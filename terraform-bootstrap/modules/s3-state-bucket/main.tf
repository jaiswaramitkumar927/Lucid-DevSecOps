resource "aws_s3_bucket" "state" {

bucket =
var.bucket_name

}


resource "aws_s3_bucket_versioning" "versioning" {


bucket =
aws_s3_bucket.state.id


    versioning_configuration {

    status="Enabled"

    }

}



resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {


bucket =
aws_s3_bucket.state.id

    rule {

        apply_server_side_encryption_by_default {

        sse_algorithm="aws:kms"

        kms_master_key_id =
        var.kms_key_arn

        }

    }

}



resource "aws_s3_bucket_public_access_block" "block" {


bucket =
aws_s3_bucket.state.id



block_public_acls=true

block_public_policy=true

ignore_public_acls=true

restrict_public_buckets=true


}