#!/opt/homebrew/bin/bash -xv
#===============================================================================
#
#          FILE: install_brazil_gem.sh
# 
#         USAGE: ./install_brazil_gem.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 04/04/2024 13:02:58
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

GEM_BIN=$1
GEM_INSTALL_DIR=$2
GEM_BIN_DIR=$3
GEM=$4

if [[ $GEM =~ (.*)-(.*).gem ]]; then
  GEM_NAME=${BASH_REMATCH[1]}
  GEM_VERSION=${BASH_REMATCH[2]}
elif [[ $GEM =~ (.*)-(.*) ]]; then
  GEM="${GEM}.gem"
  GEM_NAME=${BASH_REMATCH[1]}
  GEM_VERSION=${BASH_REMATCH[2]}
else
  echo "Unable to get gem name/version from GEM: $GEM"
  exit 1
fi

#/Users/bsschwar/workplace/RevereProxy/build/RubyGem-byebug/RubyGem-byebug-11.0.x/AL2_x86_64/DEV.STD.PTHREAD/build/private/env/ruby2.7.x/ruby2.7.x/bin/gem install -f --install-dir /Users/bsschwar/workplace/RevereProxy/build/RubyGem-byebug/RubyGem-byebug-11.0.x/AL2_x86_64/DEV.STD.PTHREAD/build/ruby2.7.x/lib/ruby/gems/2.7.0 --bindir /Users/bsschwar/workplace/RevereProxy/build/RubyGem-byebug/RubyGem-byebug-11.0.x/AL2_x86_64/DEV.STD.PTHREAD/build/ruby2.7.x/gem_bin --verbose --backtrace --no-document byebug-11.0.1.gem

$GEM_BIN fetch $GEM_NAME --version $GEM_VERSION --platform x86_64-darwin
$GEM_BIN install -f --install-dir $GEM_INSTALL_DIR --bindir $GEM_BIN_DIR --verbose --backtrace --no-document ${GEM} 
