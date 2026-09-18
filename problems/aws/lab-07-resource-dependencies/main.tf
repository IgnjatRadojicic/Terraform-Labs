// Three resources. Two kinds of dependency. Knowing which kind to reach
// for, and when the answer is neither, is the whole lab.

// TODO 1: aws_s3_bucket named "documents"
//   bucket = the project_name variable followed by "-documents"

// TODO 2: aws_s3_bucket_versioning named "documents"
//   Turn versioning on for the bucket above.
//
//   The bucket argument takes the bucket's id. Get it by REFERENCE.
//   That reference is all the ordering information Terraform needs, so
//   this resource should not need depends_on. Adding it would be
//   redundant, and redundant depends_on is a real cost, not a harmless
//   extra. The solution explains why.
//
//   The nested block you need is:
//
//     versioning_configuration {
//       status = "Enabled"
//     }

// TODO 3: aws_s3_object named "manifest"
//   bucket  = the documents bucket id
//   key     = "manifest.json"
//   content = a JSON string containing the project name and a schema
//             number. Build it with a function rather than writing JSON
//             by hand inside a string, so that quoting is not your
//             problem.
//
//   Here is the interesting part.
//
//   This object needs the BUCKET, and referencing it gives you that
//   ordering for free. But it also needs versioning to already be ON,
//   because an object written to a bucket before versioning is enabled
//   has no version history. Nothing about the object references the
//   versioning resource, because the object needs no data from it.
//
//   So Terraform is free to write this object first, and the result is
//   infrastructure that is subtly wrong rather than loudly broken.
//
//   This is the shape of a legitimate explicit dependency: a real
//   ordering requirement with no data flowing between the two resources.
//   Add one.
