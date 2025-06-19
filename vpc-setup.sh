#!/bin/bash

# --- VPC SETUP ---

# 1. Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --query 'Vpc.VpcId' --output text)
echo "✅ VPC created: $VPC_ID"

# 2. Create subnet
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ap-south-1a \
  --query 'Subnet.SubnetId' --output text)
echo "✅ Subnet created: $SUBNET_ID"

# 3. Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' --output text)
echo "✅ Internet Gateway created: $IGW_ID"

# Attach IGW to VPC
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "✅ IGW attached to VPC"

# 4. Create Route Table
RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' --output text)
echo "✅ Route Table created: $RT_ID"

# Add route to IGW
aws ec2 create-route --route-table-id $RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
echo "✅ Route added to IGW"

# Associate subnet with route table
aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $RT_ID

# 5. Modify subnet to enable public IPs
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_ID --map-public-ip-on-launch
echo "✅ Subnet set to auto-assign public IP"

# --- EC2 SETUP ---

# 6. Create a security group
SG_ID=$(aws ec2 create-security-group --group-name DevSG --description "Allow SSH + HTTP" --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
echo "✅ Security Group created: $SG_ID"

# Allow SSH + HTTP
aws ec2 authorize-security-group-ingress --group-id $SG_ID \
  --protocol tcp --port 22 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress --group-id $SG_ID \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

# 7. Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0c1a7f89451184c8b \  # Amazon Linux 2 in ap-south-1
  --instance-type t2.micro \
  --subnet-id $SUBNET_ID \
  --security-group-ids $SG_ID \
  --associate-public-ip-address \
  --key-name your-key-pair-name \
  --query 'Instances[0].InstanceId' --output text)

echo "🚀 EC2 instance launched: $INSTANCE_ID"

