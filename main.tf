terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  
  backend "s3" {}
}

provider "aws" {
  region = "eu-west-1"  # Ireland region
}

# Create VPC
resource "aws_vpc" "vsrx_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vSRX-VPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vsrx_vpc.id

  tags = {
    Name = "vSRX-IGW"
  }
}

# Create subnets for management interfaces
resource "aws_subnet" "mgmt_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.vsrx_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "vSRX-Mgmt-Subnet-${count.index + 1}"
  }
}

# Create subnets for data interfaces
resource "aws_subnet" "data_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.vsrx_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "vSRX-Data-Subnet-${count.index + 1}"
  }
}

# Create route tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vsrx_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "vSRX-Public-RT"
  }
}

# Associate route tables with management subnets
resource "aws_route_table_association" "mgmt_rta" {
  count          = 2
  subnet_id      = aws_subnet.mgmt_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Security group for vSRX instances
resource "aws_security_group" "vsrx_sg" {
  name        = "vsrx-security-group"
  description = "Security group for Juniper vSRX instances"
  vpc_id      = aws_vpc.vsrx_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTPS/J-Web access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS/J-Web access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vSRX-SG"
  }
}

# Network interfaces for vSRX instances
resource "aws_network_interface" "vsrx_mgmt_eni" {
  count             = 2
  subnet_id         = aws_subnet.mgmt_subnet[count.index].id
  security_groups   = [aws_security_group.vsrx_sg.id]
  source_dest_check = false

  tags = {
    Name = "vSRX-Mgmt-ENI-${count.index + 1}"
  }
}

resource "aws_network_interface" "vsrx_data_eni" {
  count             = 2
  subnet_id         = aws_subnet.data_subnet[count.index].id
  security_groups   = [aws_security_group.vsrx_sg.id]
  source_dest_check = false

  tags = {
    Name = "vSRX-Data-ENI-${count.index + 1}"
  }
}

# Elastic IPs for management interfaces
resource "aws_eip" "vsrx_mgmt_eip" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "vSRX-Mgmt-EIP-${count.index + 1}"
  }
}

# Associate EIPs with management interfaces
resource "aws_eip_association" "vsrx_eip_assoc" {
  count                = 2
  network_interface_id = aws_network_interface.vsrx_mgmt_eni[count.index].id
  allocation_id        = aws_eip.vsrx_mgmt_eip[count.index].id
}

# Data source for Juniper vSRX AMI - commented out and using hardcoded AMI instead
# data "aws_ami" "vsrx_ami" {
#   most_recent = true
#   owners      = ["aws-marketplace"]
#
#   filter {
#     name   = "name"
#     values = ["*vSRX-BYOL*"]
#   }
#
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# vSRX user-data configuration for primary instance
locals {
  vsrx_primary_config = <<-EOF
    #junos-config
    system {
        host-name vsrx-primary;
        root-authentication {
            # Authentication handled by AWS key pair
        }
        login {
            user admin {
                uid 2000;
                class super-user;
                authentication {
                    # Authentication handled by AWS key pair
                }
            }
        }
        services {
            ssh;
            web-management {
                http {
                    interface fxp0.0;
                }
                https {
                    system-generated-certificate;
                    interface fxp0.0;
                }
            }
        }
    }
    security {
        zones {
            security-zone trust {
                interfaces {
                    ge-0/0/0.0 {
                        host-inbound-traffic {
                            system-services {
                                ping;
                            }
                        }
                    }
                }
            }
            security-zone untrust {
                interfaces {
                    ge-0/0/1.0 {
                        host-inbound-traffic {
                            system-services {
                                ping;
                            }
                        }
                    }
                }
            }
        }
        policies {
            from-zone trust to-zone untrust {
                policy allow-outbound {
                    match {
                        source-address any;
                        destination-address any;
                        application any;
                    }
                    then {
                        permit;
                    }
                }
            }
        }
    }
    interfaces {
        fxp0 {
            unit 0 {
                family inet {
                    dhcp;
                }
            }
        }
        ge-0/0/0 {
            unit 0 {
                family inet {
                    dhcp;
                }
            }
        }
        ge-0/0/1 {
            unit 0 {
                family inet {
                    dhcp;
                }
            }
        }
    }
    routing-options {
        static {
            route 0.0.0.0/0 next-hop fxp0.0;
        }
    }
    EOF

  vsrx_secondary_config = <<-EOF
    #junos-config
    system {
        host-name vsrx-secondary;
        root-authentication {
            # Authentication handled by AWS key pair
        }
        login {
            user admin {
                uid 2000;
                class super-user;
                authentication {
                    # Authentication handled by AWS key pair
                }
            }
        }
        services {
            ssh;
            web-management {
                http {
                    interface fxp0.0;
                }
                https {
                    system-generated-certificate;
                    interface fxp0.0;
                }
            }
        }
    }
    security {
        zones {
            security-zone trust {
                interfaces {
                    ge-0/0/0.0 {
                        host-inbound-traffic {
                            system-services {
                                ping;
                            }
                        }
                    }
                }
            }
            security-zone untrust {
                interfaces {
                    ge-0/0/1.0 {
                        host-inbound-traffic {
                            system-services {
                                ping;
                            }
                        }
                    }
                }
            }
        }
        policies {
            from-zone trust to-zone untrust {
                policy allow-outbound {
                    match {
                        source-address any;
                        destination-address any;
                        application any;
                    }
                    then {
                        permit;
                    }
                }
            }
        }
    }
    interfaces {
        fxp0 {
            unit 0 {
                family inet {
                    dhcp;
                }
            }
        }
        ge-0/0/0 {
            unit 0 {
                family inet {
                    dhcp;
                }
            }
        }
        ge-0/0/1 {
            unit 0 {
                family inet {
                    dhcp;
                }
            }
        }
    }
    routing-options {
        static {
            route 0.0.0.0/0 next-hop fxp0.0;
        }
    }
    EOF
}

# vSRX instances for redundancy
resource "aws_instance" "vsrx_instance" {
  count         = 2
  ami           = "ami-02c031e72355287f2"  # Using Juniper vSRX AMI (23.4R2.13-appsec)
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = count.index == 0 ? local.vsrx_primary_config : local.vsrx_secondary_config

  network_interface {
    network_interface_id = aws_network_interface.vsrx_mgmt_eni[count.index].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.vsrx_data_eni[count.index].id
    device_index         = 1
  }

  tags = {
    Name = count.index == 0 ? "vSRX-Primary" : "vSRX-Secondary"
  }

  # Juniper vSRX requires at least 2 vCPUs and 4GB RAM
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}

# Output the public IPs of the vSRX instances
# Outputs are defined in outputs.tf
