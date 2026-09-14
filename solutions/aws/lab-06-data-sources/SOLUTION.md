# Solution: Lab 06, Data sources versus resources

## Approach

One bucket Terraform owns, one data source reading that same bucket, and two data sources describing the caller. The whole lab is arranged so that `apply` says 2, `state list` says 5, and `destroy` says 2. Explaining those three numbers is the objective.

## Walkthrough

### The counts

```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

$ terraform state list
data.aws_caller_identity.current
data.aws_region.current
data.aws_s3_bucket.lookup
aws_cloudwatch_log_group.audit
aws_s3_bucket.managed

Destroy complete! Resources: 2 destroyed.
```

Five blocks. Two created. Five in state. Two destroyed.

Data sources are **recorded** in state so Terraform can detect when the value they returned has changed, but they were never created, so there is nothing to destroy. Terraform will never delete the real thing behind a data source. That property is exactly what makes data sources safe to point at infrastructure another team owns.

Note the `data.` prefix in state addresses. `aws_s3_bucket.managed` and `data.aws_s3_bucket.lookup` are different addresses for the same real bucket, one managed and one merely observed.

### The reference is load-bearing

```hcl
data "aws_s3_bucket" "lookup" {
  bucket = aws_s3_bucket.managed.bucket
}
```

Hardcoding `bucket = "inventory-managed"` would produce the same value and break the configuration.

Data sources are read **early**, during or before plan, wherever Terraform can. With no dependency on the resource, Terraform is free to read a bucket that does not exist yet, and the first apply fails with a not-found error. The second apply then succeeds, because by then the bucket exists. A configuration that fails once and then works is considerably worse than one that fails every time.

The reference forces the read to wait. This is the same implicit dependency mechanism from Lab 07, applied to data sources.

### Data sources describing the caller

```hcl
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
```

Empty bodies. These take no arguments because they describe the provider's own context rather than looking anything up.

They are how a module discovers where it is running without being told:

```hcl
arn = "arn:aws:s3:::${var.bucket}/*"
account = data.aws_caller_identity.current.account_id
```

Under LocalStack, `account_id` comes back as `000000000000`. That is LocalStack's fixed fake account. It is a valid twelve digit account ID, structurally identical to a real one, which is what lets IAM policy labs work later.

`region` returns `us-east-1`, matching the provider configuration.

### Resource attribute and data source attribute are identical

```
resource_bucket_arn    = "arn:aws:s3:::inventory-managed"
data_source_bucket_arn = "arn:aws:s3:::inventory-managed"
```

Same value from both. When you own the resource, reading it back through a data source adds nothing but a round trip.

That is deliberate, because the lesson is about **when** each applies:

| Situation | Use |
|---|---|
| Your configuration creates it | the resource |
| It already exists and another team owns it | a data source |
| It already exists and you want to take ownership | `import`, Tier 4 |

Using a data source for something you create is a real mistake, not a style issue. It adds an unnecessary API call on every plan and makes the configuration read as though ownership lies elsewhere.

### Data sources are re-read on every plan

Run plan with no changes and watch the output. The managed resource is **refreshed**. The data sources are **read**. Both hit the API, but only the resource has prior state to compare against.

This has a practical consequence: if the thing behind a data source changes outside Terraform, your next plan silently picks up the new value, and anything derived from it may show as a change. That is usually what you want, and it is occasionally a surprise when someone else's change to shared infrastructure produces a diff in yours.

## Why not the alternative

**The tempting approach: use a data source to "check" something exists before creating it.**

```hcl
data "aws_s3_bucket" "maybe_exists" {
  bucket = "shared-artifacts"
}

resource "aws_s3_bucket" "fallback" {
  count  = data.aws_s3_bucket.maybe_exists.id == "" ? 1 : 0
  bucket = "shared-artifacts"
}
```

This is a very common instinct and it does not work.

A data source that finds nothing **errors**. It does not return an empty value you can test. The plan fails before your conditional is ever evaluated, so the fallback can never trigger.

More fundamentally, Terraform is declarative. "Create it if it is not there" is imperative thinking. The declarative answer is that the configuration owns the bucket or it does not, and which one is a decision you make, not a runtime check. If ownership genuinely varies by environment, that is a variable driving `count`, decided at plan time from configuration, not discovered from the API.

**A second tempting approach: hardcode your account ID instead of using `aws_caller_identity`.**

It works until the configuration is applied in a second account, which is exactly what happens when someone builds a staging environment. Hardcoded account IDs are also the most common reason a module cannot be reused. The data source costs one API call and removes the problem permanently.

## Verification transcript

```
$ terraform apply -auto-approve
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

account_id = "000000000000"
data_source_bucket_arn = "arn:aws:s3:::inventory-managed"
region = "us-east-1"
resource_bucket_arn = "arn:aws:s3:::inventory-managed"

$ terraform state list
data.aws_caller_identity.current
data.aws_region.current
data.aws_s3_bucket.lookup
aws_cloudwatch_log_group.audit
aws_s3_bucket.managed

$ terraform destroy -auto-approve
Destroy complete! Resources: 2 destroyed.
```

State entries: 5, of which 3 carry the `data.` prefix. Created: 2. Destroyed: 2.

Verified against LocalStack with Terraform 1.16.0 and AWS provider 6.64.0.

## Exam connection

Objectives 7 and 8 both touch this. Reliable question shapes:

**How is a data source referenced?** `data.<type>.<name>.<attribute>`. Dropping the `data.` prefix is the single most common error, and a question may show it as a distractor.

**Does `terraform destroy` remove what a data source points at?** No. Only managed resources are destroyed. A question phrased as "what happens to the VPC read by a data source when you destroy" is testing this.

**When do data sources get read?** During plan, and again on refresh. A question about a data source returning stale values is testing whether you know it is re-read rather than cached in state permanently.

Worth knowing though this lab does not use it: `depends_on` works on data sources, and it is occasionally necessary when the thing being read is created by a resource that shares no attribute with it. That is the data source version of Lab 07's lesson.
