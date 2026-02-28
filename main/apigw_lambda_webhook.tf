variable "codebuild_project_name" {
  type    = string
  default = "vprofile-devops-dev-build"
}

variable "webhook_secret" {
  type        = string
  sensitive   = true
  default     = null
  description = "Shared secret for Bitbucket webhook header X-Webhook-Secret"
}

# ---- IAM role for Lambda ----
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "webhook_lambda" {
  name               = "${local.name}-webhook-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Basic Lambda logging
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.webhook_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permission to start CodeBuild build (scoped to project)
data "aws_iam_policy_document" "lambda_codebuild" {
  statement {
    actions = ["codebuild:StartBuild"]
    resources = [
      "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.me.account_id}:project/${var.codebuild_project_name}"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_codebuild" {
  name   = "${local.name}-lambda-codebuild"
  role   = aws_iam_role.webhook_lambda.id
  policy = data.aws_iam_policy_document.lambda_codebuild.json
}

# ---- Lambda function ----
resource "aws_lambda_function" "webhook" {
  function_name = "${local.name}-bitbucket-webhook"
  role          = aws_iam_role.webhook_lambda.arn
  runtime       = "python3.12"
  handler       = "handler.handler"
  timeout       = 10

  filename         = "${path.module}/lambda/function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/function.zip")

  environment {
    variables = {
      CODEBUILD_PROJECT_NAME = var.codebuild_project_name
      WEBHOOK_SECRET         = local.effective_webhook_secret
    }
  }
}

# ---- API Gateway HTTP API ----
resource "aws_apigatewayv2_api" "webhook" {
  name          = "${local.name}-webhook-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.webhook.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.webhook.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.webhook.id
  route_key = "POST /webhook"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.webhook.id
  name        = "$default"
  auto_deploy = true
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webhook.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.webhook.execution_arn}/*/*"
}

output "bitbucket_webhook_url" {
  value = "${aws_apigatewayv2_api.webhook.api_endpoint}/webhook"
}
