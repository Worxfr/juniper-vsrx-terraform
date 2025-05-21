# Juniper vSRX Deployment with Terraform

This Terraform project deploys Juniper vSRX instances in AWS with redundancy configuration in the Ireland (eu-west-1) region.

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
