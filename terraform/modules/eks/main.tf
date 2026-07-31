module "eks" {


source =
"terraform-aws-modules/eks/aws"


version =
"20.8.5"



cluster_name =
var.cluster_name



cluster_version =
var.cluster_version



vpc_id =
var.vpc_id



subnet_ids =
var.subnet_ids



enable_cluster_creator_admin_permissions=true



}