#!/usr/local/bin/bash

CACHE_DIR="$HOME/brazil-pkg-cache/packages"
declare -A PKG_MAP
declare -A PKG_NAME
declare -A LIB_MAP
PKGS="cryptography PyOpenSSL Pycryptodomex cffi lzma ldap typed-ast ninja regex"
PKGS="cryptography cffi"
PKG_MAP["cryptography"]="cryptography"
PKG_MAP[cffi]=""
PKG_MAP[ldap]=""
PKG_NAME["ldap"]="python-ldap"
PKG_NAME["typed-ast"]="typed_ast"
PKG_NAME["Pycryptodomex"]="Cryptodome"
PKG_NAME["PyOpenSSL"]="OpenSSL"
LIB_MAP["lzma"]="_lzma"
LIB_MAP["typed-ast"]="ast"
LIB_MAP["typed-ast"]="_openssl.abi3"
python_versions=$(pyenv versions | grep -v x86 | grep -v system | sed -e 's/(.*//g' -e 's/*//g')
pyenv_dir="$HOME/.pyenv/versions"
#for pkg in ${!PKG_MAP[@]}; do
for pkg in $PKGS; do
  [[ ${pkg} == "Pycryptodomex" ]] && package_name=${pkg} || package_name="Python-${pkg}"
  [[ ${pkg} == "PyOpenSSL" ]] && package_name=${pkg} || package_name="Python-${pkg}"
  for al in AL2012 AL2_x86_64 AL2_aarch64; do
    for version in ${python_versions}; do
      [[ ${al} =~ .*aarch64 ]] || version="${version}_x86"
      pkg_name=${pkg}
      pat='([0-9].[0-9]).*'
      if [[ $version =~ $pat ]]; then
        base_ver=${BASH_REMATCH[1]}
        non_dot_dir=${base_ver//.}
        pkg_name=${pkg}
        if [ "x${PKG_NAME[${pkg}]}" != "x" ]; then
          pkg_name=${PKG_NAME[${pkg}]}
        fi
        lib_name=${pkg_name}
        if [ "x${LIB_MAP[${lib_name}]}" != "x" ]; then
          lib_name=${LIB_MAP[${lib_name}]}
        fi
        if [ "x${PKG_NAME[${pkg}]}" != "x" ]; then
          pkg_name=${PKG_NAME[${pkg}]}
        fi
        lib_name=${pkg_name}
        if [ "x${LIB_MAP[${lib_name}]}" != "x" ]; then
          lib_name=${LIB_MAP[${lib_name}]}
        fi
      fi
      for cpython_dir in `find ${CACHE_DIR}/CPython${non_dot_dir}Runtime/ -depth 1 2>/dev/null`; do
        sp_dir="${cpython_dir}/${al}/DEV.STD.PTHREAD/build/python${base_ver}/lib/python${base_ver}/site-packages"
        if [ -e "${sp_dir}/${pkg_name}" ]; then
          rm -rf "${sp_dir}/${pkg_name}"
        fi
        ln -s ${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/${pkg_name} ${sp_dir}/${pkg_name}
      done
#        for module in `find ${CACHE_DIR}/${package_name} -type d -depth 1 2>/dev/null`; do
#          brazil_dir="${module}/${al}/DEV.STD.PTHREAD/build"
#          if [ ! -d "${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/${pkg_name}" ]; then
#            ${pyenv_dir}/${version}/bin/python -m pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org pip --upgrade
#            ${pyenv_dir}/${version}/bin/pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org ${pkg_name}
#          fi
#          if [ -e "$brazil_dir/python${base_ver}/site-packages/${pkg_name}" ]; then
#            rm -rf ${brazil_dir}/python${base_ver}/site-packages/${pkg_name}
#            ln -s ${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/${pkg_name} ${brazil_dir}/python${base_ver}/site-packages/${pkg_name}
#            find ${brazil_dir}/python${base_ver}/site-packages -depth 1 -iname _${lib_name}*.so -exec rm {} \;
#            rsync -az ${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/_${lib_name}*.so ${brazil_dir}/python${base_ver}/site-packages/ 2>/dev/null
#          fi
#          if [ -e "$brazil_dir/lib/python${base_ver}/site-packages/${pkg_name}" ]; then
#            rm -rf ${brazil_dir}/lib/python${base_ver}/site-packages/${pkg_name}
#            ln -s ${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/${pkg_name} ${brazil_dir}/lib/python${base_ver}/site-packages/${pkg_name}
#            find ${brazil_dir}/lib/python${base_ver}/site-packages -depth 1 -iname _${lib_name}*.so -exec rm {} \;
#            rsync -az ${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/_${lib_name}*.so ${brazil_dir}/lib/python${base_ver}/site-packages/ 2>/dev/null
#          fi
#         if [ -e "$brazil_dir/lib/python${base_ver}/site-packages/${pkg_name}" ]; then
#         fi
#          rsync -naz --include="*lzma*" --include="*/" --exclude="*" ${pyenv_dir}/${version}/lib/python${base_ver}/ ${brazil_dir}/lib/python${base_ver}/
#        done
    done
  done
done
