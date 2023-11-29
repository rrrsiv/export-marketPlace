resource "aws_s3_bucket" "emp-bucket" {
    bucket = "emp-terraform-state-backend"
    object_lock_enabled = true
    tags = {
        Name = "S3 Remote Terraform State Store"
    }
}


resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.emp-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_object_lock_configuration" "example" {
  bucket = aws_s3_bucket.emp-bucket.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 5
    }
  }
}
