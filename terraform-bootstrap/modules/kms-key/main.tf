resource "aws_kms_key" "terraform" {


description =
"Terraform state encryption key"


enable_key_rotation=true



}


resource "aws_kms_alias" "terraform" {


name =
"alias/${var.alias}"


target_key_id =
aws_kms_key.terraform.id


}