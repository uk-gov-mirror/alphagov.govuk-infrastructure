terraform {
  backend "s3" {
    bucket  = "govuk-terraform-test"
    key     = "projects/content-store.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.13"
    }
  }
}

provider "aws" {
  region = "eu-west-1"

  assume_role {
    role_arn = var.assume_role_arn
  }
}

data "aws_secretsmanager_secret" "oauth_id" {
  name = "content-store_OAUTH_ID"
}
data "aws_secretsmanager_secret" "oauth_secret" {
  name = "content-store_OAUTH_SECRET"
}
data "aws_secretsmanager_secret" "publishing_api_bearer_token" {
  name = "content-store_PUBLISHING_API_BEARER_TOKEN" # pragma: allowlist secret
}
data "aws_secretsmanager_secret" "router_api_bearer_token" {
  name = "content-store_ROUTER_API_BEARER_TOKEN" # pragma: allowlist secret
}
data "aws_secretsmanager_secret" "secret_key_base" {
  name = "content-store_SECRET_KEY_BASE" # pragma: allowlist secret
}
data "aws_secretsmanager_secret" "sentry_dsn" {
  name = "SENTRY_DSN"
}

data "aws_iam_role" "execution" {
  name = "fargate_execution_role"
}

data "aws_iam_role" "task" {
  name = "fargate_task_role"
}

locals {
  image_tag = "bill-content-schemas" # TODO: Change back once content schemas are available

  environment = {
    "DEFAULT_TTL"                     = "1800",
    "GOVUK_APP_DOMAIN"                = var.mesh_domain,
    "GOVUK_APP_DOMAIN_EXTERNAL"       = var.app_domain,
    "GOVUK_APP_NAME"                  = "content-store",
    "GOVUK_APP_TYPE"                  = "rack",
    "GOVUK_CONTENT_SCHEMAS_PATH"      = "/govuk-content-schemas",
    "GOVUK_GROUP"                     = "deploy",                             # TODO: clean up?
    "GOVUK_STATSD_PREFIX"             = "fargate",                            # TODO: choose a more useful value
    "GOVUK_USER"                      = "deploy",                             # TODO: clean up?
    "GOVUK_WEBSITE_ROOT"              = "https://frontend.${var.app_domain}", # TODO: Change back to www once router is up
    "MONGODB_URI"                     = "mongodb://${var.mongodb_host}/content_store_production",
    "PLEK_SERVICE_PUBLISHING_API_URI" = "http://publishing-api-web.${var.mesh_domain}",
    "PLEK_SERVICE_ROUTER_API_URI"     = "http://router-api.${var.mesh_domain}"
    "PLEK_SERVICE_RUMMAGER_URI"       = "",
    "PLEK_SERVICE_SIGNON_URI"         = "https://signon-ecs.${var.app_domain}",
    "PLEK_SERVICE_SPOTLIGHT_URI"      = "",
    "PORT"                            = "80",
    "RAILS_ENV"                       = "production",
    "SENTRY_ENVIRONMENT"              = var.sentry_environment,
    "STATSD_HOST"                     = "statsd.${var.mesh_domain}",
    "STATSD_PROTOCOL"                 = "tcp",
    "UNICORN_WORKER_PROCESSES"        = "12",

    "PLEK_SERVICE_PERFORMANCEPLATFORM_BIG_SCREEN_VIEW_URI" = "",
  }

  secrets = {
    "GDS_SSO_OAUTH_ID"            = data.aws_secretsmanager_secret.oauth_id.arn,
    "GDS_SSO_OAUTH_SECRET"        = data.aws_secretsmanager_secret.oauth_secret.arn,
    "PUBLISHING_API_BEARER_TOKEN" = data.aws_secretsmanager_secret.publishing_api_bearer_token.arn,
    "ROUTER_API_BEARER_TOKEN"     = data.aws_secretsmanager_secret.router_api_bearer_token.arn,
    "SECRET_KEY_BASE"             = data.aws_secretsmanager_secret.secret_key_base.arn,
    "SENTRY_DSN"                  = data.aws_secretsmanager_secret.sentry_dsn.arn,
  }
}

# TODO: delete this module once terraform is applied
module "task_definition" {
  source = "../../../modules/task-definitions/content-store"
}