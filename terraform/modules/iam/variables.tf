variable "roles" {
  type = map(object({
    description = string
    policy_arns = list(string)
  }))
}