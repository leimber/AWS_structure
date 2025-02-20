#certificado SSL
resource "aws_acm_certificate" "main" {
  domain_name       = "${var.project_name}.local"  
  validation_method = "DNS"

  tags = merge(var.tags, {
    Name = "${var.project_name}-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

#validación 
resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn
}