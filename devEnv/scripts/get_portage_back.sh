#!/bin/bash

python_version=$(python -c 'import sys; print "%02d%02d" % sys.version_info[:2]')
unpack_dir=/var/tmp/portage-unpack

die() {
	echo $@
	exit 1
}

case "$python_version" in
	0202)
		portage_version=2.0.51.22
		portage_dir=/usr/lib/portage
		;;
	0203)
		portage_version=2.1.1
		portage_dir=/usr/lib/portage
		;;
	0204|0205)
		portage_version=2.2_rc13
		portage_dir=${HOME}/portage-recover
		;;
	0201|0200)
		die "your python version is too old"
		;;
	*)
		die "unknown python version: $python_version"
		;;
esac

echo ">>> Found python version ${python_version}, using portage-${portage_version}"

tarball="portage-${portage_version}.tar.bz2"
mypath=$(readlink -f $0)
[ -z "${DISTDIR}" ] && DISTDIR=${mypath%/*/*}
mkdir -p "$portage_dir" "$unpack_dir"

[ -d "$DISTDIR" ] || DISTDIR=/var/tmp

wget -O "${DISTDIR}/${tarball}" "http://distfiles.gentoo.org/distfiles/${tarball}"

tar xfj "${DISTDIR}/${tarball}" -C "$unpack_dir" 
unpack_dir=${unpack_dir}/portage-${portage_version}

cp -r "${unpack_dir}"/{pym,bin} "${portage_dir}/"
if [ ! -e /etc/make.globals ]; then
	echo ">>> Restoring /etc/make.globals"
	cp "${unpack_dir}/cnf/make.globals" /etc
fi

if [ -e "${unpack_dir}/cnf/sets.conf" -a ! -e /usr/share/portage/config/sets.conf ]; then
	echo ">>> Restoring /usr/share/portage/config/sets.conf"
	mkdir -p /usr/share/portage/config/
	cp -r "${unpack_dir}/cnf/sets.conf" /usr/share/portage/config/
fi

echo ">>> Testing if rescue portage works and trying to remerge portage"
export PYTHONPATH="${portage_dir}/pym" 
export PATH="${portage_dir}/bin:${PATH}"
emerge --version > /dev/null && emerge --oneshot portage
if [ "$?" -ne 0 ]; then
	echo "!!! Portage was not remerged correctly"
fi
if [ "${portage_dir}" != /usr/lib/portage ]; then
	echo ">>> The rescue portage has been installed in \$HOME/portage-recover. You can access it"
	echo "    with the following command:"
	echo "    PYTHONPATH=${portage_dir}/pym PATH="${portage_dir}/bin:\$PATH" emerge"
	echo "    Of course you can also remove that directory if you've sucessfully remerged portage"
	echo "    and don't need the rescue version anymore."
fi
echo ">>> Cleaning up"
rm -rf "$(dirname ${unpack_dir})"
