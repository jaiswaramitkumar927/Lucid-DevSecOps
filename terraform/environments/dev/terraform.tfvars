vpc_name="dev-vpc"


vpc_cidr="10.0.0.0/16"


azs=[

"us-east-1a",

"us-east-1b"

]


public_subnets=[

"10.0.1.0/24",

"10.0.2.0/24"

]


private_subnets=[

"10.0.10.0/24",

"10.0.20.0/24"

]


cluster_name = "dev-eks"


cluster_version="1.31"



node_groups = {


    general = {

    desired_size=2

    min_size=1

    max_size=5


        instance_types=[

        "t3.medium"

        ]


    capacity_type="ON_DEMAND"


    }

}



tags = {

Environment="dev"

}


roles = {

  devops = {
    description = "DevOps Administrator"

    policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
      "arn:aws:iam::aws:policy/AdministratorAccess"
    ]
  }

  developers = {
    description = "Developers"

    policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    ]
  }

  readonly = {
    description = "Read Only"

    policy_arns = [
      "arn:aws:iam::aws:policy/ReadOnlyAccess"
    ]
  }

  jenkins = {
    description = "Jenkins"

    policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    ]
  }

}