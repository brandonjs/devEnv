#!/opt/homebrew/bin/bash -
#===============================================================================
#
#          FILE: kill_bones_bootstrap.sh
# 
#         USAGE: ./kill_bones_bootstrap.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 08/21/2024 13:28:35
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

export PYTHONWARNINGS="ignore:Unverified HTTPS request"

templateName=$1
templateLocation="build/cdk.out/${templateName}"
region=$(echo $templateName | sed -e 's/\.template.json//g' -e 's/BONESBootstrap-[0-9]*-[0-9]*-//g')
AWS="aws --no-verify-ssl --region ${region}"
[[ ! -f ${templateLocation} ]] && echo "Need to be in CDK package to access template" && exit 1

for role in $(grep "RoleName" ${templateLocation} | sed -e 's/.*: "//g' -e 's/"//g'); do

  [[ $(${AWS} iam get-role --role-name ${role} 2>&1) =~ "NoSuchEntity" ]] && continue
  for policy in $($AWS iam list-role-policies --role-name ${role} | jq -r .PolicyNames[]); do
    ${AWS} iam delete-role-policy --role-name ${role} --policy-name ${policy}
  done

  for policy in $($AWS iam list-attached-role-policies --role-name ${role} | jq -r .AttachedPolicies[].PolicyArn); do
    ${AWS} iam detach-role-policy --role-name ${role} --policy-arn ${policy}
    ${AWS} iam delete-policy --policy-arn ${policy}
  done
  ${AWS} iam delete-role --role-name ${role}
done


for repo in $(grep "RepositoryName" ${templateLocation} | sed -e 's/.*: "//g' -e 's/"//g' -e 's/,$//g'); do
  ${AWS} ecr delete-repository --repository-name ${repo}
done

for bucket in $(grep '"BucketName"' ${templateLocation} | sed -e 's/.*: "//g' -e 's/"//g' -e 's/,$//g'); do
  ${AWS} s3api delete-objects \
  --bucket ${bucket} \
  --delete "$(${AWS} s3api list-object-versions \
  --bucket "${bucket}" \
  --output=json \
  --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
  ${AWS} s3api delete-bucket --bucket ${bucket}
done
