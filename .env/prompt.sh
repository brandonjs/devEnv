# Change the window title of X terminals
shopt -s histappend

BLACK="\[\033[0;30m\]"
RED="\[\033[0;31m\]"
GREEN="\[\033[0;32m\]"
BROWN="\[\033[0;33m\]"
BLUE="\[\033[0;34m\]"
PURPLE="\[\033[0;35m\]"
CYAN="\[\033[0;36m\]"
LIGHT_GREY="\[\033[0;37m\]"

DARK_GREY="\[\033[1;30,\]"
BRIGHT_RED="\[\033[1;31m\]"
BRIGHT_GREEN="\[\033[1;32m\]"
YELLOW="\[\033[1;33m\]"
BRIGHT_BLUE="\[\033[1;34m\]"
BRIGHT_PURPLE="\[\033[1;35m\]"
BRIGHT_CYAN="\[\033[1;36m\]"
WHITE="\[\033[1;37m\]"

NO_COLOR="\[\033[0m\]"

case $TERM in
  xterm*|rxvt|eterm)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~}\007"'
    #TITLEBAR='\[\033]@;\u@h:\w\007\]'
    TITLEBAR=""
  ;;
  screen)
    #TITLEBAR='\[\033]@;\u@h:\w\007\]'
    TITLEBAR=""
    PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~}\033\\"'
  ;;
  *)
    #TITLEBAR='\[\033]@;\u@h:\w\007\]'
    TITLEBAR=""
  ;;
esac 
#PROMPT_COMMAND="history -a;history -c;history -r;$PROMPT_COMMAND"

PS1="${TITLEBAR}\
$BRIGHT_BLUE[$BRIGHT_CYAN\@$BRIGHT_BLUE]\
$BRIGHT_BLUE[$BRIGHT_RED\u@$BRIGHT_PURPLE\h$BRIGHT_BLUE:$BRIGHT_GREEN\W$BRIGHT_BLUE]\
$WHITE\$$NO_COLOR "
PS2='> '
ps4='+'

