# AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Template autoscaling group
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-template"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Actualizar el sistema e instalar apache, amazon-efs-utils y redis
              yum update -y
              yum install -y httpd amazon-efs-utils redis

              # directorio para montar EFS
              mkdir -p /var/www/html/shared

              # Montar EFS
              mount -t efs ${aws_efs_file_system.main.id}:/ /var/www/html/shared

              # Añadir el montaje a fstab para que persista tras reinicios
              echo "${aws_efs_file_system.main.id}:/ /var/www/html/shared efs defaults,_netdev 0 0" >> /etc/fstab

              # Iniciar y habilitar Apache
              systemctl start httpd
              systemctl enable httpd

              # Crear página con Redis
              cat <<'HTML' > /var/www/html/index.html
              <h1>Servidor Web desde ASG</h1>
              <p>Contenido compartido EFS:</p>
              <div id='shared'></div>
              <p>Contador de visitas (Redis):</p>
              <div id='counter'></div>
              <script>
                fetch('/shared/content.txt').then(r => r.text()).then(t => document.getElementById('shared').innerHTML = t);
              </script>
              HTML

              # Crear contenido compartido
              echo "Este contenido está compartido entre todas las instancias a través de EFS - $(hostname)" > /var/www/html/shared/content.txt

              # Asignar permisos al directorio compartido
              chown -R apache:apache /var/www/html/shared
              chmod -R 755 /var/www/html/shared
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.project_name}-instance"
    })
  }
}

# Target group para ASG
resource "aws_lb_target_group" "asg" {
  name        = replace("${var.project_name}-tg-asg", "_", "-")
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-tg-asg"
  })
}

# Autoscaling group 
resource "aws_autoscaling_group" "main" {
  name                = "${var.project_name}-asg"
  desired_capacity    = 2
  max_size           = 3
  min_size           = 2
  target_group_arns  = [aws_lb_target_group.asg.arn]
  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = true
  }
}

# Balanceador externo
resource "aws_lb" "public" {
  name               = replace("${var.project_name}-alb-public", "_", "-")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_public.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-public"
  })
}

# Balanceador de carga interno
resource "aws_lb" "internal" {
  name               = replace("${var.project_name}-alb-internal", "_", "-")
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_internal.id]
  subnets            = aws_subnet.private[*].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-internal"
  })
}

# Target group interno
resource "aws_lb_target_group" "internal" {
  name        = replace("${var.project_name}-tg-internal", "_", "-")
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-tg-internal"
  })
}

# Listener balanceador público
resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal.arn
  }
}

# Listener balanceador interno
resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}