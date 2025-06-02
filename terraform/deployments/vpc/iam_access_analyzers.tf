# Creates IAM Access Analyzers in each AWS region.
# This file has loads of providers because Terraform requires one provider per region.

provider "aws" {
  region = "ap-northeast-1"
  alias = "aa-ap-northeast-1"
  # Use global STS endpoint so we don't have to enable STS in every region
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "ap-northeast-1" {
  analyzer_name = "govuk-ap-northeast-1"
  provider = aws.aa-ap-northeast-1
  # Don't create Access Analyzers in ephemeral environments
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "ap-northeast-2"
  alias = "aa-ap-northeast-2"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "ap-northeast-2" {
  analyzer_name = "govuk-ap-northeast-2"
  provider = aws.aa-ap-northeast-2
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "ap-northeast-3"
  alias = "aa-ap-northeast-3"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "ap-northeast-3" {
  analyzer_name = "govuk-ap-northeast-3"
  provider = aws.aa-ap-northeast-3
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "ap-south-1"
  alias = "aa-ap-south-1"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "ap-south-1" {
  analyzer_name = "govuk-ap-south-1"
  provider = aws.aa-ap-south-1
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "ap-southeast-1"
  alias = "aa-ap-southeast-1"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "ap-southeast-1" {
  analyzer_name = "govuk-ap-southeast-1"
  provider = aws.aa-ap-southeast-1
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "ap-southeast-2"
  alias = "aa-ap-southeast-2"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "ap-southeast-2" {
  analyzer_name = "govuk-ap-southeast-2"
  provider = aws.aa-ap-southeast-2
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "ca-central-1"
  alias = "aa-ca-central-1"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "ca-central-1" {
  analyzer_name = "govuk-ca-central-1"
  provider = aws.aa-ca-central-1
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "eu-central-1"
  alias = "aa-eu-central-1"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "eu-central-1" {
  analyzer_name = "govuk-eu-central-1"
  provider = aws.aa-eu-central-1
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "eu-north-1"
  alias = "aa-eu-north-1"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "eu-north-1" {
  analyzer_name = "govuk-eu-north-1"
  provider = aws.aa-eu-north-1
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "eu-west-1"
  alias = "aa-eu-west-1"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "eu-west-1" {
  analyzer_name = "govuk-eu-west-1"
  provider = aws.aa-eu-west-1
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "eu-west-2"
  alias = "aa-eu-west-2"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "eu-west-2" {
  analyzer_name = "govuk-eu-west-2"
  provider = aws.aa-eu-west-2
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "eu-west-3"
  alias = "aa-eu-west-3"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "eu-west-3" {
  analyzer_name = "govuk-eu-west-3"
  provider = aws.aa-eu-west-3
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "sa-east-1"
  alias = "aa-sa-east-1"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "sa-east-1" {
  analyzer_name = "govuk-sa-east-1"
  provider = aws.aa-sa-east-1
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "us-east-1"
  alias = "aa-us-east-1"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "us-east-1" {
  analyzer_name = "govuk-us-east-1"
  provider = aws.aa-us-east-1
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "us-east-2"
  alias = "aa-us-east-2"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "us-east-2" {
  analyzer_name = "govuk-us-east-2"
  provider = aws.aa-us-east-2
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "us-west-1"
  alias = "aa-us-west-1"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "us-west-1" {
  analyzer_name = "govuk-us-west-1"
  provider = aws.aa-us-west-1
  count = local.is_ephemeral ? 0 : 1
}

provider "aws" {
  region = "us-west-2"
  alias = "aa-us-west-2"
  sts_region = "us-east-1"
  endpoints {
    sts = "https://sts.amazonaws.com"
  }
}

resource "aws_accessanalyzer_analyzer" "us-west-2" {
  analyzer_name = "govuk-us-west-2"
  provider = aws.aa-us-west-2
  count = local.is_ephemeral ? 0 : 1
}

