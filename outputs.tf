output "vsrx_public_ips" {
  description = "Public IP addresses of the vSRX instances"
  value       = aws_eip.vsrx_mgmt_eip[*].public_ip
}

output "vsrx_primary_instance_id" {
  description = "Instance ID of the primary vSRX"
  value       = aws_instance.vsrx_instance[0].id
}

output "vsrx_secondary_instance_id" {
  description = "Instance ID of the secondary vSRX"
  value       = aws_instance.vsrx_instance[1].id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vsrx_vpc.id
}

output "management_subnet_ids" {
  description = "IDs of the management subnets"
  value       = aws_subnet.mgmt_subnet[*].id
}

output "data_subnet_ids" {
  description = "IDs of the data subnets"
  value       = aws_subnet.data_subnet[*].id
}
