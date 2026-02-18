#/bin/sh

umask 022
set autolist
unset noclobber
set -o vi

shopt -s extglob

export SHELL_TYPE="Bourne"
export HOST=`hostname`

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

[ -f ~/.xsession-errors ] && rm -f ~/.xsession-errors* && ln -s /dev/null ~/.xsession-errors
[ -f ~/core* ] && rm -f ~/core*

for file in ~/.env/*.sh; do
   . $file
done

