# EKS Cluster Resource
# Creates the main EKS control plane
resource "aws_eks_cluster" "eks" {

  count    = var.is-eks-cluster-enabled == true ? 1 : 0
  name     = var.cluster-name
  role_arn = aws_iam_role.eks-cluster-role[count.index].arn
  version  = var.cluster-version

  # VPC Configuration
  # Defines networking settings including subnets and endpoint access
  vpc_config {
    subnet_ids              = [aws_subnet.private-subnet[0].id, aws_subnet.private-subnet[1].id, aws_subnet.private-subnet[2].id]
    endpoint_private_access = var.endpoint-private-access  # Enable/disable private API server endpoint
    endpoint_public_access  = var.endpoint-public-access   # Enable/disable public API server endpoint
    security_group_ids      = [aws_security_group.eks-cluster-sg.id]
  }


  # Access Configuration
  # Defines authentication mode and bootstrap permissions
  access_config {
    authentication_mode                         = "CONFIG_MAP"  # Use ConfigMap for authentication
    bootstrap_cluster_creator_admin_permissions = true          # Grant cluster creator admin permissions
  }

  tags = {
    Name = var.cluster-name
    Env  = var.env
  }
}

# OIDC Provider for EKS
# Enables IAM roles for service accounts (IRSA)
# Allows Kubernetes pods to assume AWS IAM roles
resource "aws_iam_openid_connect_provider" "eks-oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-certificate.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.eks-certificate.url
}


# EKS Add-ons
# Installs and manages EKS add-ons like VPC CNI, CoreDNS, kube-proxy
# These are operational software for EKS clusters
resource "aws_eks_addon" "eks-addons" {
  for_each      = { for idx, addon in var.addons : idx => addon }
  cluster_name  = aws_eks_cluster.eks[0].name
  addon_name    = each.value.name
  addon_version = each.value.version

  # Wait for node groups to be created before installing add-ons
  depends_on = [
    aws_eks_node_group.ondemand-node,
    aws_eks_node_group.spot-node
  ]
}

# On-Demand Node Group
# Creates a managed node group using on-demand EC2 instances
# Provides stable, predictable compute capacity for production workloads
resource "aws_eks_node_group" "ondemand-node" {
  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "${var.cluster-name}-on-demand-nodes"

  node_role_arn = aws_iam_role.eks-nodegroup-role[0].arn

  # Auto Scaling Configuration
  scaling_config {
    desired_size = var.desired_capacity_on_demand
    min_size     = var.min_capacity_on_demand
    max_size     = var.max_capacity_on_demand
  }


  # Deploy nodes across multiple private subnets for high availability
  subnet_ids = [aws_subnet.private-subnet[0].id, aws_subnet.private-subnet[1].id, aws_subnet.private-subnet[2].id]

  instance_types = var.ondemand_instance_types
  capacity_type  = "ON_DEMAND"  # Use on-demand pricing model
  labels = {
    type = "ondemand"  # Kubernetes label for workload scheduling
  }

  # Update Configuration
  # Controls how many nodes can be unavailable during updates
  update_config {
    max_unavailable = 1
  }
  tags = {
    "Name" = "${var.cluster-name}-ondemand-nodes"
  }

  depends_on = [aws_eks_cluster.eks]
}

# Spot Instance Node Group
# Creates a managed node group using spot EC2 instances
# Provides cost-optimized compute capacity (up to 90% savings)
# Suitable for fault-tolerant, stateless workloads
resource "aws_eks_node_group" "spot-node" {
  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "${var.cluster-name}-spot-nodes"

  node_role_arn = aws_iam_role.eks-nodegroup-role[0].arn

  # Auto Scaling Configuration
  scaling_config {
    desired_size = var.desired_capacity_spot
    min_size     = var.min_capacity_spot
    max_size     = var.max_capacity_spot
  }


  # Deploy nodes across multiple private subnets for high availability
  subnet_ids = [aws_subnet.private-subnet[0].id, aws_subnet.private-subnet[1].id, aws_subnet.private-subnet[2].id]

  instance_types = var.spot_instance_types
  capacity_type  = "SPOT"  # Use spot pricing model for cost savings

  # Update Configuration
  # Controls how many nodes can be unavailable during updates
  update_config {
    max_unavailable = 1
  }
  tags = {
    "Name" = "${var.cluster-name}-spot-nodes"
  }
  # Kubernetes labels for workload scheduling and spot instance awareness
  labels = {
    type      = "spot"
    lifecycle = "spot"
  }
  disk_size = 50  # Root volume size in GB

  depends_on = [aws_eks_cluster.eks]
}