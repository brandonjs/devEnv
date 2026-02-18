#!/bin/bash - 

vpc=$1
email=$2
region=$3
[[ -z ${region} ]] && region="us-east-1"
[[ -z ${vpc} ]] && echo "Must provide vpc id" && exit 1
[[ -z ${email} ]] && echo "Must provide account email" && exit 1

eval `isengard credentials --region ${region} --role Admin ${email}`
aws --region ${region} ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep InternetGatewayId
aws --region ${region} ec2 describe-subnets --filters 'Name=vpc-id,Values='$vpc | grep SubnetId
aws --region ${region} ec2 describe-route-tables --filters 'Name=vpc-id,Values='$vpc | grep RouteTableId
aws --region ${region} ec2 describe-network-acls --filters 'Name=vpc-id,Values='$vpc | grep NetworkAclId
aws --region ${region} ec2 describe-vpc-peering-connections --filters 'Name=requester-vpc-info.vpc-id,Values='$vpc | grep VpcPeeringConnectionId
aws --region ${region} ec2 describe-vpc-endpoints --filters 'Name=vpc-id,Values='$vpc | grep VpcEndpointId
aws --region ${region} ec2 describe-nat-gateways --filter 'Name=vpc-id,Values='$vpc | grep NatGatewayId
aws --region ${region} ec2 describe-security-groups --filters 'Name=vpc-id,Values='$vpc | grep GroupId
aws --region ${region} ec2 describe-instances --filters 'Name=vpc-id,Values='$vpc | grep InstanceId
aws --region ${region} ec2 describe-vpn-connections --filters 'Name=vpc-id,Values='$vpc | grep VpnConnectionId
aws --region ${region} ec2 describe-vpn-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep VpnGatewayId
aws --region ${region} ec2 describe-network-interfaces --filters 'Name=vpc-id,Values='$vpc | grep NetworkInterfaceId
