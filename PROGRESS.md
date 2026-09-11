# Lab Progress

Work through labs in tier order. Tier 3 assumes fluency with what Tier 2 builds, so skipping ahead tends to produce the kind of stuck where you cannot tell which concept is confusing you.

Mark a lab `[x]` when you have completed it and read the solution. These tables are also how new labs get chosen, so keeping them current avoids duplicate coverage.

## Difficulty tiers

| Tier | Name | Characteristics |
|---|---|---|
| 1 | Foundations | Single concept, explicit instructions, starter files provided. 15 to 25 minutes |
| 2 | Composition | Two or three concepts combined, no starter files. 30 to 45 minutes |
| 3 | Structure | Modules, multiple files, you design the layout. 45 to 75 minutes |
| 4 | Operations | State manipulation, imports, drift, refactoring. AWS track only. 45 to 90 minutes |
| 5 | Synthesis | Multi-module, realistic scenario with ambiguity to resolve. 90+ minutes |

## AWS Track

Runs against LocalStack. Applies for real, produces real state files, costs nothing.

| Lab | Title | Tier | Topics | Status |
|---|---|---|---|---|
| 01 | Provider configuration and first resource | 1 | provider config, endpoints, S3, TF_LOG | [ ] |
| 02 | Input variables with types and defaults | 1 | variables, types, defaults, tfvars, precedence | [ ] |

## Azure Track

Plan-only against a real subscription. **Never run `terraform apply` on these.**

| Lab | Title | Tier | Topics | Status |
|---|---|---|---|---|
| 01 | Resource groups and implicit dependencies | 1 | features block, resource groups, implicit dependencies | [ ] |

## Coverage against exam objectives

| Area | Title | Covered by |
|---|---|---|
| 1 | IaC concepts | Implicit throughout, no dedicated lab |
| 2 | Terraform's purpose | Implicit throughout, no dedicated lab |
| 3 | Terraform basics | AWS 01, Azure 01 |
| 4 | CLI outside core workflow | AWS 01 (logging), Tier 4 labs to come |
| 5 | Terraform modules | Tier 3 labs to come |
| 6 | Core Terraform workflow | AWS 01, AWS 02, Azure 01 |
| 7 | State management | Tier 4 labs to come |
| 8 | Configuration language | AWS 02, more to come |

HCP Terraform, the hosted platform, cannot be practised meaningfully without a paid account and real cloud resources. Cover it through reading instead. The one exception worth a lab later is declaring a `cloud` block and running `terraform validate` against it, which confirms the syntax without executing anything remotely.
