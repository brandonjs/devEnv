alias a='alias'
alias ll='ls -al'
alias ls='ls -G'
alias cl='cd; clear'
alias vissh='vi ~/.ssh/known_hosts'
alias syn='synergys --restart -f -d INFO'
alias ssh='ssh -XYA'
alias grep='egrep'
alias rdesktop='rdesktop -C -alias 24 -g 1152x864'
alias diff='diff --exclude=CVS --exclude=RCS --exclude=.git'
alias ndiff='diff'
alias buildp='dpkg-buildpackage -b -us -uc'
alias sbuildp='sudo dpkg-buildpackage -b -us -uc'
alias res='. ~/.bashrc'
alias functions='typeset -F | grep -v _[a-zA-Z]'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias bp='sudo /System/Library/Extensions/TMSafetyNet.kext/Contents/Helpers/bypass'

alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'

alias ports='netstat -tulanp'

## get top process eating memory
alias psmem='ps axvm'
alias psmem10='ps axvm | head -10'
 
## get top process eating cpu ##
alias pscpu='ps axvr'
alias pscpu10='ps axvr | head -10'
 
alias wget='wget -c'

alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

#alias cr='cr --reviewers $(~/scripts/cr_reviewers 1)'
#alias crall='cr --reviewers $(~/scripts/cr_reviewers)'
#alias recr='~/.toolbox/bin/cr'
#alias realcr='~/.toolbox/bin/cr'

if [[ -n $(which pyenv) ]]; then
  alias python27="~/.pyenv/versions/$(pyenv whence python2.7)/bin/python"
  alias python38="~/.pyenv/versions/$(pyenv whence python3.8)/bin/python3"
  alias python39="~/.pyenv/versions/$(pyenv whence python3.9)/bin/python3"
fi

alias dockercleanup='docker rmi $(docker images -q)'

alias gitff="git push origin :${USER}; git push origin ${USER}:${USER}"

alias pip86='arch -x86_64 pip install'
alias pip_arm='arch -arm64 pip install'
#alias brew='arch -arm64 brew'
alias brew86="arch -x86_64 /usr/local/bin/brew"
