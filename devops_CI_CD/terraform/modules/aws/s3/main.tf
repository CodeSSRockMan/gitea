resource "aws_s3_bucket" "gitea_bucket" {
  bucket = var.bucket_name

  force_destroy = true

  tags = {
    Name = "gitea-bucket"

    Project = "dr"
  }
}
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.gitea_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.gitea_bucket.id

  rule {
    id     = "DeleteOldVersions"
    status = "Enabled"
    filter {
      prefix = ""
    }


    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }


  }
}
