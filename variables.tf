variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for redundancy"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "instance_type" {
  description = "EC2 instance type for vSRX"
  default     = "c5.xlarge"  # Recommended for vSRX
}

variable "key_name" {
  description = "SSH key pair name"
  default     = "vsrx-key"
}

# Admin password variable removed - using SSH key authentication only
