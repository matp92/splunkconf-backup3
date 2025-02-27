
resource "aws_s3_bucket" "s3_install" {
  provider      = aws.region-primary
  bucket_prefix = "splunkconf-${var.profile}-${var.splunktargetenv}-install"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "s3_install" {
  bucket              = aws_s3_bucket.s3_install.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}

# aws provider change with 4.0 
resource "aws_s3_bucket_versioning" "s3_install_versioning" {
  provider = aws.region-primary
  bucket   = aws_s3_bucket.s3_install.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_install_lifecycle" {
  provider = aws.region-primary
  bucket   = aws_s3_bucket.s3_install.id

  rule {
    id = "s3install-purge-old-noncurrent-versionned-install"
    filter {
      prefix = "install/"
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    expiration {
      expired_object_delete_marker = true
    }
    status = "Enabled"
  }

  rule {
    id = "s3install-purge-old-noncurrent-versionned-packaged"
    filter {
      prefix = "packaged/"
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    expiration {
      expired_object_delete_marker = true
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "s3_backup" {
  provider            = aws.region-primary
  bucket_prefix       = "splunkconf-${var.profile}-${var.splunktargetenv}-backup"
  force_destroy       = true
  object_lock_enabled = var.objectlock-backup
}

resource "aws_s3_bucket_object_lock_configuration" "s3_backup" {
  count  = var.objectlock-backup ? 1 : 0
  bucket = aws_s3_bucket.s3_backup.bucket

  rule {
    default_retention {
      mode = var.objectlock-backup-mode
      days = var.objectlock-backup-days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_backup" {
  bucket              = aws_s3_bucket.s3_backup.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}

# aws provider change with 4.0 
resource "aws_s3_bucket_versioning" "s3_backup_versioning" {
  provider = aws.region-primary
  bucket   = aws_s3_bucket.s3_backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_backup_lifecycle" {
  provider = aws.region-primary
  bucket   = aws_s3_bucket.s3_backup.id

  rule {
    id = "purge-old-noncurrent-versionned-backup"
    filter {
      prefix = "splunkconf-backup/"
    }
    noncurrent_version_expiration {
      noncurrent_days = var.backup-retention
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    expiration {
      expired_object_delete_marker = true
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "s3_data" {
  provider      = aws.region-primary
  bucket_prefix = "splunkconf-${var.profile}-${var.splunktargetenv}-data"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "s3_data" {
  bucket              = aws_s3_bucket.s3_data.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}

# aws provider change with 4.0 
resource "aws_s3_bucket_versioning" "s3_data_versioning" {
  provider = aws.region-primary
  bucket   = aws_s3_bucket.s3_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_data_lifecycle" {
  provider = aws.region-primary
  bucket   = aws_s3_bucket.s3_data.id

  rule {
    id = "s3data-purge-old-noncurrent-versionned-data"
    filter {
      prefix = "smartstore*/"
    }
    noncurrent_version_expiration {
      noncurrent_days = var.deleteddata-retention
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    expiration {
      expired_object_delete_marker = true
    }
    status = "Enabled"
  }
  # auto , use INTELLIGENT_TIERING to let AWS decide
  rule {
    id = "transition-data-smartstore"
    filter {
      prefix = "smartstore/"
    }
    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
    status = "Enabled"
  }

  # move to IA (setting need to be 30 days mini)
  rule {
    id = "transition-data-smartstore1"
    filter {
      prefix = "smartstore1/"
    }
    transition {
      days          = var.s2days-1-ia
      storage_class = "STANDARD_IA"
    }
    status = "Enabled"
  }

  # complete here if you need more granularity

}


# Ingest Action bucket
resource "aws_s3_bucket" "s3_ia" {
  provider      = aws.region-primary
  bucket_prefix = "splunkconf-${var.profile}-${var.splunktargetenv}-ia"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account_to_s3ia" {
  count = var.enable-fss3-policy  ? 1 : 0
  bucket = aws_s3_bucket.s3_ia.id
  #policy = data.template_file.pol-splunk-s3iafs.rendered 
  policy = local.pol-splunk-s3iafs 
}

resource "aws_s3_bucket_public_access_block" "s3_ia" {
  bucket              = aws_s3_bucket.s3_ia.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_ia_lifecycle" {
  provider = aws.region-primary
  bucket   = aws_s3_bucket.s3_ia.id

  rule {
    id = "purge-old-noncurrent-versionned-ia"
    filter {
      prefix = "${var.s3_iaprefix}/"
    }
    noncurrent_version_expiration {
      noncurrent_days = var.deleteddata-retention
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    expiration {
      expired_object_delete_marker = true
    }
    status = "Enabled"
  }
}

output "s3_install_arn" {
  value       = aws_s3_bucket.s3_install.arn
  description = "s3 install arn"
}

output "s3_backup_arn" {
  value       = aws_s3_bucket.s3_backup.arn
  description = "s3 backup arn"
}

output "s3_data_arn" {
  value       = aws_s3_bucket.s3_data.arn
  description = "s3 data arn"
}

output "s3_ia_arn" {
  value       = aws_s3_bucket.s3_ia.arn
  description = "s3 data arn"
}
