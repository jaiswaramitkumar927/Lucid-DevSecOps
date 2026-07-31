module "vpc" {


source="../../modules/vpc"


name = var.vpc_name


cidr = var.vpc_cidr


azs = var.azs


public_subnets = var.public_subnets


private_subnets = var.private_subnets


tags = var.tags


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

    # Security Groups

    cluster_security_group_id =
        module.security_groups.eks_cluster_security_group_id


    node_security_group_id =
        module.security_groups.eks_node_security_group_id
}