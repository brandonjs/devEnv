#!/usr/local/bin/bash 

CACHE_DIR="$HOME/brazil-pkg-cache/packages"
declare -A PKG_MAP
declare -A PKG_NAME
PKG_MAP[pkcs11 sqlite3 ffi]=""
ruby_versions=$(rbenv versions | grep -v system | sed -e 's/^[\s\+\*]//g' | awk '{print $1}')
rbenv_dir="$HOME/.rbenv/versions"
for pkg in ${!PKG_MAP[@]}; do
    package_name="RubyGem-${pkg}"
    for version in ${ruby_versions}; do
        gem_cmd="${rbenv_dir}/${version}/bin/gem"
        for module in `find ${CACHE_DIR}/${package_name} -type d -depth 1`; do
          for al in AL2012 AL2_x86_64 AL2_aarch64; do
            brazil_dir="${module}/AL2_aarch64/DEV.STD.PTHREAD/build/"
            if [ -d "$brazil_dir" ]; then
                for ruby_dir in $(ls $brazil_dir); do
                    gem_dir=$(${gem_cmd} environment gemdir 2>/dev/null)
                    base_ver=`basename $gem_dir`
                    if [ -d "$brazil_dir/$ruby_dir/lib/ruby/gems/${base_ver}/gems" ]; then
                        pkg_ver=$(ls $brazil_dir/$ruby_dir/lib/ruby/gems/${base_ver}/gems/)
                        pkg_ver=${pkg_ver##*-}
                        installed_gems=$(${gem_cmd} list ${pkg} 2>/dev/null)
                        if [[ ! $installed_gems =~ $pkg_ver ]] && [[ ! "$version" =~ "1.9" ]]; then
                            if [ "${PKG_NAME[${pkg}]}" != "" ]; then
                                pkg=${PKG_NAME[${pkg}]}
                            fi
                            echo "Installing gem: ${pkg} version: ${pkg_ver} for ruby: ${version}"
                            ${rbenv_dir}/${version}/bin/gem install ${pkg} -v ${pkg_ver} 2>/dev/null
                            echo "done installing gem"
                        fi
                        rm -rf $brazil_dir/$ruby_dir/lib/ruby/gems/${base_ver}/gems/${pkg}-${pkg_ver}
                        ln -s ${gem_dir}/gems/${pkg}-${pkg_ver} $brazil_dir/$ruby_dir/lib/ruby/gems/${base_ver}/gems/${pkg}-${pkg_ver}

                    fi
                done
#            if [ -d "$brazil_dir/python${base_ver}/site-packages/${pkg}" ]; then
#                echo "$brazil_dir/python${base_ver}/site-packages/${pkg}"
#                rm -rf ${brazil_dir}/python${base_ver}/site-packages/${pkg}
#                ln -s ${rbenv_dir}/${version}/lib/python${base_ver}/site-packages/${pkg} ${brazil_dir}/python${base_ver}/site-packages/${pkg}
#                for lib in ${PKG_MAP[$pkg]}; do
#                    if [ -n `find ${brazil_dir}/python${base_ver}/site-packages/ -depth 1 -iname _${pkg}*.so` ] && [ -f ${rbenv_dir}/${version}/lib/python${base_ver}/site-packages/${lib} ]; then
#                        rm ${brazil_dir}/python${base_ver}/site-packages/_${pkg}*.so
#                        cp ${rbenv_dir}/${version}/lib/python${base_ver}/site-packages/${lib} ${brazil_dir}/python${base_ver}/site-packages/${lib}
#                    fi
#                done
            fi
          done
        done
    done
done
