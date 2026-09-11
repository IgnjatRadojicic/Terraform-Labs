// This file is complete. Nothing to change here.
//
// The terraform block is where you declare what Terraform itself needs,
// as opposed to what your infrastructure needs. Two things are declared:
//
//   required_version   which Terraform CLI versions this configuration
//                      supports. Running an older CLI produces a clear
//                      error instead of a confusing parse failure.
//
//   required_providers where each provider comes from and which versions
//                      are acceptable. "hashicorp/aws" is shorthand for
//                      registry.terraform.io/hashicorp/aws. This is what
//                      terraform init reads to decide what to download.
//
// The "~> 6.0" constraint means ">= 6.0.0, < 7.0.0". It allows minor and
// patch updates but not a major version bump, because major versions are
// where breaking changes are allowed to happen.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
