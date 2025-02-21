# AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Launch template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-template"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd amazon-efs-utils redis
              mkdir -p /var/www/html/shared
              mount -t efs ${aws_efs_file_system.main.id}:/ /var/www/html/shared
              echo "${aws_efs_file_system.main.id}:/ /var/www/html/shared efs defaults,_netdev 0 0" >> /etc/fstab
              systemctl start httpd
              systemctl enable httpd
              cat <<'HTML' > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Lab4 HackABoss</title>
                  <style>
                      body { 
                          font-family: Arial, sans-serif;
                          text-align: center;
                          padding-top: 50px;
                          background-color: #f0f0f0;
                      }
                      .container {
                          background-color: white;
                          padding: 20px;
                          border-radius: 10px;
                          box-shadow: 0 0 10px rgba(0,0,0,0.1);
                          margin: auto;
                          max-width: 600px;
                      }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1>¡Bienvenido al Lab4 de AWS!</h1>
                      <p>Servidor: $(hostname)</p>
                      <p>Fecha: $(date)</p>
                      <p>Esta infraestructura incluye:</p>
                      <ul style="list-style: none;">
                          <li>✅ Auto Scaling Group</li>
                          <li>✅ Load Balancers</li>
                          <li>✅ Redis Cache</li>
                          <li>✅ RDS Database</li>
                          <li>✅ EFS Storage</li>
                      </ul>
                      <p>Contenido compartido EFS:</p>
                      <div id='shared'></div>
                  </div>
                  <script>
                    fetch('/shared/content.txt').then(r => r.text()).then(t => document.getElementById('shared').innerHTML = t);
                  </script>
              </body>
              </html>
              HTML
              echo "Este contenido está compartido entre todas las instancias a través de EFS - $(hostname)" > /var/www/html/shared/content.txt
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

# Target group para ALB público
resource "aws_lb_target_group" "public" {
  name        = replace("${var.project_name}-tg-public", "_", "-")
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-tg-public"
  })
}

# Target group para ALB interno (mantener configuración original que funciona)
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

# Auto Scaling Group para instancias del balanceador público
resource "aws_autoscaling_group" "public" {
  name                = "${var.project_name}-asg-public"
  desired_capacity    = 2
  max_size           = 3
  min_size           = 2
  target_group_arns  = [aws_lb_target_group.public.arn]
  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-public"
    propagate_at_launch = true
  }
}

# Auto Scaling Group para instancias del balanceador interno
resource "aws_autoscaling_group" "internal" {
  name                = "${var.project_name}-asg-internal"
  desired_capacity    = 2
  max_size           = 3
  min_size           = 2
  target_group_arns  = [aws_lb_target_group.internal.arn]
  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-internal"
    propagate_at_launch = true
  }
}

# Balanceador público
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

# Balanceador interno
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

# Listener balanceador público
resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn
  }
}

# Listener balanceador interno
resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal.arn
  }
}