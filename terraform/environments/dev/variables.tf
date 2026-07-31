variable "vpc_name" {}

variable "vpc_cidr" {}

variable "azs" {}

variable "public_subnets" {}

variable "private_subnets" {}


variable "cluster_name" {}

variable "cluster_version" {}


variable "node_groups" {}


variable "tags" {}

variable "roles" {
  description = "IAM roles to create"

  type = map(object({
    description = string
    policy_arns = list(string)
  }))
}

variable "eks_access_entries" {
  description = "EKS Access Entries"

  type = map(object({
    role_name  = string
    policy_arn = string
  }))
}