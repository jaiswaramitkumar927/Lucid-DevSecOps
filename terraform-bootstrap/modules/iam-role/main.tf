resource "aws_iam_role" "terraform" {


name="terraform-deployment-role"



    assume_role_policy=jsonencode({


    Version="2026-07-31"


        Statement=[

            {

            Effect="Allow"


                Principal={

                Service="ec2.amazonaws.com"

                }

            Action="sts:AssumeRole"

            }
        ]

    })

}

resource "aws_iam_role_policy_attachment" "admin" {

    role =
    aws_iam_role.terraform.name

    policy_arn =
    "arn:aws:iam::aws:policy/AdministratorAccess"

}