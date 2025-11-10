# Local variables for IAM resources
locals {
  cluster_name = var.cluster-name
}

# Generate random suffix for unique IAM role names
# Helps avoid naming conflicts when recreating resources
resource "random_integer" "random_suffix" {
  min = 1000
  max = 9999
}

# IAM role for EKS cluster
# This role allows EKS service to manage AWS resources on your behalf
resource "aws_iam_role" "eks-cluster-role" {
  count = var.is_eks_role_enabled ? 1 : 0
  name  = "${local.cluster_name}-role-${random_integer.random_suffix.result}"

  # Trust policy allowing EKS service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach AWS managed policy for EKS cluster permissions
# Provides necessary permissions for EKS to create and manage resources
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  count      = var.is_eks_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role[count.index].name
}

# IAM role for EKS node group
# This role is assumed by EC2 instances in the EKS node group
resource "aws_iam_role" "eks-nodegroup-role" {
  count = var.is_eks_nodegroup_role_enabled ? 1 : 0
  name  = "${local.cluster_name}-nodegroup-role-${random_integer.random_suffix.result}"

  # Trust policy allowing EC2 instances to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach EKS Worker Node Policy
# Allows worker nodes to connect to EKS cluster
resource "aws_iam_role_policy_attachment" "eks-AmazonWorkerNodePolicy" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}

# Attach EKS CNI Policy
# Provides permissions for Amazon VPC CNI plugin to modify IP address configuration on nodes
resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}
# Attach ECR Read-Only Policy
# Allows worker nodes to pull container images from Amazon ECR
resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}

# OIDC Configuration for Kubernetes Service Accounts
# IAM role for OIDC provider integration
# Allows Kubernetes service accounts to assume AWS IAM roles
resource "aws_iam_role" "eks_oidc" {
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_policy.json
  name               = "eks-oidc"
}

# Custom IAM policy for OIDC role
# Example policy granting S3 permissions (customize based on your application needs)
# WARNING: Currently has wildcard permissions (*) - should be restricted in production
resource "aws_iam_policy" "eks-oidc-policy" {
  name = "test-policy"

  policy = jsonencode({
    Statement = [{
      Action = [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "*"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

# Attach custom policy to OIDC role
# Links the permissions policy to the OIDC role
resource "aws_iam_role_policy_attachment" "eks-oidc-policy-attach" {
  role       = aws_iam_role.eks_oidc.name
  policy_arn = aws_iam_policy.eks-oidc-policy.arn
}