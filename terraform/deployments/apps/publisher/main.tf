terraform {
  backend "s3" {
    key     = "projects/publisher.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-west-1"

  assume_role {
    role_arn = var.assume_role_arn
  }
}

data "aws_region" "current" {}

data "aws_secretsmanager_secret" "asset_manager_bearer_token" {
  name = "publisher_app-ASSET_MANAGER_BEARER_TOKEN"
}
data "aws_secretsmanager_secret" "fact_check_password" {
  name = "publisher_app-FACT_CHECK_PASSWORD"
}
data "aws_secretsmanager_secret" "fact_check_reply_to_address" {
  name = "publisher_app-FACT_CHECK_REPLY_TO_ADDRESS"
}
data "aws_secretsmanager_secret" "fact_check_reply_to_id" {
  name = "publisher_app-FACT_CHECK_REPLY_TO_ID"
}
data "aws_secretsmanager_secret" "govuk_notify_api_key" {
  name = "publisher_app-GOVUK_NOTIFY_API_KEY"
}
data "aws_secretsmanager_secret" "govuk_notify_template_id" {
  name = "publisher_app-GOVUK_NOTIFY_TEMPLATE_ID" # pragma: allowlist secret
}
data "aws_secretsmanager_secret" "jwt_auth_secret" {
  name = "publisher_app-JWT_AUTH_SECRET"
}
data "aws_secretsmanager_secret" "link_checker_api_bearer_token" {
  name = "publisher_app-LINK_CHECKER_API_BEARER_TOKEN"
}
data "aws_secretsmanager_secret" "link_checker_api_secret_token" {
  name = "publisher_app-LINK_CHECKER_API_SECRET_TOKEN"
}
data "aws_secretsmanager_secret" "mongodb_uri" {
  name = "publisher_app-MONGODB_URI"
}
data "aws_secretsmanager_secret" "oauth_id" {
  name = "publisher_app-OAUTH_ID"
}
data "aws_secretsmanager_secret" "oauth_secret" {
  name = "publisher_app-OAUTH_SECRET"
}
data "aws_secretsmanager_secret" "publishing_api_bearer_token" {
  name = "publisher_app-PUBLISHING_API_BEARER_TOKEN" # pragma: allowlist secret
}

data "aws_secretsmanager_secret" "secret_key_base" {
  name = "publisher_app-SECRET_KEY_BASE" # pragma: allowlist secret
}
data "aws_secretsmanager_secret" "sentry_dsn" {
  name = "SENTRY_DSN"
}

data "terraform_remote_state" "govuk" {
  backend   = "s3"
  workspace = terraform.workspace
  config = {
    bucket   = "govuk-terraform-${var.environment}"
    key      = "projects/govuk.tfstate"
    region   = data.aws_region.current.name
    role_arn = var.assume_role_arn
  }
}

locals {
  app_domain                     = data.terraform_remote_state.govuk.outputs.app_domain
  app_domain_internal            = data.terraform_remote_state.govuk.outputs.app_domain_internal
  fargate_execution_iam_role_arn = data.terraform_remote_state.govuk.outputs.fargate_execution_iam_role_arn
  fargate_task_iam_role_arn      = data.terraform_remote_state.govuk.outputs.fargate_task_iam_role_arn
  govuk_website_root             = data.terraform_remote_state.govuk.outputs.govuk_website_root
  log_group                      = data.terraform_remote_state.govuk.outputs.log_group
  mesh_domain                    = data.terraform_remote_state.govuk.outputs.mesh_domain
  mesh_name                      = data.terraform_remote_state.govuk.outputs.mesh_name

  sentry_environment = "${var.environment}-ecs"
  statsd_host        = "statsd.${local.mesh_domain}" # TODO: Put Statsd in App Mesh

  # TODO fix all the var. whatevers.
  environment_variables = {
    BASIC_AUTH_USERNAME              = "gds",
    EMAIL_GROUP_BUSINESS             = "test-address@digital.cabinet-office.gov.uk",
    EMAIL_GROUP_CITIZEN              = "test-address@digital.cabinet-office.gov.uk",
    EMAIL_GROUP_DEV                  = "test-address@digital.cabinet-office.gov.uk",
    EMAIL_GROUP_FORCE_PUBLISH_ALERTS = "test-address@digital.cabinet-office.gov.uk",
    FACT_CHECK_SUBJECT_PREFIX        = "dev",
    FACT_CHECK_USERNAME              = "govuk-fact-check-test@digital.cabinet-office.gov.uk",
    GOVUK_APP_DOMAIN                 = local.mesh_domain,
    GOVUK_APP_DOMAIN_EXTERNAL        = local.app_domain,
    GOVUK_APP_NAME                   = "publisher",
    GOVUK_APP_ROOT                   = "/app",
    GOVUK_APP_TYPE                   = "rack",
    GOVUK_STATSD_PREFIX              = "fargate",

    # TODO: how does GOVUK_ASSET_ROOT relate to ASSET_HOST? Is one a function of the other? Are they both really in use? Is GOVUK_ASSET_ROOT always just https://${ASSET_HOST}?
    GOVUK_ASSET_ROOT                = "https://assets.${local.app_domain}", # TODO don't hardcode test
    GOVUK_GROUP                     = "deploy",
    GOVUK_USER                      = "deploy",
    GOVUK_WEBSITE_ROOT              = local.govuk_website_root,
    PLEK_SERVICE_PUBLISHING_API_URI = "http://publishing-api-web.${local.mesh_domain}",
    PLEK_SERVICE_SIGNON_URI         = "https://signon-ecs.${local.mesh_domain}",
    PLEK_SERVICE_STATIC_URI         = "https://assets.${local.mesh_domain}",

    # TODO: remove PLEK_SERVICE_DRAFT_ORIGIN_URI once we have the draft origin properly set up with multiple frontends
    PLEK_SERVICE_DRAFT_ORIGIN_URI = "https://draft-frontend.${local.app_domain}",
    PORT                          = "80",
    RAILS_ENV                     = "production",
    RAILS_SERVE_STATIC_FILES      = "true", # TODO: temporary hack?

    # TODO: we shouldn't be specifying both REDIS_{HOST,PORT} *and* REDIS_URL.
    REDIS_HOST         = "TODO" # var.redis_host, # TODO - provide this in the terraform outputs of govuk, and use that.
    REDIS_PORT         = "TODO" # tostring(var.redis_port),
    REDIS_URL          = "TODO" # "redis://${var.redis_host}:${var.redis_port}",
    STATSD_PROTOCOL    = "tcp",
    STATSD_HOST        = local.statsd_host,
    WEBSITE_ROOT       = "https://frontend.${local.app_domain}" # TODO - set this back to www once we have router running
    SENTRY_ENVIRONMENT = local.sentry_environment
  }

  secrets_from_arns = {
    ASSET_MANAGER_BEARER_TOKEN    = data.aws_secretsmanager_secret.asset_manager_bearer_token.arn,
    FACT_CHECK_PASSWORD           = data.aws_secretsmanager_secret.fact_check_password.arn,
    FACT_CHECK_REPLY_TO_ADDRESS   = data.aws_secretsmanager_secret.fact_check_reply_to_address.arn,
    FACT_CHECK_REPLY_TO_ID        = data.aws_secretsmanager_secret.fact_check_reply_to_id.arn,
    GOVUK_NOTIFY_API_KEY          = data.aws_secretsmanager_secret.govuk_notify_api_key.arn,
    GOVUK_NOTIFY_TEMPLATE_ID      = data.aws_secretsmanager_secret.govuk_notify_template_id.arn,
    JWT_AUTH_SECRET               = data.aws_secretsmanager_secret.jwt_auth_secret.arn,
    LINK_CHECKER_API_BEARER_TOKEN = data.aws_secretsmanager_secret.link_checker_api_bearer_token.arn,
    LINK_CHECKER_API_SECRET_TOKEN = data.aws_secretsmanager_secret.link_checker_api_secret_token.arn,

    # TODO: Only the password should be a secret in the MONGODB_URI.
    MONGODB_URI                 = data.aws_secretsmanager_secret.mongodb_uri.arn,
    GDS_SSO_OAUTH_ID            = data.aws_secretsmanager_secret.oauth_id.arn,
    GDS_SSO_OAUTH_SECRET        = data.aws_secretsmanager_secret.oauth_secret.arn,
    PUBLISHING_API_BEARER_TOKEN = data.aws_secretsmanager_secret.publishing_api_bearer_token.arn,
    SECRET_KEY_BASE             = data.aws_secretsmanager_secret.secret_key_base.arn,
    SENTRY_DSN                  = data.aws_secretsmanager_secret.sentry_dsn.arn
  }
}