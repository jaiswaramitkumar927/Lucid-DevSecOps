module "node_groups" {


source =
"terraform-aws-modules/eks/aws//modules/eks-managed-node-group"


for_each =
var.node_groups



name =
each.key



cluster_name =
module.eks.cluster_name



cluster_version =
var.cluster_version



subnet_ids =
var.subnet_ids



desired_size =
each.value.desired_size



min_size =
each.value.min_size



max_size =
each.value.max_size



instance_types =
each.value.instance_types



capacity_type =
each.value.capacity_type


}