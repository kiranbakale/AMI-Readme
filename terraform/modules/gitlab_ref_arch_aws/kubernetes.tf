locals {
  eks_custom_ami = var.eks_ami_id != null
  eks_ami_type   = local.eks_custom_ami ? "CUSTOM" : "AL2_x86_64"

  total_node_pool_count = var.webservice_node_pool_count + var.sidekiq_node_pool_count + var.supporting_node_pool_count + var.webservice_node_pool_max_count + var.sidekiq_node_pool_max_count + var.supporting_node_pool_max_count

  webservice_node_pool_autoscaling = var.webservice_node_pool_max_count > 0
  sidekiq_node_pool_autoscaling    = var.sidekiq_node_pool_max_count > 0
  supporting_node_pool_autoscaling = var.supporting_node_pool_max_count > 0

  # Subnet selection
  eks_default_subnet_ids       = local.default_network ? slice(tolist(local.default_subnet_ids), 0, var.eks_default_subnet_count) : []
  eks_cluster_subnet_ids       = !local.default_network ? local.all_subnet_ids : local.eks_default_subnet_ids
  eks_backend_node_subnet_ids  = !local.default_network ? local.backend_subnet_ids : local.eks_default_subnet_ids
  eks_frontend_node_subnet_ids = !local.default_network ? local.frontend_subnet_ids : local.eks_default_subnet_ids
}

# Cluster
resource "aws_eks_cluster" "gitlab_cluster" {
  count = min(local.total_node_pool_count, 1)

  name                      = var.prefix
  version                   = var.eks_version
  role_arn                  = aws_iam_role.gitlab_eks_role[0].arn
  enabled_cluster_log_types = var.eks_enabled_cluster_log_types

  vpc_config {
    endpoint_public_access = var.eks_endpoint_public_access
    public_access_cidrs    = var.eks_endpoint_public_access_cidr_blocks

    endpoint_private_access = true
    subnet_ids              = local.eks_cluster_subnet_ids

    security_group_ids = [
      aws_security_group.gitlab_internal_networking.id,
    ]
  }

  dynamic "encryption_config" {
    for_each = range(var.eks_envelope_encryption ? 1 : 0)

    content {
      provider {
        key_arn = var.eks_envelope_kms_key_arn != null ? var.eks_envelope_kms_key_arn : coalesce(var.default_kms_key_arn, try(aws_kms_key.gitlab_cluster_key[0].arn, null))
      }
      resources = ["secrets"]
    }
  }

  tags = merge({
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "gitlab-cluster"
  }, var.additional_tags)

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.amazon_eks_vpc_resource_controller,
  ]
}

## Optional KMS Key for EKS Envelope Encryption if enabled and none provided (deprecated)
## kics: Terraform AWS - KMS Key With Vulnerable Policy - Key is deprecated and will be removed in future
## kics-scan ignore-block
resource "aws_kms_key" "gitlab_cluster_key" {
  count = var.eks_envelope_encryption && local.total_node_pool_count > 0 && var.eks_envelope_kms_key_arn == null && var.default_kms_key_arn == null ? 1 : 0

  description         = "${var.prefix}-cluster-key"
  enable_key_rotation = true
}

## Optional KMS Key for EKS Envelope Encryption if enabled and none provided
resource "aws_kms_alias" "gitlab_cluster_key" {
  count = var.eks_envelope_encryption && local.total_node_pool_count > 0 && var.eks_envelope_kms_key_arn == null && var.default_kms_key_arn == null ? 1 : 0

  name          = "alias/${var.prefix}-cluster-key"
  target_key_id = aws_kms_key.gitlab_cluster_key[0].arn
}

# Node Pools

resource "aws_launch_template" "gitlab_webservice" {
  count    = local.eks_custom_ami ? min(var.webservice_node_pool_count + var.webservice_node_pool_max_count, 1) : 0
  image_id = var.eks_ami_id

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = coalesce(var.webservice_node_pool_disk_size, var.default_disk_size)
      volume_type           = var.default_disk_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/userdata.sh.tpl", { cluster_name = aws_eks_cluster.gitlab_cluster[0].name }))
}

resource "aws_eks_node_group" "gitlab_webservice_pool" {
  count = min(var.webservice_node_pool_count + var.webservice_node_pool_max_count, 1)

  cluster_name = aws_eks_cluster.gitlab_cluster[0].name

  ami_type = local.eks_ami_type
  version  = local.eks_custom_ami ? null : var.eks_version

  dynamic "launch_template" {
    for_each = range(local.eks_custom_ami ? 1 : 0)

    content {
      id      = aws_launch_template.gitlab_webservice[0].id
      version = aws_launch_template.gitlab_webservice[0].latest_version
    }
  }

  # Create a unique name to allow nodepool replacements
  node_group_name_prefix = "gitlab_webservice_pool_"
  node_role_arn          = aws_iam_role.gitlab_eks_node_role[0].arn
  subnet_ids             = local.eks_backend_node_subnet_ids
  instance_types         = [var.webservice_node_pool_instance_type]
  disk_size              = local.eks_custom_ami ? null : var.webservice_node_pool_disk_size

  scaling_config {
    desired_size = local.webservice_node_pool_autoscaling ? var.webservice_node_pool_min_count : var.webservice_node_pool_count
    min_size     = local.webservice_node_pool_autoscaling ? var.webservice_node_pool_min_count : var.webservice_node_pool_count
    max_size     = local.webservice_node_pool_autoscaling ? var.webservice_node_pool_max_count : var.webservice_node_pool_count
  }

  labels = {
    workload = "webservice"
  }

  tags = merge({
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "webservice-pool"

    "k8s.io/cluster-autoscaler/${aws_eks_cluster.gitlab_cluster[0].name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                                   = "TRUE"
  }, var.additional_tags)

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_iam_role.gitlab_addon_vpc_cni_role,
    # Don't create the node-pools until kube-proxy and vpc_cni plugins are created
    aws_eks_addon.kube_proxy,
    aws_eks_addon.vpc_cni,
  ]

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}

resource "aws_launch_template" "gitlab_sidekiq" {
  count    = local.eks_custom_ami ? min(var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count, 1) : 0
  image_id = var.eks_ami_id

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = coalesce(var.sidekiq_node_pool_disk_size, var.default_disk_size)
      volume_type           = var.default_disk_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/userdata.sh.tpl", { cluster_name = aws_eks_cluster.gitlab_cluster[0].name }))
}


resource "aws_eks_node_group" "gitlab_sidekiq_pool" {
  count = min(var.sidekiq_node_pool_count + var.sidekiq_node_pool_max_count, 1)

  cluster_name = aws_eks_cluster.gitlab_cluster[0].name

  ami_type = local.eks_ami_type
  version  = local.eks_custom_ami ? null : var.eks_version

  dynamic "launch_template" {
    for_each = range(local.eks_custom_ami ? 1 : 0)

    content {
      id      = aws_launch_template.gitlab_sidekiq[0].id
      version = aws_launch_template.gitlab_sidekiq[0].latest_version
    }
  }


  # Create a unique name to allow nodepool replacements
  node_group_name_prefix = "gitlab_sidekiq_pool_"
  node_role_arn          = aws_iam_role.gitlab_eks_node_role[0].arn
  subnet_ids             = local.eks_backend_node_subnet_ids
  instance_types         = [var.sidekiq_node_pool_instance_type]
  disk_size              = local.eks_custom_ami ? null : var.sidekiq_node_pool_disk_size

  scaling_config {
    desired_size = local.sidekiq_node_pool_autoscaling ? var.sidekiq_node_pool_min_count : var.sidekiq_node_pool_count
    min_size     = local.sidekiq_node_pool_autoscaling ? var.sidekiq_node_pool_min_count : var.sidekiq_node_pool_count
    max_size     = local.sidekiq_node_pool_autoscaling ? var.sidekiq_node_pool_max_count : var.sidekiq_node_pool_count
  }

  labels = {
    workload = "sidekiq"
  }

  tags = merge({
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "sidekiq-pool"

    "k8s.io/cluster-autoscaler/${aws_eks_cluster.gitlab_cluster[0].name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                                   = "TRUE"
  }, var.additional_tags)

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_iam_role.gitlab_addon_vpc_cni_role,
    # Don't create the node-pools until kube-proxy and vpc_cni plugins are created
    aws_eks_addon.kube_proxy,
    aws_eks_addon.vpc_cni,
  ]

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}

resource "aws_launch_template" "gitlab_supporting" {
  count    = local.eks_custom_ami ? min(var.supporting_node_pool_count + var.supporting_node_pool_max_count, 1) : 0
  image_id = var.eks_ami_id
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = coalesce(var.supporting_node_pool_disk_size, var.default_disk_size)
      volume_type           = var.default_disk_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/userdata.sh.tpl", { cluster_name = aws_eks_cluster.gitlab_cluster[0].name }))
}

resource "aws_eks_node_group" "gitlab_supporting_pool" {
  count = min(var.supporting_node_pool_count + var.supporting_node_pool_max_count, 1)

  cluster_name = aws_eks_cluster.gitlab_cluster[0].name

  ami_type = local.eks_ami_type
  version  = local.eks_custom_ami ? null : var.eks_version

  dynamic "launch_template" {
    for_each = range(local.eks_custom_ami ? 1 : 0)

    content {
      id      = aws_launch_template.gitlab_supporting[0].id
      version = aws_launch_template.gitlab_supporting[0].latest_version
    }
  }

  # Create a unique name to allow nodepool replacements
  node_group_name_prefix = "gitlab_supporting_pool_"
  node_role_arn          = aws_iam_role.gitlab_eks_node_role[0].arn
  subnet_ids             = local.eks_frontend_node_subnet_ids # Select Public subnets if configured first as this pool hosts NGinx
  instance_types         = [var.supporting_node_pool_instance_type]
  disk_size              = local.eks_custom_ami ? null : var.supporting_node_pool_disk_size

  scaling_config {
    desired_size = local.supporting_node_pool_autoscaling ? var.supporting_node_pool_min_count : var.supporting_node_pool_count
    min_size     = local.supporting_node_pool_autoscaling ? var.supporting_node_pool_min_count : var.supporting_node_pool_count
    max_size     = local.supporting_node_pool_autoscaling ? var.supporting_node_pool_max_count : var.supporting_node_pool_count
  }

  labels = {
    workload = "support"
  }

  tags = merge({
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "supporting-pool"

    "k8s.io/cluster-autoscaler/${aws_eks_cluster.gitlab_cluster[0].name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                                   = "TRUE"
  }, var.additional_tags)

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_iam_role.gitlab_addon_vpc_cni_role,
    # Don't create the node-pools until kube-proxy and vpc_cni plugins are created
    aws_eks_addon.kube_proxy,
    aws_eks_addon.vpc_cni,
  ]

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
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

  permissions_boundary = var.default_iam_permissions_boundary_arn
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

  permissions_boundary = var.default_iam_permissions_boundary_arn
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

## Cluster Autoscaler policy (Optional)
resource "aws_iam_policy" "amazon_eks_node_autoscaler_policy" {
  count = min(var.webservice_node_pool_max_count + var.sidekiq_node_pool_max_count + var.supporting_node_pool_max_count, 1)

  name        = "${var.prefix}-eks-node-cluster-autoscaler"
  description = "Policy for ${var.prefix} Cluster Autoscaler"

  # kics: Terraform AWS - IAM policies allow all ('*') in a statement action - False positive, recommended by AWS for this specific policy.
  # kics-scan ignore-block
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "amazon_eks_node_autoscaler_policy" {
  count = min(var.webservice_node_pool_max_count + var.sidekiq_node_pool_max_count + var.supporting_node_pool_max_count, 1)

  role       = aws_iam_role.gitlab_eks_node_role[0].name
  policy_arn = aws_iam_policy.amazon_eks_node_autoscaler_policy[0].arn
}

# Addons

resource "aws_eks_addon" "kube_proxy" {
  count = min(local.total_node_pool_count, 1)

  cluster_name = aws_eks_cluster.gitlab_cluster[0].name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  count = min(local.total_node_pool_count, 1)

  cluster_name = aws_eks_cluster.gitlab_cluster[0].name
  addon_name   = "coredns"

  # coredns needs nodes to run on, so don't create it until
  # the node-pools have been created
  depends_on = [
    aws_eks_node_group.gitlab_webservice_pool,
    aws_eks_node_group.gitlab_sidekiq_pool,
    aws_eks_node_group.gitlab_supporting_pool
  ]
}

## vpc-cni Addon
resource "aws_eks_addon" "vpc_cni" {
  count = min(local.total_node_pool_count, 1)

  cluster_name             = aws_eks_cluster.gitlab_cluster[0].name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.gitlab_addon_vpc_cni_role[count.index].arn
  resolve_conflicts        = "OVERWRITE"

  depends_on = [
    aws_eks_addon.kube_proxy,
    # Note: To specify an existing IAM role, you must have an IAM OpenID Connect (OIDC) provider created for your cluster.
    aws_iam_openid_connect_provider.gitlab_cluster_openid
  ]
}

data "tls_certificate" "gitlab_cluster_oidc" {
  count = min(local.total_node_pool_count, 1)

  url = aws_eks_cluster.gitlab_cluster[0].identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "gitlab_cluster_openid" {
  count = min(local.total_node_pool_count, 1)

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.gitlab_cluster_oidc[count.index].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.gitlab_cluster[0].identity[0].oidc[0].issuer
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
  name  = "${var.prefix}-gitlab_addon_vpc_cni_role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy[count.index].json

  permissions_boundary = var.default_iam_permissions_boundary_arn
}

resource "aws_iam_role_policy_attachment" "gitlab_addon_vpc_cni_policy" {
  count = min(local.total_node_pool_count, 1)

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.gitlab_addon_vpc_cni_role[count.index].name
}

# Object Storage Role Policy
resource "aws_iam_role_policy_attachment" "gitlab_s3_eks_role_policy_attachment" {
  count = min(local.total_node_pool_count, length(local.gitlab_s3_policy_arns))

  policy_arn = local.gitlab_s3_policy_arns[count.index]
  role       = aws_iam_role.gitlab_eks_node_role[0].name
}

output "kubernetes" {
  value = {
    "kubernetes_cluster_name" = try(aws_eks_cluster.gitlab_cluster[0].name, "")

    # Expose All Roles created for EKS
    "kubernetes_eks_role"           = try(aws_iam_role.gitlab_eks_role[0].name, "")
    "kubernetes_eks_node_role"      = try(aws_iam_role.gitlab_eks_node_role[0].name, "")
    "kubernetes_addon_vpc_cni_role" = try(aws_iam_role.gitlab_addon_vpc_cni_role[0].name, "")

    # Provide the OIDC information to be used outside of this module (e.g. IAM role for other K8s components)
    "kubernetes_cluster_oidc_issuer_url" = try(aws_eks_cluster.gitlab_cluster[0].identity[0].oidc[0].issuer, "")
    "kubernetes_oidc_provider"           = try(replace(aws_eks_cluster.gitlab_cluster[0].identity[0].oidc[0].issuer, "https://", ""), "")
    "kubernetes_oidc_provider_arn"       = try(aws_iam_openid_connect_provider.gitlab_cluster_openid[0].arn, "")
  }
}
