# Local variables for resource naming convention
# Defines organization and environment prefixes for consistent resource naming
locals {
  org = "ap-medium"  # Organization identifier
  env = var.env      # Environment (dev, staging, prod)
}

# EKS Module Configuration
# Deploys complete EKS infrastructure including VPC, subnets, cluster, and node groups
module "eks" {
  source = "../module"

  # Environment Configuration
  env                   = var.env
  cluster-name          = "${local.env}-${local.org}-${var.cluster-name}"  # Naming convention: env-org-name

  # VPC Configuration
  cidr-block            = var.vpc-cidr-block
  vpc-name              = "${local.env}-${local.org}-${var.vpc-name}"
  
  # Internet Gateway Configuration
  igw-name              = "${local.env}-${local.org}-${var.igw-name}"
  
  # Public Subnet Configuration
  pub-subnet-count      = var.pub-subnet-count      # Number of public subnets to create
  pub-cidr-block        = var.pub-cidr-block        # CIDR blocks for public subnets
  pub-availability-zone = var.pub-availability-zone # AZs for high availability
  pub-sub-name          = "${local.env}-${local.org}-${var.pub-sub-name}"
  
  # Private Subnet Configuration
  pri-subnet-count      = var.pri-subnet-count      # Number of private subnets to create
  pri-cidr-block        = var.pri-cidr-block        # CIDR blocks for private subnets
  pri-availability-zone = var.pri-availability-zone # AZs for high availability
  pri-sub-name          = "${local.env}-${local.org}-${var.pri-sub-name}"
  
  # Route Table Configuration
  public-rt-name        = "${local.env}-${local.org}-${var.public-rt-name}"
  private-rt-name       = "${local.env}-${local.org}-${var.private-rt-name}"
  
  # NAT Gateway Configuration
  eip-name              = "${local.env}-${local.org}-${var.eip-name}"
  ngw-name              = "${local.env}-${local.org}-${var.ngw-name}"
  
  # Security Group Configuration
  eks-sg                = var.eks-sg

  # IAM Role Enablement Flags
  is_eks_role_enabled           = true  # Enable EKS cluster IAM role creation
  is_eks_nodegroup_role_enabled = true  # Enable node group IAM role creation
  
  # On-Demand Node Group Configuration
  ondemand_instance_types       = var.ondemand_instance_types       # EC2 instance types for on-demand nodes
  desired_capacity_on_demand    = var.desired_capacity_on_demand    # Desired number of on-demand nodes
  min_capacity_on_demand        = var.min_capacity_on_demand        # Minimum on-demand nodes
  max_capacity_on_demand        = var.max_capacity_on_demand        # Maximum on-demand nodes
  
  # Spot Instance Node Group Configuration
  spot_instance_types           = var.spot_instance_types           # EC2 instance types for spot nodes
  desired_capacity_spot         = var.desired_capacity_spot         # Desired number of spot nodes
  min_capacity_spot             = var.min_capacity_spot             # Minimum spot nodes
  max_capacity_spot             = var.max_capacity_spot             # Maximum spot nodes
  
  # EKS Cluster Configuration
  is-eks-cluster-enabled        = var.is-eks-cluster-enabled        # Enable/disable cluster creation
  cluster-version               = var.cluster-version               # Kubernetes version
  endpoint-private-access       = var.endpoint-private-access       # Enable private API endpoint
  endpoint-public-access        = var.endpoint-public-access        # Enable public API endpoint

  # EKS Add-ons Configuration
  # Add-ons like VPC CNI, CoreDNS, kube-proxy
  addons = var.addons
}