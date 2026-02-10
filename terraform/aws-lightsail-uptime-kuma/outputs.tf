output "service_name" {
  description = "Name of the Lightsail container service"
  value       = aws_lightsail_container_service.uptime_kuma.name
}

output "service_arn" {
  description = "ARN of the Lightsail container service"
  value       = aws_lightsail_container_service.uptime_kuma.arn
}

output "service_url" {
  description = "Public URL of the Lightsail container service"
  value       = aws_lightsail_container_service.uptime_kuma.url
}

output "service_state" {
  description = "Current state of the service"
  value       = aws_lightsail_container_service.uptime_kuma.state
}

output "power" {
  description = "Power specification of the container"
  value       = aws_lightsail_container_service.uptime_kuma.power
}

output "scale" {
  description = "Number of container instances running"
  value       = aws_lightsail_container_service.uptime_kuma.scale
}

output "uptime_kuma_url" {
  description = "Full URL to access Uptime Kuma"
  value       = "https://${aws_lightsail_container_service.uptime_kuma.url}"
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.domain_name != "" && var.subdomain != "" ? "https://${var.subdomain}.${var.domain_name}" : "Not configured"
}

output "monthly_cost_estimate" {
  description = "Estimated monthly cost in USD"
  value = format("$%.2f", lookup({
    "nano"   = 7.00
    "micro"  = 10.00
    "small"  = 20.00
    "medium" = 40.00
    "large"  = 80.00
    "xlarge" = 160.00
  }, var.container_power, 0) * var.container_scale)
}
