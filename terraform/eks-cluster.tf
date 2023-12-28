provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

# Define the EKS cluster module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  # ... (other configuration options)

  cluster_name                  = "myapp-eks-cluster"
  cluster_version               = "1.24"
  cluster_endpoint_public_access = true

  vpc_id      = module.myapp-vpc.vpc_id
  subnet_ids  = module.myapp-vpc.private_subnets

  tags = {
    environment = "development"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
    }
  }
}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

# Define the EBS CSI driver module
module "ebs_csi_driver" {
  source            = "akw-devsecops/eks/aws//modules/aws-ebs-csi-driver"
  cluster_name      = module.eks.cluster_name
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn  # Use the OIDC provider ARN output from the eks module
}

# IAM Policy Document for EBS CSI PVs
data "aws_iam_policy_document" "ebs_csi_pvs" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:DeleteVolume",
      "ec2:DescribeVolumes",
    ]

    resources = ["*"]
  }
}

# IAM Policy Attachment for EBS CSI PVs
resource "aws_iam_role_policy_attachment" "ebs_csi_pvs" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"  # Update with the correct policy if needed
  role       = "eks-demo-iam-role"  # Replace with the correct IAM role name
}

# IAM Policy for EBS CSI PVs (custom policy)
resource "aws_iam_role_policy" "ebs_csi_pvs_custom" {
  name   = "ebs_csi_pvs_custom"
  role   = "eks-demo-iam-role"  # Replace with the correct IAM role name
  policy = data.aws_iam_policy_document.ebs_csi_pvs.json
}

