output "vpc_id" {
  description = "ID of the platform VPC."
  value       = aws_vpc.platform.id
}

output "private_platform_subnet_ids" {
  description = "Private subnet IDs used by EKS workloads."
  value       = [for subnet in aws_subnet.private_platform : subnet.id]
}

output "data_subnet_ids" {
  description = "Isolated data-tier subnet IDs."
  value       = [for subnet in aws_subnet.data : subnet.id]
}

output "endpoint_subnet_ids" {
  description = "Subnet IDs hosting interface VPC endpoints."
  value       = [for subnet in aws_subnet.endpoints : subnet.id]
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.platform.name
}

output "eks_cluster_endpoint" {
  description = "Private Kubernetes API endpoint."
  value       = aws_eks_cluster.platform.endpoint
  sensitive   = true
}

output "eks_cluster_ca" {
  description = "Base64-encoded EKS cluster certificate authority data."
  value       = aws_eks_cluster.platform.certificate_authority[0].data
  sensitive   = true
}

output "vpc_endpoint_ids" {
  description = "Interface VPC endpoint IDs by service."
  value       = { for service, endpoint in aws_vpc_endpoint.interface : service => endpoint.id }
}
