// This configuration works. It is also the kind of file that rots.
//
// Read it and count how many times the same fact appears. Then ask what
// happens when the tagging policy gains one more required tag, or the
// naming convention changes from project-environment to environment-project.
//
// Your job is to refactor this so that each fact is written exactly once.
// The resulting infrastructure must be byte for byte identical.

resource "aws_s3_bucket" "raw" {
  bucket = "analytics-dev-raw"

  tags = {
    Project     = "analytics"
    Environment = "dev"
    Owner       = "data-platform"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "processed" {
  bucket = "analytics-dev-processed"

  tags = {
    Project     = "analytics"
    Environment = "dev"
    Owner       = "data-platform"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "pipeline" {
  name              = "/aws/analytics-dev/pipeline"
  retention_in_days = 30

  tags = {
    Project     = "analytics"
    Environment = "dev"
    Owner       = "data-platform"
    ManagedBy   = "Terraform"
  }
}
