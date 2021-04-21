module "backends_origin" {
  source = "../../modules/origin"

  name                                 = "backends"
  vpc_id                               = local.vpc_id
  aws_region                           = data.aws_region.current.name
  assume_role_arn                      = var.assume_role_arn
  public_subnets                       = local.public_subnets
  public_zone_id                       = aws_route53_zone.workspace_public.zone_id
  external_app_domain                  = aws_route53_zone.workspace_public.name
  subdomain                            = "backends"
  extra_aliases                        = compact([local.is_default_workspace ? "publisher.${var.publishing_service_domain}" : null, "publisher.${aws_route53_zone.workspace_public.name}", "signon.${aws_route53_zone.workspace_public.name}"])
  load_balancer_certificate_arn        = aws_acm_certificate_validation.workspace_public.certificate_arn
  cloudfront_certificate_arn           = aws_acm_certificate_validation.public_north_virginia.certificate_arn
  publishing_service_domain            = var.publishing_service_domain
  workspace                            = local.workspace
  is_default_workspace                 = local.is_default_workspace
  external_cidrs_list                  = local.is_default_workspace ? concat(var.office_cidrs_list, data.fastly_ip_ranges.fastly.cidr_blocks, local.aws_nat_gateways_cidrs) : concat(var.office_cidrs_list, local.aws_nat_gateways_cidrs)
  rails_assets_s3_regional_domain_name = aws_s3_bucket.backends_rails_assets.bucket_regional_domain_name

  fronted_apps = {
    "publisher" = { security_group_id = module.publisher_web.security_group_id },
    "signon" = { security_group_id = module.signon.security_group_id },
  }
}

## Publisher

resource "aws_lb_target_group" "publisher" {
  name        = "backends-origin-publisher-${local.workspace}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener_rule" "publisher" {
  listener_arn = module.backends_origin.origin_alb_listerner_arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.publisher.arn
  }

  condition {
    http_header {
      http_header_name = "X-Cloudfront-Token"
      values           = [module.backends_origin.origin_alb_x_custom_header_secret]
    }
  }

  condition {
    host_header {
      values = ["publisher.*"]
    }
  }
}

resource "aws_route53_record" "publisher" {
  zone_id = aws_route53_zone.workspace_public.zone_id
  name    = "publisher"
  type    = "CNAME"
  ttl     = 300
  records = [module.backends_origin.fqdn]
}

## Signon

resource "aws_lb_target_group" "signon" {
  name        = "backends-origin-signon-${local.workspace}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener_rule" "signon" {
  listener_arn = module.backends_origin.origin_alb_listerner_arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.signon.arn
  }

  condition {
    http_header {
      http_header_name = "X-Cloudfront-Token"
      values           = [module.backends_origin.origin_alb_x_custom_header_secret]
    }
  }

  condition {
    host_header {
      values = ["signon.*"]
    }
  }
}

resource "aws_route53_record" "signon" {
  zone_id = aws_route53_zone.workspace_public.zone_id
  name    = "signon"
  type    = "CNAME"
  ttl     = 300
  records = [module.backends_origin.fqdn]
}
