 #!/bin/bash

 set -e

 if  (( $# < 2))
 then
     echo Usage: halted_check.sh account_id PROFILE IAM_USER_NAME
     exit 1
 fi

 PROFILE=$1
 IAM_USER_NAME=$2

 source <(grep = <(grep -A5 '\[*$PROFILE\]' ~/.aws/config| sed -e 's/ = /=/g'))

 ISENGARD_STATE=$(curl -b ~/.midway/cookie -c ~/.midway/cookie -L -X POST --header "X-Amz-Target: IsengardService.GetIAMUser" --header "Content-Encoding: amz-1.0" --header "Content-Type: application/json; charset=UTF-8" -d '{"AWSAccountID": "'$account_id'", "IAMUserName":"'$IAM_USER_NAME'"}' https://isengard-service.amazon.com)
 echo "Isengard State"
 ISENGARD_LAST_ROTATION_ATTEMPT=$(echo "$ISENGARD_STATE" | jq 'select(.IAMUser.LastStateDate != null) | .IAMUser.LastStateDate')
 [[ ! -z "$ISENGARD_LAST_ROTATION_ATTEMPT" ]] && echo "Isengard Last Attempted A Rotation On: $(date -d @$ISENGARD_LAST_ROTATION_ATTEMPT +"%Y-%m-%dT%H:%M:%SZ")"
 ISENGARD_AKID_NEW=$(echo "$ISENGARD_STATE" | jq -r 'select(.IAMUser.AkidNew != null) | .IAMUser.AkidNew')
 [[ ! -z "$ISENGARD_AKID_NEW" ]] && echo "AKID New: $ISENGARD_AKID_NEW"
 ISENGARD_AKID_OLD=$(echo "$ISENGARD_STATE" | jq -r 'select(.IAMUser.AkidOld != null) | .IAMUser.AkidOld')
 [[ ! -z "$ISENGARD_AKID_OLD" ]] && echo "AKID Old: $ISENGARD_AKID_OLD"
 ISENGARD_ODIN_NEW=$(echo "$ISENGARD_STATE" | jq 'select(.IAMUser.OdinSerialNew != null) | .IAMUser.OdinSerialNew')
 [[ ! -z "$ISENGARD_ODIN_NEW" ]] && echo "Odin Serial New: $ISENGARD_ODIN_NEW"
 ISENGARD_ODIN_OLD=$(echo "$ISENGARD_STATE" | jq 'select(.IAMUser.OdinSerialOld != null) | .IAMUser.OdinSerialOld')
 [[ ! -z "$ISENGARD_ODIN_OLD" ]] && echo "Odin Serial Old: $ISENGARD_ODIN_OLD"
 echo

 IAM_STATE=$(aws --profile $PROFILE iam list-access-keys --user-name $2)
 echo "IAM State"
 IAM_AKID_NEW=$(echo "$IAM_STATE" | jq -r 'select(.AccessKeyMetadata[0] != null) | .AccessKeyMetadata[0]')
 IAM_AKID_OLD=$(echo "$IAM_STATE" | jq -r 'select(.AccessKeyMetadata[1] != null) | .AccessKeyMetadata[1]')
 # Ensure ordered by create date
 if [[ ! -z "$IAM_AKID_OLD" && ! -z "$IAM_AKID_NEW" ]]; then
     if [[ $(echo "$IAM_AKID_OLD" | jq -r '.CreateDate') > $(echo "$IAM_AKID_NEW" | jq -r '.CreateDate') ]]; then
         temp=$IAM_AKID_NEW
         IAM_AKID_NEW=$IAM_AKID_OLD
         IAM_AKID_OLD=$temp
     fi
 fi

 if [[ ! -z "$IAM_AKID_NEW" ]]; then
     AKLU=$(aws --profile $PROFILE iam get-access-key-last-used --access-key-id "$(echo "$IAM_AKID_NEW" | jq -r '.AccessKeyId')" | jq -r '.AccessKeyLastUsed')
     echo -n "AKID New: "
     echo "$IAM_AKID_NEW" | jq --arg AKLU "$AKLU" '. + {AKLU: $AKLU | fromjson}'
 fi
 if [[ ! -z "$IAM_AKID_OLD" ]]; then
     AKLU=$(aws --profile $PROFILE iam get-access-key-last-used --access-key-id "$(echo "$IAM_AKID_OLD" | jq -r '.AccessKeyId')" | jq -r '.AccessKeyLastUsed')
     echo -n "AKID Old: "
     AKID_OLD_LAST_USED=$(echo "$AKLU" | jq -r '.LastUsedDate')
     echo "$IAM_AKID_OLD" | jq --arg AKLU "$AKLU" '. + {AKLU: $AKLU | fromjson}'
 fi
 echo

 ODIN_MS=$(echo "$ISENGARD_STATE" | jq -r '.IAMUser.OdinMaterialSet')
 ODIN_SERIAL_STATE=$(odin adminAPI --ListMat -n $ODIN_MS | sed -nr 's/([0-9]+).*Principal.*\(active\)/\1/p')
 echo "Odin Active Serials"
 echo "$ODIN_SERIAL_STATE"
 echo

 echo "Odin Active AKIDs"
 ODIN_MATERIALS=""
 while read -r serial; do
     echo -n "Odin Serial $serial: "
     AKID=$(odin-get -t Principal -s $serial $ODIN_MS)
     echo "$AKID"
     ODIN_MATERIALS="$ODIN_MATERIALS""$AKID"$'\n'
 done <<< "$ODIN_SERIAL_STATE"
 echo

 echo "Checking Consistency"
 if [[ ! -z "$IAM_AKID_NEW" ]]; then
     [[ -z "$ISENGARD_AKID_NEW" ]] && echo "Isengard and IAM mismatch for new AKID."
 fi
 if [[ ! -z "$IAM_AKID_OLD" ]]; then
     [[ -z "$ISENGARD_AKID_OLD" ]] && echo "Isengard and IAM mismatch for new AKID."
 fi
 if [[ ! -z "$ISENGARD_ODIN_NEW" ]]; then
     echo "$ODIN_SERIAL_STATE" | grep -q "$ISENGARD_ODIN_NEW" || echo "Isengard and Odin Mismatch for new Odin serial."
 fi
 if [[ ! -z "$ISENGARD_ODIN_OLD" ]]; then
     echo "$ODIN_SERIAL_STATE" | grep -q "$ISENGARD_ODIN_OLD" || echo "Isengard and Odin Mismatch for old Odin serial."
 fi
 if [[ ! -z "$ISENGARD_AKID_NEW" ]]; then
     echo "$ODIN_MATERIALS" | grep -q "$ISENGARD_AKID_NEW" || echo "IAM and Odin do not match for its new AKID."
 fi
 if [[ ! -z "$ISENGARD_AKID_OLD" ]]; then
     echo "$ODIN_MATERIALS" | grep -q "$ISENGARD_AKID_OLD" || echo "IAM and Odin do not match for its old AKID."
 fi
 if [[ ! -z "$AKID_OLD_LAST_USED" ]]; then
     if [[ "$AKID_OLD_LAST_USED" > "$(date -d @$((ISENGARD_LAST_ROTATION_ATTEMPT-14400)) +"%Y-%m-%dT%H:%M:%SZ")" ]]; then
         echo "The Old Access Key Was Being Used When Isengard Attempted Rotation."
     fi
 fi
