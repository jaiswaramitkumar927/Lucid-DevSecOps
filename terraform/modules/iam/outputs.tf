output "role_arns" {
  value = {
    for name, role in aws_iam_role.this :
    name => role.arn
  }
}