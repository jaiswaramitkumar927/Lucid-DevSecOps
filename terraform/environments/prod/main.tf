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

# Route Tables

module "route_tables" {

  source = "../../modules/route-tables"


  name = var.vpc_name


  vpc_id = module.vpc.vpc_id


  internet_gateway_id =
    module.vpc.internet_gateway_id


  nat_gateway_id =
    module.vpc.nat_gateway_id


  public_subnet_ids =
    module.vpc.public_subnet_ids


  private_subnet_ids =
    module.vpc.private_subnet_ids

}

# Network ACL

module "network_acl" {

  source = "../../modules/network-acl"


  name = var.vpc_name


  vpc_id =
    module.vpc.vpc_id


  vpc_cidr =
    var.vpc_cidr


  public_subnet_ids =
    module.vpc.public_subnet_ids


  private_subnet_ids =
    module.vpc.private_subnet_ids

}

# Security Groups

module "security_groups" {

    source = "../../modules/security-groups"


    name = var.vpc_name


    vpc_id =
        module.vpc.vpc_id


    vpc_cidr =
        var.vpc_cidr

}

module "iam" {

  source = "../../modules/iam"

  roles = var.roles
}

module "eks_access" {

  source = "../../modules/eks-access"

  cluster_name = module.eks.cluster_name

  access_entries = {

    for key, value in var.eks_access_entries :

    key => {

      principal_arn = module.iam.role_arns[value.role_name]

      policy_arn = value.policy_arn

    }

  }

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