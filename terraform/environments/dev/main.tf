module "vpc" {


source="../../modules/vpc"


name =
var.vpc_name


cidr =
var.vpc_cidr


azs =
var.azs


public_subnets =
var.public_subnets


private_subnets =
var.private_subnets


tags =
var.tags


}



module "eks" {


source="../../modules/eks"



cluster_name =
var.cluster_name


cluster_version =
var.cluster_version



vpc_id =
module.vpc.vpc_id



subnet_ids =
module.vpc.private_subnet_ids



node_groups =
var.node_groups


}