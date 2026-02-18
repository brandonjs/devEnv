#!/opt/homebrew/bin/bash - 
#===============================================================================
#
#          FILE: fix_bats.sh
# 
#         USAGE: ./fix_bats.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 10/10/2023 10:35:45
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

toolCache="/Volumes/Unix/bats/tool-cache"
workplaceCache="/Volumes/Unix/workplace/BATS/env"
dockerPackagePath="BATSTransformDockerImage-1.0/runtime"
lambdaPackagePath="BATSTransformAWSLambda-1.0/runtime"
[[ -d ${toolCache}/DockerImage-1.0/env/${dockerPackagePath} ]] && rm -rf ${toolCache}/DockerImage-1.0/env/${dockerPackagePath} && ln -s ${workplaceCache}/${dockerPackagePath} ${toolCache}/DockerImage-1.0/env/${dockerPackagePath}
[[ -d ${toolCache}/AWSLambda-1.0/env/${lambdaPackagePath} ]] && rm -rf ${toolCache}/AWSLambda-1.0/env/${lambdaPackagePath} && ln -s ${workplaceCache}/${lambdaPackagePath} ${toolCache}/AWSLambda-1.0/env/${lambdaPackagePath}
