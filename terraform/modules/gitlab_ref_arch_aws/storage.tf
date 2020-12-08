resource "aws_s3_bucket" "gitlab_object_storage" {
  bucket = "${var.prefix}-object-storage"
  force_destroy = true
}

resource "aws_iam_role" "gitlab_s3_role" {
  name = "${var.prefix}-s3-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "gitlab_s3_policy" {
  name = "${var.prefix}-s3-policy"
  role = aws_iam_role.gitlab_s3_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["s3:*"],
      "Effect": "Allow",
      "Resource": ["${aws_s3_bucket.gitlab_object_storage.arn}","${aws_s3_bucket.gitlab_object_storage.arn}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "gitlab_s3_profile" {
  name = "${var.prefix}-s3-profile"
  role = aws_iam_role.gitlab_s3_role.name
}
