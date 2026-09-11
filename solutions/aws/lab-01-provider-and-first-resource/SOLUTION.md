# Solution: Lab 01, Provider configuration and first resource

## Approach

The whole lab is one provider block and one resource block. The provider block redirects every AWS API call to LocalStack and disables three startup checks that assume real AWS is reachable. The resource block is deliberately the simplest thing the AWS provider offers, so that nothing distracts from the configuration above it.

The logging exercise is separate from the infrastructure and exists to expose a specific wrong mental model before it costs you an exam question.

## Walkthrough

### The two blocks do different jobs

This trips people up early. `versions.tf` declares **which** provider to download and from where. `main.tf` declares **how** to talk to it once downloaded.

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}
```

`terraform init` reads that, fetches the plugin, and records the resolved version. If you came from .NET, the `terraform` block is your `.csproj` PackageReference and the `provider` block is the options object you configure at startup. One resolves the dependency, the other configures the instance.

### Credentials that are not credentials

```hcl
access_key = "test"
secret_key = "test"
```

LocalStack ignores these values entirely. The AWS SDK still refuses to sign a request without something present, so they have to exist.

The safety property matters more than the mechanics. If you omit them and your endpoint configuration has a typo, the provider falls back to the standard credential chain, finds `~/.aws/credentials` if you have one, and applies against **real AWS**. Setting them explicitly guarantees that a broken endpoint configuration fails to connect instead of quietly succeeding somewhere that bills you.

### The three skips

```hcl
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_requesting_account_id  = true
```

| Argument | What it skips | Why it must be skipped |
|---|---|---|
| `skip_credentials_validation` | An STS call to check the key is valid | `test` is not a valid key anywhere |
| `skip_metadata_api_check` | A request to `169.254.169.254`, the EC2 instance metadata endpoint | That address is unreachable off an EC2 instance and the attempt hangs before timing out |
| `skip_requesting_account_id` | Looking up the AWS account ID | There is no account behind LocalStack |

Each of these happens during provider initialisation, before your endpoint override is ever used. That is why omitting them causes a failure that appears to have nothing to do with your configuration.

### Path style addressing

```hcl
s3_use_path_style = true
```

Real S3 addresses a bucket as a subdomain, `team-build-artifacts.s3.amazonaws.com`. LocalStack serves everything from one host, so the bucket must live in the path instead, `localhost:4566/team-build-artifacts`. Without this, the SDK builds a hostname that does not resolve.

This is S3-specific. No other service in these labs needs it.

### The endpoints block

```hcl
endpoints {
  s3 = "http://localhost:4566"
}
```

This is the line that actually redirects Terraform. One entry per service used. Later labs that touch IAM, DynamoDB and SQS need an entry each, all pointing at the same port, because LocalStack multiplexes every service onto 4566.

### The resource block's two labels

```hcl
resource "aws_s3_bucket" "artifacts" {
  bucket = "team-build-artifacts"
}
```

Three names are in play and confusing them is a classic early mistake:

| Name | What it is | Where it is used |
|---|---|---|
| `aws_s3_bucket` | Resource type, fixed by the provider | Determines which API is called |
| `artifacts` | Your label for this resource | References elsewhere in config, and the state address `aws_s3_bucket.artifacts` |
| `team-build-artifacts` | The real bucket name in AWS | Only inside the block, as an argument |

Renaming `artifacts` to something else changes the state address and, without a `moved` block, causes Terraform to destroy and recreate the bucket. That is a Tier 4 lab.

### The logging trap

Running `TF_LOG_PATH=terraform.log terraform plan` **creates `terraform.log` and leaves it at zero bytes.**

This is worse than producing nothing, because the file exists. Check only that it was created and you will conclude logging is working, then waste twenty minutes wondering why your log is empty.

`TF_LOG` is the switch. `TF_LOG_PATH` is only a redirect for output that `TF_LOG` has already enabled. Both are needed to write a useful log file:

```bash
TF_LOG=INFO TF_LOG_PATH=terraform.log terraform plan
```

Levels, most verbose first: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`. `TRACE` includes the full HTTP request and response bodies, which is what you want when a provider is doing something inexplicable and what you never want otherwise.

## Why not the alternative

**The tempting approach: skip the explicit configuration and just use `tflocal`.**

It works, and from Lab 03 onward it is what you should do. Here it would have cost you the entire lesson.

`tflocal` generates a file called `localstack_providers_override.tf` containing exactly the block you just wrote by hand, then calls `terraform`. Use it before understanding it and three things go wrong later:

1. When a lab needs a service whose endpoint is missing, you will not recognise the error, because you never learned that endpoints are per-service.
2. The exam asks about provider configuration, including `alias` and multiple provider instances. Wrapper tools do not appear on it.
3. When you hit real AWS in a job and need a custom endpoint, for a VPC endpoint or a compatible third-party store, you will not know the argument exists.

**A second tempting approach: put credentials in environment variables instead of the provider block.**

`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are read by the provider and would work. The problem is that they are invisible in the configuration. Six months later, someone clones the repository, runs `apply` with their own real credentials in the environment, and creates resources in production. Explicit dummy values in the block make the intent unambiguous and unoverridable.

## Verification transcript

```
$ terraform init
- Installing hashicorp/aws v6.64.0...
Terraform has been successfully initialized!

$ terraform validate
Success! The configuration is valid.

$ terraform apply -auto-approve
aws_s3_bucket.artifacts: Creating...
aws_s3_bucket.artifacts: Creation complete after 0s [id=team-build-artifacts]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

$ terraform state list
aws_s3_bucket.artifacts

$ aws --endpoint-url=http://localhost:4566 s3 ls
2026-09-11 20:15:42 team-build-artifacts
```

Logging behaviour, confirmed over repeated trials:

```
$ rm -f terraform.log
$ TF_LOG_PATH=terraform.log terraform plan
$ ls -l terraform.log
-rw-r--r-- 1 user user 0 Sep 11 20:17 terraform.log      <-- zero bytes

$ TF_LOG=INFO TF_LOG_PATH=terraform.log terraform plan
$ head -1 terraform.log
2026-09-11T20:17:17.898+0200 [INFO]  Terraform version: 1.16.0
```

Teardown:

```
$ terraform destroy -auto-approve
Destroy complete! Resources: 1 destroyed.

$ aws --endpoint-url=http://localhost:4566 s3 ls
(no output)
```

This solution was verified end to end against LocalStack with Terraform 1.16.0 and AWS provider 6.64.0.

## Exam connection

Objective 3 covers provider installation and configuration, and objective 6 covers the core workflow you just ran in order. Both are heavily represented.

Two traps worth carrying into the exam:

**Logging.** `TF_LOG` enables, `TF_LOG_PATH` redirects. A question that gives you only `TF_LOG_PATH` and asks what happens is testing precisely this. The answer is not "an error". It is an empty file and no indication anything is wrong.

**Provider versus terraform block.** Questions ask where `required_providers` goes. It goes in the `terraform` block, not the `provider` block. The `provider` block cannot declare a version, and putting `version` inside it was deprecated long ago.

One more worth knowing, though this lab does not exercise it: `terraform init` writes `.terraform.lock.hcl` recording exact provider versions and checksums. **That file should be committed in a real project**, so every collaborator and CI run resolves identically. This repository gitignores it only because each lab directory is a throwaway practice environment. The exam may ask about the lock file's purpose.
