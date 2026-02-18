#!/opt/homebrew/bin/bash

CACHE_DIR="/Volumes/Unix/bats/tool-cache/"
declare -A PKG_MAP
declare -A PKG_NAME
PKGS="cryptography cffi ldap typed-ast ninja"
PKG_MAP[cryptography]="cryptography"
PKG_NAME[ldap]="python-ldap"
PKG_NAME[typed-ast]="typed_ast"
declare -A LIB_MAP
LIB_MAP[typed-ast]="ast"
LIB_MAP[typed-ast]="_openssl.abi3"
python_versions=$(pyenv versions | grep -v system | sed -e 's/(.*//g' -e 's/*//g')
pyenv_dir="$HOME/.pyenv/versions"
for pkg in $PKGS; do
    package_name="Python-${pkg}"
    for module in `find ${CACHE_DIR}/${package_name} -type d -depth 1 2>/dev/null`; do
        for al in AL2012 AL2_x86_64; do
          brazil_dir="${module}/${al}/DEV.STD.PTHREAD/build"
          for version in ${python_versions}; do
              pat='([0-9].[0-9]).*'
              if [[ $version =~ $pat ]]; then
                  base_ver=${BASH_REMATCH[1]}
                  pkg_name=${pkg}
                  if [ "x${PKG_NAME[${pkg}]}" != "x" ]; then
                    pkg_name=${PKG_NAME[${pkg}]}
                  fi
                  lib_name=${pkg_name}
                  if [ "x${LIB_MAP[${lib_name}]}" != "x" ]; then
                    lib_name=${LIB_MAP[${lib_name}]}
                  fi
                  if [ ! -d "${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/${pkg_name}" ]; then
                    ${pyenv_dir}/${version}/bin/pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org ${pkg_name}
                  fi
                  if [ -e "$brazil_dir/python${base_ver}/site-packages/${pkg_name}" ]; then
                      rm -rf ${brazil_dir}/python${base_ver}/site-packages/${pkg_name}
                      ln -s ${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/${pkg_name} ${brazil_dir}/python${base_ver}/site-packages/${pkg_name}
                      find ${brazil_dir}/python${base_ver}/site-packages -depth 1 -iname _${lib_name}*.so -exec rm {} \;
                      rsync -az ${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/_${lib_name}*.so ${brazil_dir}/python${base_ver}/site-packages/ 2>/dev/null
                  fi
                  if [ -e "$brazil_dir/lib/python${base_ver}/site-packages/${pkg_name}" ]; then
                      rm -rf ${brazil_dir}/lib/python${base_ver}/site-packages/${pkg_name}
                      ln -s ${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/${pkg_name} ${brazil_dir}/lib/python${base_ver}/site-packages/${pkg_name}
                      find ${brazil_dir}/lib/python${base_ver}/site-packages -depth 1 -iname _${lib_name}*.so -exec rm {} \;
                      rsync -az ${pyenv_dir}/${version}/lib/python${base_ver}/site-packages/_${lib_name}*.so ${brazil_dir}/lib/python${base_ver}/site-packages/ 2>/dev/null
                  fi
#                  if [ -e "$brazil_dir/lib/python${base_ver}/site-packages/${pkg_name}" ]; then
#                  fi
              fi
          done
        done
    done
done

    
