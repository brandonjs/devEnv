export EDITOR="vi"
export TERM="xterm-color"
export COMMAND_MODE="unix2003"
export PATH="/sbin:/usr/sbin:/usr/bin:/bin:/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/sbin:$PATH"
export MANPATH="/usr/share/man:/usr/local/share/man:/usr/local/man:/opt/local/man:$MANPATH"
export LOCAL_BASHCOMP_DIR="~/.bash_completion.d"

# enable bash completion in interactive shells
if [ -f "${BREW_DIR}/etc/bash_completion" ]; then
   . ${BREW_DIR}/etc/bash_completion
fi

if [ -f ~/etc/profile.d/bash_completion.sh ]; then
   . ~/etc/profile.d/bash_completion.sh
fi

if [ -d $LOCAL_BASHCOMP_DIR -a -r $LOCAL_BASHCOMP_DIR -a -x $LOCAL_BASHCOMP_DIR ]; then
    for i in $LOCAL_BASHCOMP_DIR/*; do
        [[ ${i##*/} != @(*~|*.bak|*.swp|\#*\#|*.dpkg*|.rpm*) ]] &&
            [ \( -f $i -o -h $i \) -a -r $i ] && . $i
    done
fi
unset i

export PATH=/opt/local/bin:/opt/local/sbin:$PATH

# Multiple Homebrews on Apple Silicon
if [ "$(arch)" = "arm64" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export SHELL="/opt/homebrew/bin/bash"
else
    eval "$(/usr/local/bin/brew shellenv)"
#    export PYENV_ROOT="$HOME/.pyenv-x86"
    export SHELL="/usr/local/bin/bash"
fi

[[ -s "${HOME}/.cargo/env" ]] && . ${HOME}/.cargo/env
[[ -s "${HOME}/Library/Perl/perl5/lib/perl5" ]] && eval "$(perl -I$HOME/Library/Perl/perl5/lib/perl5 -Mlocal::lib=$HOME/Library/Perl/perl5)"

#########################################################
# Mise should take care of all this now.
# Set up mise for runtime management
eval "$(mise activate bash)"

#[[ -s "/Users/brandons/.rvm/scripts/rvm" ]] && source "/Users/brandons/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
#[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" && PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

#[ -d ${HOME}/.nvm ] && export NVM_DIR=${HOME}/.nvm
#[ -f "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -f "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
#. $(${BREW_DIR} nvm)/nvm.sh

#if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
#if which jenv > /dev/null; then eval "$(jenv init -)"; fi

#export PATH="$HOME/.pyenv/bin:$PATH"
#eval "$(pyenv init -)"
#eval "$(pyenv virtualenv-init -)"
#eval "$(rbenv init -)"
#########################################################

export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(${BREW_DIR} openssl@1.1)"
export NODE_OPTIONS=--max-old-space-size=8192

#export DEV_ACCOUNT_ID=""
#export DEVELOPER_ACCOUNT_ID=""

# Set this is AWS CLI is acting up.
#export NODE_TLS_REJECT_UNAUTHORIZED=0
export JSII_DEPRECATED="quiet"
export PYTHONWARNINGS="ignore:Unverified HTTPS request"

export JAVA_TOOLS_OPTIONS="-Dlog4j2.formatMsgNoLookups=true"
