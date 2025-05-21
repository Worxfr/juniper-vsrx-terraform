# Juniper vSRX Deployment with Terraform

This Terraform project deploys Juniper vSRX instances in AWS with redundancy configuration in the Ireland (eu-west-1) region.

> [!WARNING]  
> ## ⚠️ Important Disclaimer
>
> **This project is for testing and demonstration purposes only.**
>
> Please be aware of the following:
>
> - The infrastructure deployed by this project is not intended for production use.
> - Security measures may not be comprehensive or up to date.
> - Performance and reliability have not been thoroughly tested at scale.
> - The project may not comply with all best practices or organizational standards.
>
> Before using any part of this project in a production environment:
>
> 1. Thoroughly review and understand all code and configurations.
> 2. Conduct a comprehensive security audit.
> 3. Test extensively in a safe, isolated environment.
> 4. Adapt and modify the code to meet your specific requirements and security standards.
> 5. Ensure compliance with your organization's policies and any relevant regulations.
>
> The maintainers of this project are not responsible for any issues that may arise from the use of this code in production environments.

## Architecture

```
                                   AWS Cloud (eu-west-1)
                                 +---------------------+
                                 |                     |
                      +----------+  Internet Gateway   +----------+
                      |          |                     |          |
                      |          +---------------------+          |
                      |                                           |
                      |                                           |
          +-----------v-----------+               +-----------v-----------+
          |                       |               |                       |
          |  vSRX Instance 1      |               |  vSRX Instance 2      |
          |  (Primary)            |               |  (Secondary)          |
          |                       |               |                       |
          |  +------------------+ |               |  +------------------+ |
          |  | Management IF    | |               |  | Management IF    | |
          |  | (Public Subnet)  | |               |  | (Public Subnet)  | |
          |  +------------------+ |               |  +------------------+ |
          |                       |               |                       |
          |  +------------------+ |     HA        |  +------------------+ |
          |  | Data IF          +<--------------->+  | Data IF          | |
          |  | (Private Subnet) | |    Sync       |  | (Private Subnet) | |
          |  +------------------+ |               |  +------------------+ |
          |                       |               |                       |
          +-----------+-----------+               +-----------+-----------+
                      |                                       |
                      |                                       |
                      v                                       v
          +-----------+-----------+               +-----------+-----------+
          |                       |               |                       |
          |  Protected Resources  |               |  Protected Resources  |
          |  (Private Subnet)     |               |  (Private Subnet)     |
          |                       |               |                       |
          +-----------------------+               +-----------------------+
```

## Features

- Deploys two Juniper vSRX instances for high availability
- Uses license-included AMI from AWS Marketplace
- Configures management and data interfaces
- Sets up basic security zones and policies
- Includes initial Junos configuration via user-data

## Prerequisites

1. AWS account with appropriate permissions
2. Terraform installed (version 0.12+)
3. AWS CLI configured with appropriate credentials
4. SSH key pair created in the AWS Ireland region

## Usage

1. Update the `variables.tf` file with your specific requirements:
   - Change the default SSH key name
   - Update the admin password
   - Modify instance type if needed

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Plan the deployment:
   ```
   terraform plan
   ```

4. Apply the configuration:
   ```
   terraform apply
   ```

5. Access your vSRX instances:
   - SSH: `ssh admin@<public-ip>`
   - Web UI (J-Web): `https://<public-ip>`

## Important Notes

- The default configuration includes basic security settings
- Remember to change the default admin password in the variables.tf file
- The vSRX instances are deployed with source/destination check disabled
- The AMI used is the license-included version from AWS Marketplace

## Cleanup

To remove all resources created by this Terraform configuration:

```
terraform destroy
```
