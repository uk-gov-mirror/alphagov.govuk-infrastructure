resource "aws_wafv2_ip_set" "origin_cloudfront_ipv4_access" {
  provider           = aws.use1
  name               = "${local.mode}_origin_${var.workspace}_cloudfront_access"
  description        = "access to ${local.mode} origin ${var.workspace} cloudfront"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.external_cidrs_list
}

resource "aws_wafv2_web_acl" "origin_cloudfront_web_acl" {
  provider    = aws.use1
  name        = "${local.mode}_origin_${var.workspace}_cloudfront_web_acl"
  description = "Web ACL for ${local.mode}-origin ${var.workspace} cloudfront"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name     = "allow-requests-from-selected-IPv4-addresses"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.origin_cloudfront_ipv4_access.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.mode}-origin-${var.workspace}-cloudfront-ip-allow"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.mode}-origin-${var.workspace}-cloudfront"
    sampled_requests_enabled   = true
  }
}
