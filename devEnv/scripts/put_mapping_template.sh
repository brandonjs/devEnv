#!/bin/bash -
#===============================================================================
#
#          FILE: put_mapping_template.sh
#
#         USAGE: ./put_mapping_template.sh
#
#   DESCRIPTION: Gets the LoadBalancer Dns name for the Bastion, sets up an SSH tunnel
#                and performs an awscurl to put the mapping-template into the VPC
#                ES endpoint.
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 02/08/2022 08:59:36
#      REVISION: 1
#===============================================================================

set -o nounset                              # Treat unset variables as an error

[[ -z "$1" ]] && echo "ERROR: You must provide a region list in CSV format. ex: us-east-1,cn-north-1,us-gov-west-1" && exit 1
[[ -z "$2" ]] && echo "ERROR: You must provide a stage list in CSV format. ex: beta,gamma,prod" && exit 1
region_list=(${1//,/ })
stages=(${2//,/ })
for stage in ${stages[@]}; do
  for region in ${region_list[@]}; do
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    email=aws-varia+logs+${stage}+${region}@amazon.com
    AWS="aws --region ${region}"
    eval $(isengard credentials --region ${region} --role ReadOnly ${email} 2>/dev/null)
    if [ -z ${AWS_ACCESS_KEY_ID} ] && [ -z ${AWS_SECRET_ACCESS_KEY} ]; then
      continue
    fi
    elb=$(${AWS} elbv2 describe-load-balancers | jq -r '.LoadBalancers[] | select(.LoadBalancerArn|test("Chozo-Basti")) | .DNSName')
    esDomain=$(${AWS} opensearch list-domain-names | jq -r '.DomainNames[] | select(.DomainName|test("chozose")) | .DomainName')
    esEndpoint=$(${AWS} opensearch describe-domains --domain-names ${esDomain} | jq -r '.DomainStatusList[].Endpoints.vpc')

    eval $(isengard credentials --region ${region} --role Kibana ${email} 2>/dev/null)
    if [ -z ${AWS_ACCESS_KEY_ID} ] && [ -z ${AWS_SECRET_ACCESS_KEY} ]; then
      continue
    fi
    ssh -M -S my-ctrl-socket -fnNT -L 8443:${esEndpoint}:443 ${elb}
    ssh -S my-ctrl-socket -O check ${elb}
    awscurl -k --service es -H "host: ${esEndpoint}" https://localhost:8443/_index_template/chozo-template -X POST -H "Content-Type: application/json" --data "@configuration/json/index_mapping_template.json"
    ssh -S my-ctrl-socket -O exit ${elb}
  done
done
