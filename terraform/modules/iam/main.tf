resource "aws_iam_role" "this" {
  for_each = var.roles

  name = each.key

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  description = each.value.description
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = {
    for item in flatten([
      for role_name, role in var.roles : [
        for policy in role.policy_arns : {
          role   = role_name
          policy = policy
        }
      ]
    ]) : "${item.role}-${basename(item.policy)}" => item
  }

  role       = aws_iam_role.this[each.value.role].name
  policy_arn = each.value.policy
}