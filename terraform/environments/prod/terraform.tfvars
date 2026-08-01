vpc_name="prod-vpc"


vpc_cidr="10.20.0.0/16"


azs=[

"us-east-1a",

"us-east-1b",

"us-east-1c"

]


public_subnets=[

 "10.20.1.0/24",
 "10.20.2.0/24",
 "10.20.3.0/24"

]

private_subnets=[

 "10.20.10.0/24",
 "10.20.20.0/24",
 "10.20.30.0/24"

]


cluster_name="prod-eks"


cluster_version="1.31"



node_groups={

general={

desired_size=5

min_size=3

max_size=20


instance_types=[

"m6i.large"

]


capacity_type="ON_DEMAND"


}

}



tags={

Environment="prod"

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