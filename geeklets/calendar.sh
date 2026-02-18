#!/bin/bash 

GRAY=`echo -e '\033[1;30m'`
LIGHT_GRAY=`echo -e '\033[0;37m'`
CYAN=`echo -e '\033[0;36m'`
LIGHT_CYAN=`echo -e '\033[1;36m'`
LIGHT_GREEN=`echo -e '\033[1;32m'`
RED=`echo -e '\033[41m\033[37m'`
NO_COLOR=`echo -e '\033[0m'`

cal=`cal`
today=`date "+%e"`
year=`date "+%Y"`
echo -e "${cal}" | sed -e "/${year}/! s/\( ${today} \)/${LIGHT_GREEN}\1${NO_COLOR}/g" -e '/^$/d'
