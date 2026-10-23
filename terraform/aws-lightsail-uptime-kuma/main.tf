terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Lightsail Container Service for Uptime Kuma
resource "aws_lightsail_container_service" "uptime_kuma" {
  name  = var.service_name
  power = var.container_power
  scale = var.container_scale

  tags = {
    Name        = var.service_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Container Service Deployment
resource "aws_lightsail_container_service_deployment_version" "uptime_kuma" {
  container {
    container_name = "uptime-kuma"
    image          = var.uptime_kuma_image

    command = []

    environment = {
      UPTIME_KUMA_PORT = "3001"
    }

    ports = {
      "3001" = "HTTP"
    }
  }

  public_endpoint {
    container_name = "uptime-kuma"
    container_port = 3001

    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 3
      timeout_seconds     = 5
      interval_seconds    = 30
      path                = "/"
      success_codes       = "200-299"
    }
  }

  service_name = aws_lightsail_container_service.uptime_kuma.name
}

# Public Domain (optional - for custom domain)
resource "aws_lightsail_domain" "uptime_kuma" {
  count       = var.domain_name != "" ? 1 : 0
  domain_name = var.domain_name
}

# Domain Entry (optional - for custom domain)
resource "aws_lightsail_domain_entry" "uptime_kuma" {
  count       = var.domain_name != "" && var.subdomain != "" ? 1 : 0
  domain_name = aws_lightsail_domain.uptime_kuma[0].domain_name
  name        = var.subdomain
  type        = "A"
  target      = aws_lightsail_container_service.uptime_kuma.url

  depends_on = [
    aws_lightsail_container_service_deployment_version.uptime_kuma
  ]
}
