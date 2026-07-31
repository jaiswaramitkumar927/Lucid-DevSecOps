resource "aws_security_group" "alb" {


name =
"${var.name}-alb-sg"


vpc_id =
var.vpc_id



ingress {


from_port=80

to_port=80

protocol="tcp"

cidr_blocks=[
"0.0.0.0/0"
]

}



ingress {


from_port=443

to_port=443

protocol="tcp"

cidr_blocks=[
"0.0.0.0/0"
]

}



egress {


from_port=0

to_port=0

protocol="-1"

cidr_blocks=[
"0.0.0.0/0"
]

}


}




##################################
# EKS Cluster Security Group
##################################


resource "aws_security_group" "eks_cluster" {


name =
"${var.name}-eks-cluster-sg"


vpc_id =
var.vpc_id



ingress {


from_port=443

to_port=443

protocol="tcp"


cidr_blocks=[
var.vpc_cidr
]

}



egress {


from_port=0

to_port=0

protocol="-1"

cidr_blocks=[
"0.0.0.0/0"
]


}

}



##################################
# Worker Node Security Group
##################################


resource "aws_security_group" "eks_nodes" {


name =
"${var.name}-eks-node-sg"


vpc_id =
var.vpc_id



ingress {


from_port=0

to_port=0

protocol="-1"


security_groups=[
aws_security_group.eks_cluster.id
]

}



ingress {


from_port=0

to_port=0

protocol="-1"


self=true


}



egress {


from_port=0

to_port=0

protocol="-1"


cidr_blocks=[
"0.0.0.0/0"
]


}

}