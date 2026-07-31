resource "aws_eks_addon" "vpc_cni" {


cluster_name =
module.eks.cluster_name


addon_name =
"vpc-cni"


}


resource "aws_eks_addon" "coredns" {


cluster_name =
module.eks.cluster_name


addon_name =
"coredns"


}


resource "aws_eks_addon" "kube_proxy" {


cluster_name =
module.eks.cluster_name


addon_name =
"kube-proxy"


}