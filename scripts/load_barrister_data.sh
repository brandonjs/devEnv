#!/bin/bash

NEW_REGIONS=$1
STAGE=$2

for region in "${NEW_REGIONS[@]}"
do
 export AWS_REGION=$region
 if [ $STAGE != "prod" ]
 then
  host_name="https://api.$region.$STAGE.barrister.aws.a2z.com/api/v1"
 else
  host_name="https://api.$region.barrister.aws.a2z.com/api/v1"
 fi
 echo "populating to $host_name"
 brazil-runtime-exec loader --host $host_name --load --update-if-exist --data-path configuration/data.json
 brazil-runtime-exec loader --host $host_name --load --update-if-exist --data-path configuration/managed_namespaces.json
 brazil-runtime-exec loader --host $host_name --load --update-if-exist --data-path configuration/isengard.json
 brazil-runtime-exec loader --host $host_name --load --update-if-exist --data-path configuration/amazonssh.json
 brazil-runtime-exec loader --host $host_name --load --update-if-exist --data-path configuration/canary_enrichments_test.json
 brazil-runtime-exec loader --host $host_name --load --update-if-exist --data-path configuration/aws_lambda_invoke.json --start-ns amazon.aws --alias-includes configuration/data.json
done
