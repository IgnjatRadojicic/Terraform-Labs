provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  # Two services now, so two entries. Both point at the same port, because
  # LocalStack multiplexes every service onto 4566.
  endpoints {
    s3   = "http://localhost:4566"
    logs = "http://localhost:4566"
  }
}
