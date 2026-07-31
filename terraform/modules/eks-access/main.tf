resource "aws_eks_access_entry" "this" {

  for_each = var.access_entries

  cluster_name = var.cluster_name

  principal_arn = each.value.principal_arn

  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {

  for_each = var.access_entries

  cluster_name = var.cluster_name

  principal_arn = each.value.principal_arn

  policy_arn = each.value.policy_arn

  access_scope {
    type = "cluster"
  }
}