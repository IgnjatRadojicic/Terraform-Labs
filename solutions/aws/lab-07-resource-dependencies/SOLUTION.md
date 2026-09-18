# Solution: Lab 07, Resource dependencies, implicit and explicit

## Approach

Three resources with two dependencies, one of each kind. The versioning resource gets its ordering from a reference. The object gets its ordering from `depends_on`, because it genuinely needs something no reference can express. `manifest_version_id` is the instrument: it is populated when the ordering held and empty when it did not.

## Walkthrough

### Implicit, the default and the right answer almost always

```hcl
resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  ...
}
```

Writing `aws_s3_bucket.documents.id` creates the dependency. You do not request it and cannot switch it off. Terraform parses the expression, sees it needs an attribute of another resource, and orders the graph.

That is the whole mechanism. **Terraform does not read intent, it reads expressions.**

### Explicit, and a genuine reason for it

```hcl
resource "aws_s3_object" "manifest" {
  bucket  = aws_s3_bucket.documents.id
  key     = "manifest.json"
  content = jsonencode({ project = var.project_name, schema = 1 })

  depends_on = [aws_s3_bucket_versioning.documents]
}
```

The object references the **bucket**, so that ordering is already handled. It references the **versioning resource** nowhere, because it needs no data from it.

But it does need versioning to already be on. An object written to a bucket before versioning is enabled has no version history, and no amount of enabling versioning afterwards retrofits one.

This is the exact shape that justifies `depends_on`: **a real ordering requirement with no data flowing between the two resources.**

### The failure is silent, which is the point

Remove the `depends_on` and apply from scratch:

```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

manifest_version_id = ""
```

No error. Three resources created. Everything exists. The only symptom is an empty output where a version id belongs.

Run it three times and it is empty three times. Terraform creates the object and the versioning configuration in parallel, and the object consistently wins the race in this environment.

That is what makes this class of bug expensive. Nothing failed, nothing went red, and you would have to already suspect the problem to look for it. Against real AWS the timing may differ and it may sometimes work, which is worse rather than better: "usually correct" is the hardest category of infrastructure bug to find.

With the dependency in place:

```
manifest_version_id = "AaCSWHWk9bOzG8K.rTUBAHXnGkAKpD5c"
versioning_status   = "Enabled"
```

### The graph cannot tell you which is which

```
$ terraform graph
"aws_s3_object.manifest" -> "aws_s3_bucket_versioning.documents";
"aws_s3_bucket_versioning.documents" -> "aws_s3_bucket.documents";
```

Two edges, indistinguishable. One came from a reference, one from `depends_on`. Terraform does not record which, because by the time it has a graph the distinction no longer exists.

Useful when debugging: if you expect an edge and `terraform graph` does not show it, no amount of reading your configuration will help until you find the reference you did not actually write.

### `jsonencode` and its direction

```hcl
content = jsonencode({ project = var.project_name, schema = 1 })
```

`jsonencode` takes an **HCL value** and returns a **JSON string**. Its counterpart `jsondecode` goes the other way, taking a JSON string and returning an HCL value.

The direction is easy to invert under exam pressure. The mnemonic that holds up: you are *encoding into* JSON, so HCL goes in and a string comes out.

Writing the JSON by hand inside a quoted string would mean escaping every internal quote and hand-maintaining valid JSON. `jsonencode` makes the structure the source of truth. This matters much more in Tier 2 when IAM policies arrive.

## Why not the alternative

**The tempting approach: add `depends_on` to the versioning resource too, for safety.**

```hcl
resource "aws_s3_bucket_versioning" "documents" {
  bucket     = aws_s3_bucket.documents.id
  depends_on = [aws_s3_bucket.documents]     # redundant
}
```

Plan shows no difference, so it looks free. It is not, for four reasons that compound in a real codebase:

| Problem | Consequence |
|---|---|
| Not derived from data | Refactor the bucket and the `depends_on` silently goes stale or wrong |
| Coarser than a reference | Terraform tracks "this resource" rather than "this attribute", so changes propagate more widely than needed |
| Conservative inside modules | `depends_on` on a module forces its whole subtree to be treated as changed more often, producing unnecessary replacements |
| Hides the real relationship | A reader cannot tell what the versioning config actually needs from the bucket |

That last one matters most. A reference documents itself. `depends_on` says only "wait", and the reason lives in a comment if you are lucky.

The habit worth building: **if you can express a dependency as a reference, express it as a reference.** Reach for `depends_on` only when you have checked that no data flows, as with the object above.

**A second tempting approach: put an attribute on the `depends_on` address.**

```hcl
depends_on = [aws_s3_bucket_versioning.documents.id]   # error
```

This is a syntax error. `depends_on` takes resource **addresses**, not values. It exists precisely for the case where no attribute is involved, so referencing one contradicts the point of using it. People write this when they have not yet internalised that distinction, which is why it is a good exam distractor.

## Verification transcript

```
$ terraform apply -auto-approve
aws_s3_bucket.documents: Creation complete after 0s
aws_s3_bucket_versioning.documents: Creation complete after 0s
aws_s3_object.manifest: Creation complete after 0s

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

bucket = "archive-documents"
manifest_version_id = "AaCSWHWk9bOzG8K.rTUBAHXnGkAKpD5c"
versioning_status = "Enabled"
```

Without `depends_on`, three consecutive runs from a clean state:

```
run 1 without depends_on -> version_id = <empty>
run 2 without depends_on -> version_id = <empty>
run 3 without depends_on -> version_id = <empty>
```

Graph edges:

```
"aws_s3_object.manifest" -> "aws_s3_bucket_versioning.documents";
```

Verified against LocalStack with Terraform 1.16.0 and AWS provider 6.64.0.

## Exam connection

Objective 8 covers dependencies, and this is one of the most reliably tested topics because the wrong answer is so attractive.

**The classic question.** Two resources, one referencing the other's attribute, asking how to guarantee ordering. `depends_on` is offered. It is wrong. The reference already guarantees it and the correct answer is that nothing more is needed.

**The inverse.** Two resources with no reference between them that must still be ordered. Here `depends_on` is correct and is the only tool that works.

**Syntax.** `depends_on` takes a list, even with one entry, and takes addresses with no attribute appended.

**`jsonencode` versus `jsondecode`.** Direction questions are common and easy to get backwards.

Worth knowing beyond this lab: `depends_on` is valid on resources, modules, data sources and outputs. On a module it is the bluntest form, forcing the entire module to wait, and it is the usual cause of a plan proposing more changes than expected.
