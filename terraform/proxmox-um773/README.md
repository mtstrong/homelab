# Proxmox Multi-Host Ubuntu VM Setup

This project provides Terraform configurations for setting up Ubuntu virtual machines across multiple Proxmox hosts. It is designed to streamline the deployment process and ensure consistency across different nodes.

## Project Structure

- **hosts/**: Contains individual Terraform configuration files for each Proxmox node.
  - **proxmox-node1.tf**: Configuration for Ubuntu VM on Proxmox Node 1.
  - **proxmox-node2.tf**: Configuration for Ubuntu VM on Proxmox Node 2.
  - **proxmox-node3.tf**: Configuration for Ubuntu VM on Proxmox Node 3.
  
- **variables.tf**: Defines variables used across the Terraform configurations, such as VM name and resource allocations.

- **provider.tf**: Specifies the Proxmox provider configuration, including API URL and user credentials.

- **outputs.tf**: Defines outputs of the Terraform configuration, such as VM IDs and IP addresses.

- **main.tf**: Main entry point for the Terraform configuration, orchestrating the creation of VMs across the specified Proxmox hosts.

## Prerequisites

- Terraform installed on your local machine.
- Access to a Proxmox environment with the necessary permissions to create virtual machines.
- The Proxmox API must be accessible from your machine.

## Setup Instructions

1. Clone this repository to your local machine.
2. Navigate to the project directory:
   ```
   cd proxmox-multi-host-ubuntu
   ```
3. Update the `provider.tf` file with your Proxmox API URL and credentials.
4. Modify the `variables.tf` file to set your desired VM configurations.
5. Initialize Terraform:
   ```
   terraform init
   ```
6. Plan the deployment to see the resources that will be created:
   ```
   terraform plan
   ```
7. Apply the configuration to create the virtual machines:
   ```
   terraform apply
   ```

## Usage Guidelines

- Ensure that the configurations in the `hosts/` directory are tailored to your specific requirements for each Proxmox node.
- Review the outputs after deployment to obtain important information about the created VMs.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.