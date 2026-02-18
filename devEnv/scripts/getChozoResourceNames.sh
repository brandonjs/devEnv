#!/usr/local/bin/bash -
#===============================================================================
#
#          FILE: getChozoResourceNames.sh
# 
#         USAGE: ./getChozoResourceNames.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 10/22/2021 16:26:05
#      REVISION:  ---
#===============================================================================

[[ -z "$1" ]] && echo "ERROR: You must provide a csv region list" && exit 1
region_list=(${1//,/ })
for stage in beta gamma prod; do
  echo "${stage}"
  echo "====================================================================="
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
    cluster=$(${AWS} ecs list-clusters | jq -r .clusterArns[] | grep ChozoService | awk -F\/ '{print $NF}')
    service=$(${AWS} ecs list-services --cluster ${cluster}  | jq -r '.serviceArns[]' | grep -v Bastion | awk -F\/ '{print $NF}')
    esDomain=$(${AWS} opensearch list-domain-names | jq -r .DomainNames[].DomainName)
    firehose=$(${AWS} firehose list-delivery-streams | jq -r .DeliveryStreamNames[])
    kinesis=$(${AWS} kinesis list-streams | jq -r '.StreamNames[]')
    elb=$(${AWS} elbv2 describe-load-balancers | jq -r '.LoadBalancers[] | select(.LoadBalancerArn|test("Chozo-LoadB")) | .LoadBalancerArn | split(":") | .[-1]')
    elbTargetGroup=$(${AWS} elbv2 describe-target-groups | jq -r '.TargetGroups[] | select(.TargetGroupArn|test("Chozo-LoadB")) | .TargetGroupArn | split(":") | .[-1]')

    echo ${region}
    echo "====================================================================="
    echo "'${stage}': {"
    echo "  ecsServiceName: '${service}',"
    echo "  ecsClusterName: '${cluster}',"
    echo "  esDomainName: '${esDomain}',"
    echo "  firehoseStreamName: '${firehose}',"
    echo "  kinesisStreamName: '${kinesis}',"
    echo "  nlbName: '${elb}',"
    echo "  nlbTargetGroup: '${elbTargetGroup}'"
    echo "}"

    echo "====================================================================="
    echo ""
    echo ""
  done
done

