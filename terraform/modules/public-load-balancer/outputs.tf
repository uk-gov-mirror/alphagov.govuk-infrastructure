output "target_group_arn" {
  value = aws_lb_target_group.public.arn
}

output "security_group_id" {
  value = aws_security_group.public_alb.id
}
