# terraform-aws-101
Terraform with AWS

This Terraform file provisions an EC2 instance on AWS, installs apache2 and clones a static website hosted on GitHub

ACCESS_KEY & SECRET_KEY are being kep on a separate file <i>terraform.tfvars</i>

## TF -> AWS
![screenshot](/github/TF-AWS.png)
- VPC  
- SUBNET  
- INTERNET GATEWAY  
- ROUTE TABLE  
- SECURITY GROUP  
  - 443 HTTPS  
  - 80  HTTP  
  - 22  SSH  
- NETWORK INTERFACE  
- ELASTIC IP  
- EC2  
  - Ubuntu Server 20  
  - t2.micro
