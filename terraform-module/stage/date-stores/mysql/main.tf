terraform {
  required_version = ">= 1.0.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "aws14-terraform-state"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-2"

    dynamodb_table = "aws14-stage-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# RDS에 데이터베이스를 생성한다
resource "aws_db_instance" "example" {
  identifier_prefix   = "aws14-stage-terraform-example"
  engine              = "mysql"
  allocated_storage   = 10            #스토리지는 10GB
  instance_class      = "db.t2.micro" #vCPU 1개, 1GB 메모리
  skip_final_snapshot = true

  name     = var.db_name
  username = var.db_username
  password = var.db_password
}
