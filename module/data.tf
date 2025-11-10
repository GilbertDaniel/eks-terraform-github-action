# Retrieve the TLS certificate from the EKS cluster's OIDC issuer
# This certificate is used to establish trust with the OIDC provider
data "tls_certificate" "eks-certificate" {
  url = aws_eks_cluster.eks[0].identity[0].oidc[0].issuer
}

# Define IAM policy document for OIDC-based assume role
# This allows Kubernetes service accounts to assume AWS IAM roles using OIDC
data "aws_iam_policy_document" "eks_oidc_assume_role_policy" {
  statement {
    # Allow the service account to assume the role via web identity
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    # Condition to ensure only the specified service account can assume this role
    condition {
      test     = "StringEquals"
      # Match the service account subject in the OIDC token
      variable = "${replace(aws_iam_openid_connect_provider.eks-oidc.url, "https://", "")}:sub"
      # Only allow the 'aws-test' service account in the 'default' namespace
      values   = ["system:serviceaccount:default:aws-test"]
    }

    # The OIDC provider that can perform the assume role action
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks-oidc.arn]
      type        = "Federated"
    }
  }
}