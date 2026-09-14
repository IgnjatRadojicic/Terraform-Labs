# Solution: Lab 05, Local values to avoid repetition

## Approach

Three locals, each doing a different job. `name_prefix` derives a value from two variables. `common_tags` collects a repeated structure. `tags` composes the previous one with caller-supplied overrides. The refactor must produce byte-identical infrastructure, and proving that is the actual exercise.

## Walkthrough

### Locals versus variables

The distinction is the point of the lab, and it is a design decision, not a syntax preference.

| | Variable | Local |
|---|---|---|
| Set by | the caller, from outside | you, inside the configuration |
| Can reference other values | no | yes, variables and other locals |
| Overridable at runtime | yes | never |
| Use it for | an input someone chooses | a value derived from inputs |

`name_prefix` is derived from `project_name` and `environment`. Making it a variable would let someone set `project_name = "analytics"`, `environment = "dev"`, and `name_prefix = "billing-prod"`. That configuration is internally contradictory and Terraform would happily apply it. Deriving it removes that entire class of bug from existence.

The general rule: **if a caller should be able to choose it, it is a variable. If it follows from things they already chose, it is a local.**

Note the grammar quirk that catches everyone once: the block is `locals`, plural, and the reference is `local.name`, singular.

### `merge()` and argument order

```hcl
tags = merge(local.common_tags, var.extra_tags)
```

`merge()` combines maps, and **later arguments win** on a key collision. That ordering is the whole design:

```
merge(common_tags, extra_tags)  -> caller can override a common tag
merge(extra_tags, common_tags)  -> caller's values silently discarded
```

Verified. With `extra_tags = {Owner="platform-team"}`, the plan shows:

```
~ "Owner" = "data-platform" -> "platform-team"
```

Reverse the arguments and the caller's value is ignored with no warning. Which order you want is a genuine decision. Overridable defaults is the usual answer. Mandatory tags a caller must not be able to change is the other, and then the reverse order is correct.

### Proving a refactor changed nothing

This is the habit worth taking away.

```
$ terraform apply -auto-approve       # the original, duplicated version
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

# swap in the refactored configuration

$ terraform plan
No changes. Your infrastructure matches the configuration.
```

That line is the proof. You restructured the code and Terraform agrees the described infrastructure is identical. Any other result means the refactor changed behaviour, and the plan tells you exactly which resource and which attribute.

This works because Terraform compares the **resolved** configuration against state. It has no idea whether a value came from a literal, a variable or a local, and does not care.

### Outputs are a state change

Add `outputs.tf` and plan again and you do **not** get "No changes":

```
Changes to Outputs:
  + applied_tags = { ... }
  + name_prefix  = "analytics-dev"

You can apply this plan to save these new output values to the Terraform
state, without changing any real infrastructure.
```

Nothing about AWS changed. Terraform still wants an apply, because **output values live in the state file**, and adding one means state has to be updated.

This is why the lab has you check the refactor before adding outputs. Mixing the two makes the "No changes" signal unreadable, and that signal is the only mechanical proof a refactor was safe.

### The payoff

Adding `CostCentre` to `common_tags` is one line and produces:

```
Plan: 0 to add, 3 to change, 0 to destroy.
```

In the original file that was three separate edits that had to match exactly. The copies do not drift because there are no copies.

## Why not the alternative

**The tempting approach: make the tags a variable with a default.**

```hcl
variable "common_tags" {
  type = map(string)
  default = {
    Project     = "analytics"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

This looks equivalent and is worse in a specific way.

A default is **replaced wholesale**, not merged. A caller who wants to add one tag must repeat all four:

```hcl
common_tags = {
  Project     = "analytics"
  Environment = "dev"
  ManagedBy   = "Terraform"
  CostCentre  = "CC-1234"     # the only thing they wanted
}
```

Now your mandatory tags are copy-pasted into every caller, and when the policy changes you are editing all of them. You have reinvented the duplication one layer up.

Worse, the default cannot reference `var.project_name` at all. **Variable defaults must be constant expressions.** Verified:

```
Error: Variables not allowed

  on variables.tf line 8, in variable "derived":
   8:   default = "${var.project_name}-suffix"

Variables may not be used here.
```

Anything derived has to be a local, so the choice was never really open.

The pattern here, a `local` computing from variables plus a `merge()` for extension, is the standard solution precisely because it fixes both problems.

**A second tempting approach: one giant local holding everything.**

```hcl
locals {
  config = {
    name_prefix = "..."
    tags        = { ... }
    retention   = 30
  }
}
```

Referenced as `local.config.tags`. It works, and it makes every consumer depend on the shape of one structure. Splitting a value out later means touching every reference. Separate named locals are cheaper to change and read better at the point of use.

## Verification transcript

```
$ terraform apply -auto-approve            # original
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

$ terraform plan                           # refactored, before outputs
No changes. Your infrastructure matches the configuration.

$ terraform plan                           # after adding outputs.tf
Changes to Outputs:
  + applied_tags = { ... }
  + name_prefix  = "analytics-dev"
state, without changing any real infrastructure.

$ terraform plan                           # after adding CostCentre to the local
Plan: 0 to add, 3 to change, 0 to destroy.

$ terraform plan -var='extra_tags={Owner="platform-team"}'
~ "Owner" = "data-platform" -> "platform-team"
```

Verified against LocalStack with Terraform 1.16.0 and AWS provider 6.64.0.

## Exam connection

Objective 8 covers locals. The recurring questions:

**Can a local reference a variable?** Yes. **Can a variable's default reference a local, or another variable?** No. Defaults must be constant. This asymmetry is the most commonly tested fact about locals.

**Block name versus reference name.** Declared in `locals`, referenced as `local.x`. A question may show `locals.x` in an expression, which is wrong.

**Can a local be overridden on the command line?** No. There is no `-local` flag and no environment variable equivalent. If a question asks how to override one at runtime, the answer is that you cannot, and the value should have been a variable.

`merge()` argument precedence, later wins, is also fair game on its own.
