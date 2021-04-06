locals {
  # Needed due to an AWS quota restriction (limit of 5 conditions per rule)
  # In future we may need to request a service quota increase of
  # "Rules per Application Load Balancer" from AWS.
  rules = setproduct(var.restricted_paths, var.unrestricted_cidrs)
}

resource "aws_lb_listener_rule" "allow_unrestricted_cidrs" {
  count = length(local.rules)

  listener_arn = aws_lb_listener.public.arn
  priority     = count.index + 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn
  }

  condition {
    path_pattern {
      values = [local.rules[count.index][0]]
    }
  }

  condition {
    source_ip {
      values = [local.rules[count.index][1]]
    }
  }
}

resource "aws_lb_listener_rule" "restrict_all_other_ips" {
  count = length(var.restricted_paths)

  listener_arn = aws_lb_listener.public.arn
  priority     = length(local.rules) + 2 + count.index

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern {
      values = [var.restricted_paths[count.index]]
    }
  }
}
