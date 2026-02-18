#!/opt/homebrew/bin/bash - 

# Treat unset variables as an error
set -o nounset

ZSTD_VER="1"
DYLIB=$(ls ~/Library/Java/Extensions/libzstd-jni-*-[0-9].dylib)
[[ ${DYLIB} =~ .*libzstd-jni-(.*).dylib ]] && ZSTD_VER=${BASH_REMATCH[1]}
ARCH_X86="x86_64"
ARCH_AMD="amd64"

if [[ -f ${DYLIB} ]]; then
  LINK=$(readlink ${DYLIB})
  ARCH=${ARCH_X86}
  [[ ${LINK} =~ .*libzstd-jni-${ZSTD_VER}.(.*).dylib ]] && ARCH=${BASH_REMATCH[1]}
  [[ ${ARCH} == ${ARCH_X86} ]] && arch=${ARCH_AMD} || arch=${ARCH_X86}
  [[ ${1-default} != "default" ]] && arch=$1
  newLink=${LINK/${ARCH}/${arch}}

  echo "Removing link: ${DYLIB} pointing to ${LINK}"
  rm ${DYLIB}
else
  newLink=$(echo ${DYLIB} | sed -e "s/\(.*\)\(\.dylib\)/\1\.${ARCH_X86}\2/g")
fi

if [[ -f ${newLink} ]]; then
  echo "Creating new link from: ${newLink} to ${DYLIB}:"
  ln -s ${newLink} ${DYLIB}
else
  echo "ERROR: dylib file: ${newLink} doesn't exist!!"
fi
