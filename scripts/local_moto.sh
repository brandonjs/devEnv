#!/bin/bash

package_name="Python-moto"
root_dir="/Users/bsschwar/workplace/PythonCrypto"
src_dir="${root_dir}/src/${package_name}"
build_dir="${root_dir}/build/${package_name}"
root=$(brazil ws show | grep Root | awk '{print $NF}')
pushd $root/src
ln -s $src_dir .
popd

brazil ws --use --package Python-moto

pushd $root/build
ln -s $build_dir .
popd
