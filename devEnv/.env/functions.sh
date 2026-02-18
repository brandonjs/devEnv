# Functions go here
function psg ()
{
  if [ -x /usr/ucb/ps ]
  then
    /usr/ucb/ps aef | egrep -i $1
  else
    ps auxww | egrep -i $1
  fi
}

function psgrm()
{
  ps -Ae | egrep -v 'root|brandons'
}

function x ()
{
 exit
}

function lld ()
{
   if [ $1 ]
   then 
      ls -ahltsu | grep -i $1 | more 
   else 
      ls -ahltsu ./ | more 
   fi
}

function iterm2_print_user_vars () {
	iterm2_set_user_var gitBranch $((git branch 2> /dev/null) | grep \* | cut -c3-)
    if [[ -n "$(git rev-parse --show-toplevel 2> /dev/null)" ]]; then
        iterm2_set_user_var gitPackage $(basename $(git rev-parse --show-toplevel 2> /dev/null))
    else
        iterm2_set_user_var gitPackage $(basename $(pwd))
    fi
   	iterm2_set_user_var gitDiff $(is_git_branch_dirty)
   	iterm2_set_user_var humpDay $(is_it_wednesday)
	iterm2_set_user_var badge $(dir_badges)
}

function dir_badges() {
	while read directory badge || [[ -n "$directory" ]]
    do
        if [[ "$PWD" == $directory* ]]; then
            echo $badge
            break
        fi
    done < ~/.badges
}

function is_it_wednesday {
  	if [[ $(date +%A) = "Wednesday" ]]
    	then
     		echo "🐪" # Camel Prompt
    	else
    		echo "🐙" # Inky Prompt
  	fi
}

function is_git_branch_dirty {
	if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]]; then
        echo "⚡"
    else
        echo "👍"
    fi
}

function fixDns () {
   osascript ~/control_plane/set_search_domains.scpt >/dev/null 2>&1
}

function setup_aws_env {
#   . /Users/bsschwar/scripts/setup_aws_env.sh
    [ -z $1 ] && email="${USER}@amazon.com" || email=$1
    [ -z $2 ] && region="us-east-1" || region=$2
    [ -z $3 ] && role="Admin" || role=$3
    [[ ! ${email} =~ @amazon.com ]] && [[ ! ${email} =~ ^[0-9]+$ ]] && email="${email}@amazon.com"

    check_midway
    if [ $? -eq 0 ]; then
      clearawscreds
      ec=0
#      creds=$(isengardcli credentials --allow-breakglass --region ${region} --role ${role} ${email} 2>/dev/null) || ec=$?
      creds=$(isengardcli credentials --region ${region} --role ${role} ${email} 2>/dev/null) || ec=$?
      [[ ${ec} -ne 0 ]] && (echo "No creds." && clearawscreds) || eval ${creds}
      export ACCOUNT_ID=$(aws --region ${region} sts get-caller-identity | jq -r .Account)
      [[ -n $2 ]] && export AWS_REGION=${region}
    else
      echo "Midway not present or expired. Run mwinit"
    fi
}

function fetch {
    main_branch="mainline"
    current_branch=$(git symbolic-ref HEAD | awk -F\/ '{print $NF}')
    tracking_branch=$(git rev-parse --abbrev-ref ${current_branch}@{upstream} | awk -F\/ '{print $NF}')
    # if current == mainline
    if [ "x${current_branch}" == "x${main_branch}" ]; then
      git pull --rebase
    # if tracking mainline
    elif [ "x${current_branch}" == "x${tracking_branch}" ]; then
        git fetch origin $tracking_branch:$tracking_branch
        git rebase $tracking_branch
    # if not tracking mainline
    else
        git checkout ${main_branch}
        git pull --rebase
        git checkout ${current_branch}
        git rebase ${main_branch}
    fi
}

function get_execution
{
    profile=$USER
    if [[ $1 =~ ^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4} ]]; then
        [ ! -z "$2" ] && profile=$2
        execution_id=$1
    else
        profile=$1
        execution_id=$2
    fi
    aws --profile $profile ssm get-automation-execution --automation-execution-id $execution_id | jq
}

function get_command
{
    profile=$USER
    if [[ $1 =~ ^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4} ]]; then
        command_id=$1
        [ ! -z "$2" ] && profile=$2
    else
        profile=$1
        command_id=$2
    fi
    aws --profile $profile ssm list-command-invocations --command-id $command_id | jq
}

function get_command_outputs
{
    profile=$USER
    if [[ $1 =~ ^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4} ]]; then
        [ ! -z "$2" ] && profile=$2
        command_id=$1
    else
        profile=$1
        command_id=$2
    fi
    instance_ids=$(aws --profile $profile ssm list-command-invocations --command-id $command_id | jq -r ."CommandInvocations"[]."InstanceId")
    for instance in $instance_ids; do 
        aws --profile $profile ssm get-command-invocation --command-id $command_id --instance-id $instance | jq
    done
}

function tmlogs
{
  [[ -z $1 ]] && timeRange=1h || timeRange=$1
  printf '\e[3J' && log show --predicate 'subsystem == "com.apple.TimeMachine"' --info --last ${timeRange} | grep -F 'eMac' | grep -Fv 'etat' | awk -F']' '{print substr($0,1,19), $NF}'
}

function hgrep
{
  hist=$(history | grep "$@" | grep -v hgrep)
  [[ -z "${hist}" ]] && hist=$(grep "$@" ~/.bash_history | grep -v hgrep)
  echo "${hist}"
}

function dockerlogin
{
  [[ -z ${AWS_ACCESS_KEY_ID} ||  -z ${AWS_SECRET_ACCESS_KEY} ]] && echo "No creds." && return
  [ -z $1 ] && region="us-east-1" || region=$1
  [ -z $2 ] && account=${DEV_ACCOUNT_ID} || account=$2
  docker_url="${account}.dkr.ecr.${region}.amazonaws.com"
  case ${region} in
    cn-*)
      docker_url="${docker_url}.cn"
      ;;
  esac
  aws --region ${region} ecr get-login-password | docker login --username AWS --password-stdin ${docker_url}
  aws --region us-west-2 ecr get-login-password | docker login --username AWS --password-stdin 906394416424.dkr.ecr.us-west-2.amazonaws.com
}

function clearawscreds
{
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_ACCESS_KEY_ID
  unset AWS_SESSION_TOKEN
}

function gitStatus
{
  find . -name .git -execdir bash -c 'echo -en "\033[1;31m"repo: "\033[1;34m"; basename "`git rev-parse --show-toplevel`"; git status -s' \;
}

function assume_role() {
  refresh_aea_cookie
  role_account=$1
  role_name=$2
  [[ -z ${role_account} || -z ${role_name} ]] && echo "Didn't provide account or role name"
  creds=$(aws sts assume-role --role-arn arn:aws:iam::${role_account}:role/${role_name} --role-session-name ${role_name}-Testing)
  export AWS_ACCESS_KEY_ID=$(echo ${creds} | jq -r .Credentials.AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo ${creds} | jq -r .Credentials.SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo ${creds} | jq -r .Credentials.SessionToken)
}

function nonascii() {
  LANG=C grep --color=always '[^ -~]\+';
}
