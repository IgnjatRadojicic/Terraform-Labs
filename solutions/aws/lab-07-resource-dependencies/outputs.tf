output "bucket" {
  description = "Bucket holding the documents."
  value       = aws_s3_bucket.documents.id
}

output "versioning_status" {
  description = "Whether versioning ended up enabled."
  value       = aws_s3_bucket_versioning.documents.versioning_configuration[0].status
}

output "manifest_version_id" {
  description = "Version ID of the manifest. Proof it was written after versioning was on."
  value       = aws_s3_object.manifest.version_id
}
