#/bin/sh

umask 022
set autolist
unset noclobber
set -o vi

export SHELL_TYPE="Bourne"
export HOST=`hostname`
export BREW_DIR=$(brew --prefix)

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

[ -f ~/.xsession-errors ] && rm -f ~/.xsession-errors* && ln -s /dev/null ~/.xsession-errors
[ -f ~/core* ] && rm -f ~/core*

for file in ~/.env/*.sh; do
   . $file
done

