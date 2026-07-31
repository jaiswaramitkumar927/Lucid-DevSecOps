terraform {


backend "s3" {


bucket =
"company-terraform-state"


key =
"eks/dev/terraform.tfstate"


region =
"us-east-1"


dynamodb_table =
"terraform-lock"


encrypt=true


}


}