locals {
  total_node_pool_count = max(sum([var.webservice_node_pool_count, var.sidekiq_node_pool_count, var.supporting_node_pool_count]), 0)
  eks_subnet_ids        = local.subnet_ids != null ? local.subnet_ids : slice(tolist(local.default_subnet_ids), 0, var.eks_default_subnet_count)
}

# Cluster

resource "aws_eks_cluster" "gitlab_cluster" {
  count = min(local.total_node_pool_count, 1)

  name     = var.prefix
  role_arn = aws_iam_role.gitlab_eks_role[0].arn

  vpc_config {
    subnet_ids = local.eks_subnet_ids

    security_group_ids = [
      aws_security_group.gitlab_internal_networking.id,
    ]
  }

  tags = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "gitlab-cluster"
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.amazon_eks_vpc_resource_controller,
  ]
}

# Node Pools

resource "aws_eks_node_group" "gitlab_webservice_pool" {
  count = min(var.webservice_node_pool_count, 1)

  cluster_name    = aws_eks_cluster.gitlab_cluster[count.index].name
  node_group_name = "gitlab_webservice_pool"
  node_role_arn   = aws_iam_role.gitlab_eks_node_role[0].arn
  subnet_ids      = local.eks_subnet_ids
  instance_types  = [var.webservice_node_pool_instance_type]
  disk_size       = var.webservice_node_pool_disk_size

  scaling_config {
    desired_size = var.webservice_node_pool_count
    max_size     = var.webservice_node_pool_count
    min_size     = var.webservice_node_pool_count
  }

  labels = {
    workload = "webservice"
  }

  tags = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "webservice-pool"
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_iam_role.gitlab_addon_vpc_cni_role,
  ]
}

resource "aws_eks_node_group" "gitlab_sidekiq_pool" {
  count = min(var.sidekiq_node_pool_count, 1)

  cluster_name    = aws_eks_cluster.gitlab_cluster[count.index].name
  node_group_name = "gitlab_sidekiq_pool"
  node_role_arn   = aws_iam_role.gitlab_eks_node_role[0].arn
  subnet_ids      = local.eks_subnet_ids
  instance_types  = [var.sidekiq_node_pool_instance_type]
  disk_size       = var.sidekiq_node_pool_disk_size

  scaling_config {
    desired_size = var.sidekiq_node_pool_count
    max_size     = var.sidekiq_node_pool_count
    min_size     = var.sidekiq_node_pool_count
  }

  labels = {
    workload = "sidekiq"
  }

  tags = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "sidekiq-pool"
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_iam_role.gitlab_addon_vpc_cni_role,
  ]
}

resource "aws_eks_node_group" "gitlab_supporting_pool" {
  count = min(var.supporting_node_pool_count, 1)

  cluster_name    = aws_eks_cluster.gitlab_cluster[count.index].name
  node_group_name = "gitlab_supporting_pool"
  node_role_arn   = aws_iam_role.gitlab_eks_node_role[0].arn
  subnet_ids      = local.eks_subnet_ids
  instance_types  = [var.supporting_node_pool_instance_type]
  disk_size       = var.supporting_node_pool_disk_size

  scaling_config {
    desired_size = var.supporting_node_pool_count
    max_size     = var.supporting_node_pool_count
    min_size     = var.supporting_node_pool_count
  }

  labels = {
    workload = "support"
  }

  tags = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "supporting-pool"
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_iam_role.gitlab_addon_vpc_cni_role,
  ]
}

# Roles

resource "aws_iam_role" "gitlab_eks_role" {
  count = min(local.total_node_pool_count, 1)
  name  = "${var.prefix}-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role" "gitlab_eks_node_role" {
  count = min(local.total_node_pool_count, 1)
  name  = "${var.prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Policies

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  count      = min(local.total_node_pool_count, 1)
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.gitlab_eks_role[0].name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_vpc_resource_controller" {
  count      = min(local.total_node_pool_count, 1)
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.gitlab_eks_role[0].name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  count      = min(local.total_node_pool_count, 1)
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.gitlab_eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  count      = min(local.total_node_pool_count, 1)
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.gitlab_eks_node_role[0].name
}

# Addons

resource "aws_eks_addon" "kube_proxy" {
  count = min(local.total_node_pool_count, 1)

  cluster_name = aws_eks_cluster.gitlab_cluster[count.index].name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  count = min(local.total_node_pool_count, 1)

  cluster_name = aws_eks_cluster.gitlab_cluster[count.index].name
  addon_name   = "coredns"
}

## vpc-cni Addon

resource "aws_eks_addon" "vpc_cni" {
  count = min(local.total_node_pool_count, 1)

  cluster_name             = aws_eks_cluster.gitlab_cluster[count.index].name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.gitlab_addon_vpc_cni_role[count.index].arn
}

data "tls_certificate" "gitlab_cluster_oidc" {
  count = min(local.total_node_pool_count, 1)

  url = aws_eks_cluster.gitlab_cluster[count.index].identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "gitlab_cluster_openid" {
  count = min(local.total_node_pool_count, 1)

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.gitlab_cluster_oidc[count.index].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.gitlab_cluster[count.index].identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = min(local.total_node_pool_count, 1)

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.gitlab_cluster_openid[count.index].url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.gitlab_cluster_openid[count.index].arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "gitlab_addon_vpc_cni_role" {
  count = min(local.total_node_pool_count, 1)

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy[count.index].json
  name               = "${var.prefix}-gitlab_addon_vpc_cni_role"
}

resource "aws_iam_role_policy_attachment" "gitlab_addon_vpc_cni_policy" {
  count = min(local.total_node_pool_count, 1)

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.gitlab_addon_vpc_cni_role[count.index].name
}

# Object Storage Role Policy
resource "aws_iam_role_policy_attachment" "gitlab_s3_eks_role_policy_attachment" {
  count = min(local.total_node_pool_count, length(var.object_storage_buckets), 1)

  policy_arn = aws_iam_policy.gitlab_s3_policy[0].arn
  role       = aws_iam_role.gitlab_eks_node_role[0].name
}
