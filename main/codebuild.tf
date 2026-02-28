data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${local.name}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    actions = [
      "codeconnections:UseConnection",
      "codeconnections:GetConnection",
      "codeconnections:GetConnectionToken",
      "codeconnections:PassConnection"
    ]
    resources = [var.codestar_connection_arn]
  }

  statement {
    actions = [
      "codestar-connections:UseConnection",
      "codestar-connections:GetConnection",
      "codestar-connections:GetConnectionToken",
      "codestar-connections:PassConnection"
    ]
    resources = [var.codestar_connection_arn]
  }

  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["*"]
  }

  statement {
    actions = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.artifacts.bucket}/*"
    ]
  }

  statement {
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_inline" {
  name   = "${local.name}-codebuild-inline"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

resource "aws_codebuild_source_credential" "bitbucket_connection" {
  auth_type   = "CODECONNECTIONS"
  server_type = "BITBUCKET"
  token       = var.codestar_connection_arn
}

resource "aws_codebuild_project" "app" {
  name         = "${local.name}-build"
  service_role = aws_iam_role.codebuild.arn
  depends_on = [
    aws_iam_role_policy.codebuild_inline,
    aws_codebuild_source_credential.bitbucket_connection
  ]

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_REGION"
      value = var.region
    }

    environment_variable {
      name  = "ECR_REPO_URL"
      value = aws_ecr_repository.app.repository_url
    }

    environment_variable {
      name  = "ARTIFACT_BUCKET"
      value = aws_s3_bucket.artifacts.bucket
    }

    environment_variable {
      name  = "CODEDEPLOY_APP"
      value = aws_codedeploy_app.app.name
    }

    environment_variable {
      name  = "CODEDEPLOY_DG"
      value = aws_codedeploy_deployment_group.app.deployment_group_name
    }
  }

  source {
    type            = "BITBUCKET"
    location        = var.bitbucket_repo_url
    buildspec       = "cicd/buildspec.yml"
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }
}
# resource "aws_codebuild_webhook" "app" {
#   project_name = aws_codebuild_project.app.name

#   filter_group {
#     filter {
#       type    = "EVENT"
#       pattern = "PUSH"
#     }
#     filter {
#       type    = "HEAD_REF"
#       pattern = "refs/heads/${var.bitbucket_branch}"
#     }
#   }
# }
