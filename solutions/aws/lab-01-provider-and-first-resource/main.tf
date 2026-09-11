provider "aws" {
  region = "us-east-1"

  # LocalStack ignores these values, but the AWS SDK will not sign a
  # request without them. Setting them explicitly also overrides any real
  # credentials in ~/.aws/credentials, which is a safety property, not
  # just boilerplate.
  access_key = "test"
  secret_key = "test"

  # Each of these skips a startup step that only makes sense against real
  # AWS. Without them the provider tries to reach real AWS infrastructure
  # before it ever uses your custom endpoint.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Real S3 addresses a bucket as a subdomain. LocalStack serves one host,
  # so the bucket must appear in the path instead.
  s3_use_path_style = true

  # The actual redirection. One entry per service used, all pointing at
  # the same port, because LocalStack multiplexes every service onto 4566.
  endpoints {
    s3 = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "team-build-artifacts"
}
