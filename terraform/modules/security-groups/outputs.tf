output "alb_security_group_id" {

value =
aws_security_group.alb.id

}


output "eks_cluster_security_group_id" {

value =
aws_security_group.eks_cluster.id

}


output "eks_node_security_group_id" {

value =
aws_security_group.eks_nodes.id

}