# Setup: AWS Track (LocalStack)

The AWS track runs against [LocalStack](https://www.localstack.io/), which emulates the AWS API inside a Docker container. Terraform talks to it exactly as it would talk to real AWS, so `init`, `plan`, `apply` and `destroy` all work for real and produce real state files.

Nothing in this track costs money, and no AWS account is involved at any point.

## 1. Install Docker

Follow the official instructions for your platform at [docs.docker.com/get-started/get-docker](https://docs.docker.com/get-started/get-docker/). Docker Desktop is the simplest route on Windows and macOS. On Linux, Docker Engine is enough.

Confirm it works:

```bash
docker version
```

If that errors with something about a daemon or a pipe, Docker is installed but not running. Start Docker Desktop, or run `sudo systemctl start docker` on Linux, and try again.

### A note on disk space

Docker stores images and volumes in its own data directory, which defaults to your system drive. The LocalStack image is roughly 1 GB. If your system drive is tight, move Docker's data location before pulling it. In Docker Desktop this lives under Settings, Resources, Advanced, Disk image location.

## 2. Install Terraform

Download from [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install), or use a package manager:

| Platform | Command |
|---|---|
| macOS | `brew tap hashicorp/tap && brew install hashicorp/tap/terraform` |
| Windows | `winget install HashiCorp.Terraform` |
| Linux | See the apt and yum instructions on the install page |

Confirm the version is 1.10 or later:

```bash
terraform version
```

Later labs use `removed` blocks and ephemeral values. Earlier versions fail to parse those configurations rather than giving a useful error, so starting below 1.10 buys you a confusing afternoon.

### Provider binaries are large, plan for it

This catches people out around the fifth lab.

`terraform init` downloads the provider into a `.terraform` directory **inside the working directory**, and it is not small:

| Provider | Size on disk |
|---|---|
| `hashicorp/aws` | about 870 MB |
| `hashicorp/azurerm` | about 250 MB |

Every lab directory gets its own copy. Ten AWS labs means roughly 8 GB of identical binaries.

Set a shared plugin cache so Terraform downloads each provider once:

| Platform | How |
|---|---|
| macOS, Linux | `export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"` in your shell profile |
| Windows | `[Environment]::SetEnvironmentVariable("TF_PLUGIN_CACHE_DIR", "C:\terraform-plugin-cache", "User")` |

Be precise about what this buys you. On macOS and Linux, Terraform symlinks from the cache, so it saves both download time and disk. **On Windows it copies**, so it saves the download but each lab directory still consumes the full size. Verified directly: with a warm cache, the provider inside `.terraform` is a real 870 MB file, not a link.

So on Windows, also delete `.terraform` when you finish a lab:

```bash
rm -rf .terraform
```

Nothing is lost. `terraform init` rebuilds it from the cache in seconds.

## 3. Start LocalStack

A `docker-compose.yml` is included at the root of this repository. From the repository root:

```bash
docker compose up -d
```

The first run pulls about 1 GB, so give it a minute.

## 4. Verify it is running

```bash
docker compose ps
```

Wait until the status column reads `Up (healthy)`, not merely `Up`. The compose file defines a healthcheck, so `healthy` means LocalStack is genuinely answering API calls rather than still starting up.

Then query the health endpoint directly:

```bash
curl http://localhost:4566/_localstack/health
```

**Windows PowerShell users:** type `curl.exe`, with the extension. Bare `curl` in PowerShell is an alias for `Invoke-WebRequest`, which takes completely different arguments and will produce an error that has nothing to do with LocalStack.

You should get JSON listing services with a status of `available` or `running`. Seeing `s3`, `iam`, `dynamodb` and `sqs` in that list means you are ready.

## 5. Understand the single port

Every emulated AWS service is served on port **4566**. Real AWS gives each service its own endpoint hostname. LocalStack multiplexes all of them onto one address.

This is why provider configuration in these labs looks repetitive:

```hcl
endpoints {
  s3       = "http://localhost:4566"
  iam      = "http://localhost:4566"
  dynamodb = "http://localhost:4566"
}
```

Every service you use needs its own entry, and they all point at the same place. That looks pointless until you know why it is happening.

## 6. Optional: the helper wrappers

Two convenience wrappers exist. Neither is required, and you can complete every lab without them.

### tflocal

`tflocal` wraps the `terraform` command. It writes the LocalStack endpoint overrides into a temporary file for you, so your configuration can contain a plain `provider "aws" {}` block with no LocalStack-specific content in it.

```bash
pip install terraform-local
```

Then use `tflocal init`, `tflocal plan`, `tflocal apply` in place of the `terraform` equivalents.

### awslocal

`awslocal` is shorthand for `aws --endpoint-url=http://localhost:4566`. The official package is `awscli-local`, but it depends on AWS CLI **v1** installed as a Python package. If you have AWS CLI **v2**, which is the standalone installer most people have today, it will fail with an import traceback. Installing v1 to satisfy it puts an `aws` executable on your PATH that shadows your v2 install, which is a worse problem than the one you started with.

If you are on AWS CLI v2, skip the package and use the flag directly:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

Or write your own shim. On Windows, save this as `awslocal.cmd` somewhere on your PATH:

```bat
@echo off
setlocal
set AWS_ACCESS_KEY_ID=test
set AWS_SECRET_ACCESS_KEY=test
set AWS_DEFAULT_REGION=us-east-1
aws --endpoint-url=http://localhost:4566 %*
```

On macOS or Linux, the same idea as a shell function in your profile:

```bash
awslocal() {
  AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 \
    aws --endpoint-url=http://localhost:4566 "$@"
}
```

LocalStack ignores the credential values, but the AWS CLI refuses to run without something in those variables.

Tier 1 labs use explicit endpoint configuration deliberately, so the mechanics are visible. From Tier 2 onward that boilerplate stops teaching anything and `tflocal` is the better option. Each problem statement states which approach it assumes.

## 7. Verify Terraform can reach LocalStack

This is the real confirmation that setup worked. Create a scratch directory anywhere outside this repository, and put this in `main.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3 = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "verify" {
  bucket = "setup-verification-bucket"
}
```

Then run the full cycle:

```bash
terraform init
terraform apply -auto-approve
terraform state list
terraform destroy -auto-approve
```

Expected output at each step:

| Command | Expected |
|---|---|
| `init` | `Terraform has been successfully initialized!` |
| `apply` | `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` |
| `state list` | `aws_s3_bucket.verify` |
| `destroy` | `Destroy complete! Resources: 1 destroyed.` |

If all four work, your setup is correct and you can start Lab 01.

### If you have real AWS credentials configured

Read this even if you skimmed everything else.

If you have a working `~/.aws/credentials` file, and a lab's provider block is missing or has a typo in its `endpoints` configuration, Terraform will **not** error. It will quietly fall back to your real credentials and apply against real AWS.

Two habits prevent this:

1. Always set `access_key = "test"` and `secret_key = "test"` explicitly in the provider block, as shown above. These override any profile, so a broken endpoint configuration fails to connect rather than silently succeeding somewhere that bills you.
2. Read the first lines of `plan` output before approving. An unexpected region or account ID is your signal that something is pointed at the wrong place.

`tflocal` sets both of these for you, which is a second reason to prefer it once you are past the introductory labs.

## 8. Important caveat: restarting wipes everything

Stopping the LocalStack container destroys every resource inside it. Your state files on disk survive. The two then disagree, and your next `terraform plan` proposes recreating everything.

Persistence across restarts is a LocalStack Pro feature and is not available in the free community edition, so this is a real constraint rather than a setting you have failed to find.

In practice:

| Situation | What to do |
|---|---|
| Pausing between sessions | `docker compose stop`, then `docker compose start` later. The container and its data survive |
| Finished with a lab | `terraform destroy` first, then stop the container |
| Container was removed mid-lab | Delete that lab's `terraform.tfstate` and start the lab over |

Prefer `docker compose stop` over `docker compose down`. `stop` pauses the container. `down` removes it, taking every resource with it.

## 9. Teardown

```bash
docker compose down
```

Add `-v` to also delete the named volumes. To reclaim the disk space, remove the image with `docker rmi localstack/localstack:4`.
