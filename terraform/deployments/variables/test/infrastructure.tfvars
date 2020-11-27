ecs_default_capacity_provider = "FARGATE_SPOT"

#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

# TODO: Could this be named more clearly?
internal_domain        = "govuk-internal.digital"
public_domain          = "govuk.digital"
public_lb_subdomain    = "test"
public_lb_domain_name  = "test.govuk.digital"
internal_domain_name   = "test.govuk-internal.digital"
govuk_aws_state_bucket = "govuk-terraform-steppingstone-test"
