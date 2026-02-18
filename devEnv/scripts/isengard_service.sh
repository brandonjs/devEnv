#!/bin/bash - 
#===============================================================================
#
#          FILE: isengard_service.sh
# 
#         USAGE: ./isengard_service.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 10/06/2021 12:08:56
#      REVISION:  ---
#===============================================================================


model=IsengardService
endpoint=isengard-service.amazon.com
service=IsengardService
region=us-east-1

##################################
# sig v4 generation
##################################
 
function createCanonicalRequest()
{
    local headers="content-type:application/x-www-form-urlencoded; charset=utf-8\nhost:$endpoint\nx-amz-date:$1"
    local signed_headers="content-type;host;x-amz-date"
    
    local hashed_payload=$(printf "$2" | shasum -a 256)
    local hashed_payload="${hashed_payload%% *}"
    
    local canonical_request="POST\n/\n\n$headers\n\n$signed_headers\n$hashed_payload"
    local hashed_canonical_request=$(printf "$canonical_request" | shasum -a 256)
    local hashed_canonical_request="${hashed_canonical_request%% *}"
    echo "$hashed_canonical_request"
}

# function to generate a SigV4 signature and 
# adapted from http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
# and https://github.com/bblocks/aws-api-v4/blob/master/post-simple.bash
function generateAWSV4Signature() {
  kSecret=$(printf "AWS4$1" | xxd -p -c 256)
  kDate=$(printf "$2" | openssl dgst -binary -sha256 -mac HMAC -macopt hexkey:$kSecret | xxd -p -c 256)
  kRegion=$(printf "$3" | openssl dgst -binary -sha256 -mac HMAC -macopt hexkey:$kDate | xxd -p -c 256)
  kService=$(printf "IsengardService" | openssl dgst -binary -sha256 -mac HMAC -macopt hexkey:$kRegion | xxd -p -c 256)
  kSigning=$(printf "aws4_request" | openssl dgst -binary -sha256 -mac HMAC -macopt hexkey:$kService | xxd -p -c 256)
  echo $(printf "$4" | openssl dgst -binary -hex -sha256 -mac HMAC -macopt hexkey:$kSigning | sed 's/^.* //')
}

##################################
# talk to Isengard service
##################################
function CallIsengard()
{
  local payload="$1"
  x_amz_date_long=$(date -u "+%Y%m%dT%H%M%SZ")
  x_amz_date_short="${x_amz_date_long/T*}"
  
  request="$(createCanonicalRequest $x_amz_date_long $payload)"
  string_to_sign="AWS4-HMAC-SHA256\n$x_amz_date_long\n$x_amz_date_short/$region/$service/aws4_request"
  signature=$(generateAWSV4Signature "$skid" "$x_amz_date_short" "$region" "$string_to_sign")

   read -r -d '' curl_params<<END
url = "https://$endpoint"
-H "Content-Type: application/x-www-form-urlencoded; charset=utf-8"
-H "X-Amz-Date: $x_amz_date_long"
-H "Host: $endpoint"
-H "Authorization: AWS4-HMAC-SHA256 Credential=$akid/$x_amz_date_short/$region/$service/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=$signature"
-d "$payload"
END

curl -v -K - < <(printf "$curl_params")
}

function Hello()
{
  local payload=$(cat <<-EOF
	{
	}
	EOF
  )
  activity=GetAWSAccount
  CallIsengard "$payload"
  return $?
}

$(Hello)
