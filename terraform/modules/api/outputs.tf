output "api_base_url" {
  value = aws_api_gateway_deployment.notifications-api.invoke_url
}