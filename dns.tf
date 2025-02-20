# Zona DNS privada
resource "aws_route53_zone" "private" {
  name = var.domain_name

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = var.tags
}

# Registro para ALB interno
resource "aws_route53_record" "internal" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "internal.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = true
  }
}

# Registro para ALB público
resource "aws_route53_record" "public" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.public.dns_name
    zone_id                = aws_lb.public.zone_id
    evaluate_target_health = true
  }
}