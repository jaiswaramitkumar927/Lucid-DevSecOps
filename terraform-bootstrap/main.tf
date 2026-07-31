module "kms" {

  source = "./modules/kms-key"

  alias = var.kms_alias

}


module "state_bucket" {

  source = "./modules/s3-state-bucket"

  bucket_name = var.state_bucket_name

  kms_key_arn = module.kms.key_arn

}


module "dynamodb" {

  source = "./modules/dynamodb"

  table_name = var.lock_table_name

}


module "terraform_role" {

  source = "./modules/iam-role"

  role_name = var.role_name

}