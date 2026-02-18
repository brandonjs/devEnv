#!/bin/bash

local_domain="http://localhost:8080"
api_domain="https://us-east-1.alpha.chozo.${DOMAIN_NAME}"
start_date=1621187329
end_date=1629136133

for method in automations commands; do
  out1=$(awscurl --region us-east-1 "${local_domain}/${method}/list/${DEV_ACCOUNT_ID}" -d '{"callerAccountId": "'${DEV_ACCOUNT_ID}'"}' | jq)
  out2=$(awscurl --region us-east-1 "${api_domain}/${method}/list/${DEV_ACCOUNT_ID}" | jq)
  [[ "${out1}" != "${out2}" ]] && echo "outputs don't match for list" && echo $(diff <( echo "$out1" ) <( echo "$out2" ))

  out1=$(awscurl -X POST --region us-east-1 "${local_domain}/${method}/list"  -d '{"callerAccountId": "'${DEV_ACCOUNT_ID}'"}'  | jq)
  out2=$(awscurl -X POST --region us-east-1 "${api_domain}/${method}/list" | jq)
  [[ "${out1}" != "${out2}" ]] && echo "outputs don't match for global list" && echo $(diff <( echo "$out1" ) <( echo "$out2" ))

  out1=$(awscurl --region us-east-1 "${local_domain}/${method}/metrics/${DEV_ACCOUNT_ID}"  -d '{"callerAccountId": "'${DEV_ACCOUNT_ID}'"}'  | jq)
  out2=$(awscurl --region us-east-1 "${api_domain}/${method}/metrics/${DEV_ACCOUNT_ID}" | jq)
  [[ "${out1}" != "${out2}" ]] && echo "outputs don't match for metrics" && echo $(diff <( echo "$out1" ) <( echo "$out2" ))

  out1=$(awscurl --region us-east-1 "${local_domain}/${method}/metrics" -d '{"callerAccountId": "'${DEV_ACCOUNT_ID}'"}'  | jq)
  out2=$(awscurl --region us-east-1 "${api_domain}/${method}/metrics" | jq)
  [[ "${out1}" != "${out2}" ]] && echo "outputs don't match for global metrics" && echo $(diff <( echo "$out1" ) <( echo "$out2" ))
done

out1=$(awscurl --region us-east-1 "${local_domain}/username/details/${USER}"  -d '{"callerAccountId": "'${DEV_ACCOUNT_ID}'"}' | jq)
out2=$(awscurl --region us-east-1 "${api_domain}/username/details/${USER}" | jq)
[[ "${out1}" != "${out2}" ]] && echo "outputs don't match for user" && echo $(diff <( echo "$out1" ) <( echo "$out2" ))

out1=$(awscurl --region us-east-1 "${local_domain}/username/details/${USER}?start=${start_date}&end=${end_date}"  -d '{"callerAccountId": "'${DEV_ACCOUNT_ID}'"}' | jq)
out2=$(awscurl --region us-east-1 "${api_domain}/username/details/${USER}?start=${start_date}&end=${end_date}" | jq)
[[ "${out1}" != "${out2}" ]] && echo "outputs don't match for user with dates" && echo $(diff <( echo "$out1" ) <( echo "$out2" ))

out1=$(awscurl --region us-east-1 "${local_domain}/instance/details/i-085ac3dca239a84a9" -d '{"callerAccountId": "'${DEV_ACCOUNT_ID}'"}' | jq)
out2=$(awscurl --region us-east-1 "${api_domain}/instance/details/i-085ac3dca239a84a9" | jq)
[[ "${out1}" != "${out2}" ]] && echo "outputs don't match for instanceId" && echo $(diff <( echo "$out1" ) <( echo "$out2" ))

out1=$(awscurl --region us-east-1 "${local_domain}/instance/details/i-085ac3dca239a84a9?start=${start_date}&end=${end_date}" -d '{"callerAccountId": "'${DEV_ACCOUNT_ID}'"}' | jq)
out2=$(awscurl --region us-east-1 "${api_domain}/instance/details/i-085ac3dca239a84a9?start=${start_date}&end=${end_date}" | jq)
[[ "${out1}" != "${out2}" ]] && echo "outputs don't match for instanceId with dates" && echo $(diff <( echo "$out1" ) <( echo "$out2" ))
