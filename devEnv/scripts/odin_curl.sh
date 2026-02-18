#!/bin/bash

[ -z $1 ] && echo "Need to specify material name" && exit
materialName=$1

curl -s "http://localhost:2009/query?Operation=retrieve&ContentType=JSON&material.materialName=$materialName&material.materialType=Principal" \
   | tr '{},' '\n\n\n' \
   | sed -n 's/"materialData":"\(.*\)"/\1/p' \
   | base64 -di; echo

curl -s "http://localhost:2009/query?Operation=retrieve&ContentType=JSON&material.materialName=$materialName&material.materialType=Credential" \
   | tr '{},' '\n\n\n' \
   | sed -n 's/"materialData":"\(.*\)"/\1/p' \
   | base64 -di; echo

