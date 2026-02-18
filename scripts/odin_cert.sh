#!/bin/bash 

material_name=$1;

curl -s "http://localhost:2009/query?Operation=retrieve&ContentType=JSON&material.materialName=$material_name&material.materialType=Certificate" \
    | tr '{},' '\n\n\n' \
    | sed -n 's/"materialData":"\(.*\)"/\1/p' \
    | base64 -di \
    | openssl x509 -inform DER > $material_name.crt

cert_name=`openssl x509 -in $material_name.crt -text| grep Subject: | awk -F= '{print $NF}'`

mv $material_name.crt $cert_name.crt

curl -s "http://localhost:2009/query?Operation=retrieve&ContentType=JSON&material.materialName=$material_name&material.materialType=PrivateKey" \
    | tr '{},' '\n\n\n' \
    | sed -n 's/"materialData":"\(.*\)"/\1/p' \
    | base64 -di \
    | openssl pkcs8 -nocrypt -inform DER -outform PEM > $cert_name.key

