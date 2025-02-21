#obtener dirección web

output "alb_dns_name" {
  description = "DNS name of the public ALB"
  value       = aws_lb.public.dns_name
}