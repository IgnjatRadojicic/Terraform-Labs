// The provider block configures HOW Terraform talks to a platform.
// The terraform block in versions.tf decided WHICH provider to download.
// Those are two different jobs, and conflating them is a common early
// confusion.
//
// By default the AWS provider talks to real AWS. Everything you are about
// to add is redirecting it at the emulator running on your machine.

provider "aws" {
  region = "us-east-1"

  // TODO 1: Set access_key and secret_key to the literal string "test".
  //
  // LocalStack ignores the values, but the AWS SDK refuses to make a
  // request without something present. Setting them explicitly also
  // protects you: if your endpoint configuration is wrong, the request
  // fails instead of quietly succeeding against real AWS using a
  // credentials file you forgot about.

  // TODO 2: Skip the three startup checks that only make sense against
  // real AWS. Each is a boolean argument on this block, and each name
  // begins with "skip_". One validates credentials, one checks the EC2
  // instance metadata API, and one looks up your account ID.
  //
  // Without these, Terraform tries to reach real AWS infrastructure
  // before it ever sends a request to your endpoint, and hangs or fails.

  // TODO 3: Enable path style addressing for S3.
  //
  // Real S3 resolves a bucket as a subdomain, like
  // bucket-name.s3.amazonaws.com. LocalStack serves everything from one
  // host, so the bucket has to appear in the path instead, like
  // localhost:4566/bucket-name. The argument is a boolean on this block.

  // TODO 4: Add an endpoints block pointing s3 at http://localhost:4566
  //
  // This is the part that actually redirects Terraform. One entry per
  // service you use. This lab uses only S3, so it needs only one entry.
}

// TODO 5: Declare an aws_s3_bucket resource.
//
//   Terraform resource name: artifacts
//   Actual bucket name:      team-build-artifacts
//
// Remember that a resource block takes two labels. The first is the
// resource type, which is fixed by the provider. The second is the name
// you choose, used to reference this resource elsewhere in your
// configuration. Neither is the bucket's real name in AWS. That is an
// argument inside the block.
