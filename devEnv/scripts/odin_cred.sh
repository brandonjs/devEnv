#!/bin/sh 

if [ $# -ne 2 ]
  then
    echo -e "Syntax: $0 [material set name] [type: cred, symkey, cert]\n"
    exit
fi
type=$2
matType=""
matType2=""

case $type in
	"cred")
		matType="Principal"
		matType2="Credential"
	;;

	"symkey")
		matType="SymmetricKey"
	;;

	"cert")
		matType="Certificate"
		matType2="PrivateKey"
	;;
esac

getGet="GET \"http://localhost:2009/query?Operation=retrieve&ContentType=JSON&material.materialName=$1&material.materialType=$matType\""

A=`$getGet | tr '{},' '\n\n\n' | sed -n -e 's/"materialData":"\(.*\)"/\1/p'`

if [ -z "$A" ]; then
	A=`$getGet | tr '{},' '\n\n\n' | sed -n 's/"Message":"\(.*\)"/\1/p'`
fi

if [ -n "$matType2" ]; then
	getGet2="GET \"http://localhost:2009/query?Operation=retrieve&ContentType=JSON&material.materialName=$1&material.materialType=$matType2\""
	B=`$getGet2 | tr '{},' '\n\n\n' | sed -n 's/"materialData":"\(.*\)"/\1/p'`
#		| base64 -di`

	if [ -z "$B" ]
	then
		B=`$getGet2 | tr '{},' '\n\n\n' | sed -n 's/"Message":"\(.*\)"/\1/p'`
	fi
fi

if [ $matType == "Principal" ]; then
	A=`echo $A | base64 -di`
	B=`echo $B | base64 -di`
fi

echo -e "\n$matType:
$A\n"

if [ -n "$matType2" ]; then
	echo -e "$matType2:
	$B\n"
fi
