resource "aws_s3_bucket" "gitlab_object_storage_buckets" {
  for_each = toset(var.object_storage_buckets)
  bucket = "${var.prefix}-${each.value}"
  force_destroy = true
}

resource "aws_iam_role" "gitlab_s3_role" {
  count = min(length(var.object_storage_buckets), 1)
  name  = "${var.prefix}-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "gitlab_s3_policy" {
  count = min(length(var.object_storage_buckets), 1)
  name  = "${var.prefix}-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = concat([for bucket in aws_s3_bucket.gitlab_object_storage_buckets : bucket.arn], [for bucket in aws_s3_bucket.gitlab_object_storage_buckets : "${bucket.arn}/*"])
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy_profile_attachment" {
  count = min(length(var.object_storage_buckets), 1)

  policy_arn = aws_iam_policy.gitlab_s3_policy[0].arn
  role       = aws_iam_role.gitlab_s3_role[0].name
}

resource "aws_iam_instance_profile" "gitlab_s3_profile" {
  count = min(length(var.object_storage_buckets), 1)
  name  = "${var.prefix}-s3-profile"
  role  = aws_iam_role.gitlab_s3_role[0].name
}