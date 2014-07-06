#!/bin/bash

cd "$( dirname "$0" )"
source functions.bash

function moan(){
  echo -e "$1" 1>&2
  exit 1
}

function wait_for_response(){
  echo "waiting for url $(echo ${1}| sed 's|[^:/]*|<server>|') to respond ${2}"
  response=''
  while [[ "$response" != "$2" ]]; do
    response=$(curl -s "$1")
    if [[ "$response" != "$2" ]]; then
      sleep 1
      echo "."
    fi
  done
}

function sssh(){
  if [[ "$DODGY" == "yes" ]] ; then
    ssh -i dodgy -oPasswordAuthentication=no -oUserKnownHostsFile=known_hosts $@
  else
    ssh -oPasswordAuthentication=no -oUserKnownHostsFile=known_hosts $@
  fi
}

function sscp(){
  if [[ "$DODGY" == "yes" ]] ; then
    scp -q -i dodgy -oPasswordAuthentication=no -oUserKnownHostsFile=known_hosts $@
  else
    scp -q -oPasswordAuthentication=no -oUserKnownHostsFile=known_hosts $@
  fi
}

if [[ $# -eq 1 ]] ; then
  target=$1
elif [[ $# -eq 0 && "$TARGET" != "" ]] ; then
  target=$TARGET
else
  moan 'You need to specify a target (e.g. user@hostname)'
fi

target_machine=$(echo "$target" | sed 's/.*@//')

SKIP_BUILD_ARTEFACT=$(echo ${SKIP_BUILD_ARTEFACT} | tr '[:upper:]' '[:lower:]')
if [[ "$SKIP_BUILD_ARTEFACT" == "y" || "$SKIP_BUILD_ARTEFACT" == "yes" ]] ; then
  ensure_no_uncommited_changes
else
  ./dist.bash || exit 1
fi

dist_path=target/scala-2.11/rats-*.jar
dist_file=`basename ${dist_path}`
version=`basename ${dist_file} | sed 's/\.jar//' | sed 's/rats-//'`

sssh ${target} "mkdir -p rats" || moan "Unable to ensure that ~/rats exists in the target"
sscp lb.bash "${target}:rats/" || moan "Unable to copy load balancer script lb.bash to <target>:rats/"
sscp ${dist_path} "${target}:rats/" || moan "Unable to copy artefact $dist_path to <target>:rats/"

ps_line=$(sssh ${target} "ps aux" | grep -i 'java -jar rats/rats-.*\.jar') || moan "Unable to retrieve rats ps information"
if [[ $(echo "$ps_line" | wc -l) -gt 1 ]] ; then
  moan "Too many running rats:\n${ps_line}"
fi

old_pid=$(echo "$ps_line" | sed 's/[^ ]* *//' | sed 's/ .*//' || moan "Unable to retrieve rats' curent pid")
old_port=$(echo "$ps_line" | sed 's/.* //' || moan "Unable to retrieve rats' currently running port")

if [[ "$old_port" -eq "8080" ]] ; then
  new_port=8081
  echo "Rats currently running in port 8080. Will deploy to 8081"
elif [[ "$old_port" -eq "8081" ]] ; then
  new_port=8080
  echo "Rats currently running in port 8081. Will deploy to 8080"
elif [[ "$old_port" -eq "" ]] ; then
  old_port=8081
  new_port=8080
  echo "Rats currently not running. Will deploy to 8080"
else
  moan "Unexpected rats port $old_port"
fi

echo Preparing load balancer
temp_file=$(mktemp)
sssh ${target} "chmod 755 rats/lb.bash && rats/lb.bash prepare ${old_port} ${new_port} && echo 'lb prepared'" | tee ${temp_file} || moan 'Failed to prepare load balancer (ssh)'

if [[ "$(tail -1 ${temp_file})" != 'lb prepared' ]] ; then
  moan "Failed to prepare load balancer"
fi

echo Starting new instance
sssh ${target} "nohup java -jar rats/${dist_file} ${new_port} &>>rats/rats.log &" || moan "Failed to start new instance"
wait_for_response "${target_machine}:${new_port}/id" "rats:${new_port}"

sssh ${target} "rats/lb.bash switch ${old_port} ${new_port}" || moan "Failed to switch"
wait_for_response "${target_machine}/id" "rats:${new_port}"

echo "Killing old instace with pid ${old_pid}"
sssh ${target} "kill ${old_pid}" || moan "Failed to kill old instance"

echo "Deployment complete"
