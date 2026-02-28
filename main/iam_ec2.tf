data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${local.name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# SSM (để vào instance không cần SSH)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Pull ECR + read S3 artifacts
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy_document" "ec2_artifacts_read" {
  statement {
    actions = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}/*"
    ]
  }
}

resource "aws_iam_role_policy" "ec2_artifacts_read" {
  name   = "${local.name}-ec2-artifacts-read"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.ec2_artifacts_read.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name}-ec2-profile"
  role = aws_iam_role.ec2.name
}
