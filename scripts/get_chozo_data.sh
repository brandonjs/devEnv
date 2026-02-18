#!/usr/local/bin/bash -
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

PARENT_REGION='us-east-1'
AWS="aws" 
BACKFILL="false"

function getIsengardCreds () {
  email=aws-varia+logs+${1}+global@amazon.com
  eval $(isengard credentials --region ${2} --role Admin ${email} 2>/dev/null)
}

function getLocalIsengardCreds () {
  email=aws-varia+logs+${1}+${2}@amazon.com
  eval $(isengard credentials --region ${2} --role Admin ${email} 2>/dev/null)
}

[[ -z "${1-}" ]] && echo "ERROR: You must provide a region list in CSV format. ex: us-east-1,cn-north-1,us-gov-west-1" && exit 1
[[ -z "${2-}" ]] && echo "ERROR: You must provide a stage list in CSV format. ex: beta,gamma,prod" && exit 1
[[ -n "${3-}" ]] && BACKFILL="true"

region_list=(${1//,/ })
stages=(${2//,/ })
for stage in ${stages[@]}; do
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN

  getIsengardCreds ${stage} ${PARENT_REGION}
  if [  "x${AWS_ACCESS_KEY_ID-}" == "x" ] && [ "x${AWS_SECRET_ACCESS_KEY-}" == "x" ]; then
    continue
  fi
  for region in ${region_list[@]}; do
    endpoint=$(script -q /dev/null cloud-desktop exec ripcli rip -r ${region} -s varia/logs -a endpoint)
    endpoint=${endpoint//$'\r'/}

    stat=$(script -q /dev/null cloud-desktop exec ripcli rip -r ${region} -s varia/logs -a status)
    stat=${stat//$'\r'/}

    [[ ${stat} != "GA" && ${stat} != "IA" ]] && continue

    noGlobalCreds=$(script -q /dev/null cloud-desktop exec ripcli rip -r ${region} -a accessibility_attributes | grep NO_GLOBAL)
    noGlobalCreds=${noGlobalCreds//$'\r'/}


    if [[ "${stage}" != "prod" ]]; then
      match="chozo"
      endpoint=${endpoint%%${match}*}${stage}.${match}${endpoint##*${match}}
    fi
    [[ -z ${endpoint} ]] && continue
    for c in automations commands; do
      log_group_name="chozo-api-metrics-${region}-${c}"
      existing=$(${AWS[@]} logs describe-log-groups --log-group-name ${log_group_name} | jq -r '.logGroups[].logGroupName')
      if [[ "x${existing}" == "x" ]]; then
        echo "Creating log group: ${log_group_name}"
        ${AWS[@]} --region ${PARENT_REGION} logs create-log-group --log-group-name ${log_group_name}
        if [[ ${c} == "automations" ]]; then
          nameSpace="Varia Automation Executions"
          filterName="Varia"
          ${AWS[@]} --region ${PARENT_REGION} logs put-metric-filter --log-group-name ${log_group_name} --filter-name "Varia Total Barrister Calls" --filter-pattern "{$.metrics.totalBarristerCalls = *}" --metric-transformations metricName="Total Barrister Calls - ${region}",metricNamespace="${nameSpace}",metricValue="$.metrics.totalBarristerCalls",defaultValue=0,unit="Count"
        else
          nameSpace="Mechanic Command Executions"
          filterName="Mechanic"
        fi
        for metric in Executions Failed Success; do
          ${AWS[@]} --region ${PARENT_REGION} logs put-metric-filter --log-group-name ${log_group_name} --filter-name "${filterName} Total ${metric}" --filter-pattern "{$.metrics.total${metric} = *}" --metric-transformations metricName="Total ${metric} - ${region}",metricNamespace="${nameSpace}",metricValue="$.metrics.total${metric}",defaultValue=0,unit="Count"
        done
      fi

      global_log_group_name="chozo-api-metrics-${c}"
      global_log_stream_name=${region}
      existing=$(${AWS[@]} logs describe-log-groups --log-group-name ${global_log_group_name} | jq -r '.logGroups[].logGroupName')
      if [[ "x${existing}" == "x" ]]; then
        echo "Creating log group: ${global_log_group_name}"
        ${AWS[@]} --region ${PARENT_REGION} logs create-log-group --log-group-name ${global_log_group_name}
      fi

      sequence="0"
      if [[ ${BACKFILL} == "true" ]]; then
        sequence=$(seq 15 -1 0)
        ${AWS[@]} --region ${PARENT_REGION} logs describe-log-streams --log-group-name ${log_group_name} | jq -r .logStreams[].logStreamName | while read x; 
          do ${AWS[@]} --region ${PARENT_REGION} logs delete-log-stream --log-group-name ${log_group_name} --log-stream-name ${x}
        done

        ${AWS[@]} --region ${PARENT_REGION} logs delete-log-stream --log-group-name ${global_log_group_name} --log-stream-name ${global_log_stream_name}
        ${AWS[@]} --region ${PARENT_REGION} logs create-log-stream --log-group-name ${global_log_group_name} --log-stream-name ${global_log_stream_name}
        declare ${c}_token=""
      else
        declare ${c}_token=$(${AWS[@]} --region ${PARENT_REGION} logs describe-log-streams --log-group-name ${global_log_group_name} --log-stream-name ${global_log_stream_name} | jq -r '.logStreams[].uploadSequenceToken')
      fi

      for d in ${sequence}; do
        log_stream_name=$(uuidgen | awk '{print tolower($0)}')
        ${AWS[@]} --region ${PARENT_REGION} logs create-log-stream --log-group-name ${log_group_name} --log-stream-name ${log_stream_name}
        let "d2=d+1"
        startDate=$(date -u -v -${d2}d -v0H -v0M -v0S +%s)
        endDate=$(date -u -v -${d}d -v0H -v0M -v0S +%s)
        dateInMs="$(date +%s)000"

        AWS_ACCESS_KEY_ID_PARENT=${AWS_ACCESS_KEY_ID}
        AWS_SECRET_ACCESS_KEY_PARENT=${AWS_SECRET_ACCESS_KEY}
        AWS_SESSION_TOKEN_PARENT=${AWS_SESSION_TOKEN}
        if [[ ${noGlobalCreds} != "" ]]; then
          getLocalIsengardCreds ${stage} ${region}
        else
          getIsengardCreds ${stage} ${region}
        fi

        data=$(awscurl --region ${region} "https://${endpoint}/${c}/metrics?start=$startDate&end=$endDate&documentsByAccount=true")
        [[ -z "${data}" ]] && continue
        dataStr=$(echo ${data} | jq -c '. | tojson')
        token=${c}_token

        AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID_PARENT}
        AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY_PARENT}
        AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN_PARENT}

        if ! ${AWS} --region ${region} sts get-caller-identity > /dev/null 2>&1; then
          getIsengardCreds ${stage} ${PARENT_REGION}
        fi
        output=$(${AWS[@]} --region ${PARENT_REGION} logs put-log-events --log-group-name ${log_group_name} --log-stream-name ${log_stream_name} --log-events timestamp=${dateInMs},message="${dataStr}")

        if [[ ${!token} != "" && ${!token} != "null" ]]; then
          output=$(${AWS[@]} --region ${PARENT_REGION} logs put-log-events --sequence-token ${!token} --log-group-name ${global_log_group_name} --log-stream-name ${global_log_stream_name} --log-events timestamp=${dateInMs},message="${dataStr}")
        else
          output=$(${AWS[@]} --region ${PARENT_REGION} logs put-log-events --log-group-name ${global_log_group_name} --log-stream-name ${global_log_stream_name} --log-events timestamp=${dateInMs},message="${dataStr}")
        fi
        declare ${c}_token=$(jq -r '.nextSequenceToken' <<< ${output})
      done
    done
  done
done
