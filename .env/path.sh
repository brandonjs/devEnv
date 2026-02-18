UNAME=`uname`

export PATH=/bin:/usr/bin:/usr/local/sbin:/sbin:/usr/sbin:/opt/local/bin:/opt/local/sbin:$PATH
#[ -d ~/.rbenv/shims ] && export PATH=$PATH:~/.rbenv/shims

export EDITOR=vi
export PRUNEFS="afs auto autofs cifs devfs devpts eventpollfs futexfs hugetlbfs iso9660 mqueue ncpfs nfs NFS nfs4 nfsd nnpfs pipefs proc ramfs rpc_pipefs sfs shfs smbfs sockfs subfs supermount sysfs tmpfs udf usbfs vperfctrfs"
export PRUNEPATHS="/tmp /var/tmp /root/.ccache"

if [ "$UNAME" == "Linux" ]; then
  export PATH=$PATH:/usr/X11R6/bin
  [ -d /etc/DIR_COLORS ] && eval `dircolors -b /etc/DIR_COLORS`
fi

#[ -d /usr/local/var/jenv ] && export PATH="/usr/local/var/jenv/bin:$PATH"

export GOPATH=$HOME/.go
#export GOROOT=/opt/homebrew/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
#export PATH=$PATH:$GOROOT/bin
