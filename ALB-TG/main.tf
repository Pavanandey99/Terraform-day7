# Security Group for the ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP"
  vpc_id      = "vpc-0ba982939c71a15d4"  

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Target Group
resource "aws_lb_target_group" "TG" {
  name        = "TF"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-0ba982939c71a15d4"  
  target_type = "instance"
  tags = {
    Name = "TG"
  }

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 10
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# ALB
resource "aws_lb" "ALB" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = ["subnet-055a77b3a69f8cd1a", "subnet-0fa001c6d7a2727b0"]
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.TG.arn
  }
}
