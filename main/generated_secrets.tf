locals {
  generated_db_password    = format("Db%s!9aA", substr(md5("${local.name}-${data.aws_caller_identity.me.account_id}"), 0, 12))
  effective_db_password    = coalesce(var.db_password, local.generated_db_password)
  generated_webhook_secret = substr(sha256("${local.name}-${data.aws_caller_identity.me.account_id}-${data.aws_region.current.name}"), 0, 32)
  effective_webhook_secret = coalesce(var.webhook_secret, local.generated_webhook_secret)
}
