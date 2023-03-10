terraform {
  # 테라폼 버전 지정 
  required_version = ">= 1.0.0, < 2.0.0"

  # 공급자 버전 지정
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

  }

}

provider "aws" {
  region = "ap-northeast-2"
}

# 시작 템플릿 설정
resource "aws_launch_template" "example" {
  image_id               = "ami-06eea3cd85e2db8ce" #ubuntu 20.04
  instance_type          = "t2.micro"
  key_name               = "aws14-key"
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data              = base64encode(data.template_file.web_output.rendered)

  lifecycle {
    create_before_destroy = true
  }
}

# 오토 스케일링 그룹 생성
resource "aws_autoscaling_group" "example" {
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]

  desired_capacity = 1
  min_size         = 1
  max_size         = 2

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"


  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "aws14-terraform-asg-example"
    propagate_at_launch = true
  }

}
###### 로드밸런서 설정
resource "aws_lb" "example" {
  name               = "aws14-terrafrom-asg-example"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
}

###### 로드밸런서 리스너 설정
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  # 기본값으로 단순한 404 페이지 오류를 반환한다
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

###### 로드밸런서 리스너 룰 구성
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}


###### 대상그룹
resource "aws_lb_target_group" "asg" {
  name     = "aws14-terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}




###### 보안그룹 설정 - 인스턴스
resource "aws_security_group" "instance" {
  name = "aws14-terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###### 보안그룹 설정 - ALB
resource "aws_security_group" "alb" {
  name = "aws14-terraform-example-alb"

  # 모든 HTTP 트래픽 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Default VPC정보 가져오기
data "aws_vpc" "default" {
  default = true
}

# Subnet 정보 가져오기
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "template_file" "web_output" {
  template = file("${path.module}/web.sh")
  vars = {
    server_port = "${var.server_port}"
  }
}










