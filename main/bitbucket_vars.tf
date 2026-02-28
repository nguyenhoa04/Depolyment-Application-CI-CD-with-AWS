variable "bitbucket_repo_url" {
  type = string
}

variable "bitbucket_branch" {
  type    = string
  default = "aws-ci"
}

variable "bitbucket_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Optional Bitbucket API token (not required when using CodeConnections)"
}

variable "codestar_connection_arn" {
  type        = string
  description = "AWS CodeConnections ARN for Bitbucket"
}
