variable "cluster_name" {
  type = string
}

variable "access_entries" {
  type = map(object({
    principal_arn = string
    policy_arn    = string
  }))
}