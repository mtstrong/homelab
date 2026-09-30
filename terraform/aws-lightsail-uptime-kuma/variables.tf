variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "service_name" {
  description = "Name of the Lightsail container service"
  type        = string
  default     = "uptime-kuma"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "uptime_kuma_image" {
  description = "Docker image for Uptime Kuma"
  type        = string
  default     = "louislam/uptime-kuma:latest"
}

variable "container_power" {
  description = "Power of the container (nano, micro, small, medium, large, xlarge)"
  type        = string
  default     = "nano"

  validation {
    condition     = contains(["nano", "micro", "small", "medium", "large", "xlarge"], var.container_power)
    error_message = "Container power must be one of: nano, micro, small, medium, large, xlarge."
  }
}

variable "container_scale" {
  description = "Number of container instances to run (1-20)"
  type        = number
  default     = 1

  validation {
    condition     = var.container_scale >= 1 && var.container_scale <= 20
    error_message = "Container scale must be between 1 and 20."
  }
}

variable "domain_name" {
  description = "Custom domain name (optional). Leave empty to use default Lightsail domain"
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Subdomain for the service (optional). Used with domain_name"
  type        = string
  default     = ""
}
