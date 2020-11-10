terraform {
  backend "s3" {
    bucket  = "govuk-terraform-test"
    key     = "projects/signon.tfstate"
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

module "task_definition" {
  source             = "../../../modules/task-definitions/signon"
  image_tag          = var.image_tag
  mesh_name          = var.mesh_name
  execution_role_arn = data.aws_iam_role.execution.arn
  signon_db_url      = var.signon_db_url
  signon_test_db_url = var.signon_test_db_url
  task_role_arn      = data.aws_iam_role.task.arn
  sentry_environment = var.sentry_environment
  assume_role_arn    = var.assume_role_arn
}
