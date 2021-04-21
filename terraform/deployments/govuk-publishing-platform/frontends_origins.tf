module "www_frontends_origin" {
  source = "../../modules/origin"

  name                                 = "www-frontends"
  vpc_id                               = local.vpc_id
  aws_region                           = data.aws_region.current.name
  assume_role_arn                      = var.assume_role_arn
  public_subnets                       = local.public_subnets
  public_zone_id                       = aws_route53_zone.workspace_public.zone_id
  external_app_domain                  = aws_route53_zone.workspace_public.name
  subdomain                            = "www-origin"
  extra_aliases                        = local.is_default_workspace ? ["www.ecs.${var.publishing_service_domain}"] : []
  load_balancer_certificate_arn        = aws_acm_certificate_validation.workspace_public.certificate_arn
  cloudfront_certificate_arn           = aws_acm_certificate_validation.public_north_virginia.certificate_arn
  publishing_service_domain            = var.publishing_service_domain
  workspace                            = local.workspace
  is_default_workspace                 = local.is_default_workspace
  external_cidrs_list                  = local.is_default_workspace ? concat(var.office_cidrs_list, data.fastly_ip_ranges.fastly.cidr_blocks, local.aws_nat_gateways_cidrs) : concat(var.office_cidrs_list, local.aws_nat_gateways_cidrs)
  rails_assets_s3_regional_domain_name = aws_s3_bucket.frontends_rails_assets.bucket_regional_domain_name

  fronted_apps = {
    "frontend" = { security_group_id = module.frontend.security_group_id },
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "www-f-origin-frontend-${local.workspace}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = module.www_frontends_origin.origin_alb_listerner_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    http_header {
      http_header_name = "X-Cloudfront-Token"
      values           = [module.www_frontends_origin.origin_alb_x_custom_header_secret]
    }
  }
}

module "draft_frontends_origin" {
  source = "../../modules/origin"

  name                                 = "draft-frontends"
  vpc_id                               = local.vpc_id
  aws_region                           = data.aws_region.current.name
  assume_role_arn                      = var.assume_role_arn
  public_subnets                       = local.public_subnets
  public_zone_id                       = aws_route53_zone.workspace_public.zone_id
  external_app_domain                  = aws_route53_zone.workspace_public.name
  subdomain                            = "draft-origin"
  load_balancer_certificate_arn        = aws_acm_certificate_validation.workspace_public.certificate_arn
  cloudfront_certificate_arn           = aws_acm_certificate_validation.public_north_virginia.certificate_arn
  publishing_service_domain            = var.publishing_service_domain
  workspace                            = local.workspace
  is_default_workspace                 = local.is_default_workspace
  external_cidrs_list                  = local.is_default_workspace ? concat(var.office_cidrs_list, data.fastly_ip_ranges.fastly.cidr_blocks, local.aws_nat_gateways_cidrs) : concat(var.office_cidrs_list, local.aws_nat_gateways_cidrs)
  rails_assets_s3_regional_domain_name = aws_s3_bucket.frontends_rails_assets.bucket_regional_domain_name

  fronted_apps = {
    "draft-frontend" = { security_group_id = module.draft_frontend.security_group_id },
  }
}

resource "aws_lb_target_group" "draft_frontend" {
  name        = "draft-f-origin-d-frontend-${local.workspace}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener_rule" "draft_frontend" {
  listener_arn = module.draft_frontends_origin.origin_alb_listerner_arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.draft_frontend.arn
  }

  condition {
    http_header {
      http_header_name = "X-Cloudfront-Token"
      values           = [module.draft_frontends_origin.origin_alb_x_custom_header_secret]
    }
  }
}
