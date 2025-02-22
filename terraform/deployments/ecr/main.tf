# This is supposed to be applied in the production environment

terraform {
  backend "s3" {
    bucket  = "govuk-terraform-steppingstone-production"
    key     = "govuk/ecr.tfstate"
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
}

locals {
  repositories = [
    "content-store",
    "frontend",
    "publisher",
    "publishing-api",
    "router",
    "router-api",
    "signon",
    "smokey",
    "static",
    "statsd",
  ]
}

resource "aws_ecr_repository" "content-store" {
  name                 = "content-store"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "publisher" {
  name                 = "publisher"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "publishing-api" {
  name                 = "publishing-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "router" {
  name                 = "router"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "router-api" {
  name                 = "router-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "signon" {
  name                 = "signon"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "smokey" {
  name                 = "smokey"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "static" {
  name                 = "static"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "statsd" {
  name                 = "statsd"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_user" "concourse_ecr_user" {
  name = "concourse_ecr_user"
}

resource "aws_iam_role" "push_image_to_ecr_role" {
  name = "push_image_to_ecr_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "AWS" : aws_iam_user.concourse_ecr_user.arn
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "push_image_to_ecr_policy_document" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = [
      aws_ecr_repository.content-store.arn,
      aws_ecr_repository.frontend.arn,
      aws_ecr_repository.publisher.arn,
      aws_ecr_repository.publishing-api.arn,
      aws_ecr_repository.router.arn,
      aws_ecr_repository.router-api.arn,
      aws_ecr_repository.signon.arn,
      aws_ecr_repository.smokey.arn,
      aws_ecr_repository.static.arn,
      aws_ecr_repository.statsd.arn,
    ]
  }
}

resource "aws_iam_policy" "push_image_to_ecr_policy" {
  name   = "push_image_to_ecr_policy"
  policy = data.aws_iam_policy_document.push_image_to_ecr_policy_document.json
}

resource "aws_iam_role_policy_attachment" "push_to_ecr_role_attachment" {
  role       = aws_iam_role.push_image_to_ecr_role.name
  policy_arn = aws_iam_policy.push_image_to_ecr_policy.arn
}

resource "aws_ecr_repository_policy" "pull_images_from_ecr_policy_policy" {
  for_each   = toset(local.repositories)
  repository = each.key
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCrossAccountPull",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::430354129336:root"
        },
        "Action" : [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "pull_images_from_ecr_role" {
  name = "pull_images_from_ecr_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "AWS" : "arn:aws:iam::430354129336:root"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "pull_images_from_ecr_policy" {
  name = "pull_images_from_ecr_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowECRPull",
        "Effect" : "Allow",
        "Resource" : ["*"],
        "Action" : ["ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:List*",
          "ecr:Describe*"
        ]
      },
      {
        "Sid" : "AllowECRToken",
        "Effect" : "Allow",
        "Resource" : ["*"],
        "Action" : [
          "ecr:GetAuthorizationToken"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pull_images_from_ecr_role_attachment" {
  role       = aws_iam_role.pull_images_from_ecr_role.name
  policy_arn = aws_iam_policy.pull_images_from_ecr_policy.arn
}
