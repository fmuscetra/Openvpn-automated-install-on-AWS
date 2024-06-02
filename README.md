# Openvpn-AUTOINSTALL
Install Openvpn on selected AWS regions

This Terraform template creates the infrastructure to setup and run Open VPN

It works on AWS and prepares the infrastructure for a script to install openvpn and all related modules. The scope is to setup in few minutes, fully automated, all required modules. The installation script will be executed headless, e.g. without waiting for the user input, in an automated manner. If you want to customize the installation, please read the faq from the author of the script at: https://github.com/angristan/openvpn-install#faq

Please note also that you have to replace your public key in the tfvars files and replace the email address with your email address in the main.tf section "Create SNS topic subscription"

I created few tfvars files in relation to the AWS regions that I use but you can create other tfvars files using these ones as templates. 

## Prerequisites

- [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- Store your AWS credentials as environment variables:
  - ``export AWS_ACCESS_KEY_ID= your ID``
  - ``export AWS_SECRET_ACCESS_KEY= your key``
- Assign your public key to the public_key variable in .tfvars files
- Replace the private_key in main.tf with the path of your private key

## Create the infrastructure

You can use a specific tfvars file to create the infrastructure in the specific region

This example creates the infrastructure in the eu-south-1 region:

``terraform apply -var-file="milan.tfvars"``

## Credits

This repository relies on openvpn-install.sh Bash script available in https://github.com/angristan/openvpn-install and developed by @angristan
