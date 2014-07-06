#!/bin/bash

function moan(){
  echo -e "$1" 1>&2
  exit 1
}

function hap(){
  output=$(echo -e "$1" | socat stdio /etc/haproxy/haproxysock 2>&1)

  echo -e "$1"
  if [[ `echo "$output" | grep -v '^$' | wc -l` -ne 0 ]] ; then
    moan "haproxy socket command failed:${output}"
  else
    echo "."
  fi
}

function do_prepare(){
  hap "set weight rats/rats${from_port} 1\nset weight rats/rats${to_port} 100"
  hap "enable server rats/rats${from_port}"
  hap "disable server rats/rats${to_port}"
}

function do_switch(){
  hap "enable server rats/rats${to_port}"
  hap "disable server rats/rats${from_port}"
}

##########################

usage='usage: lb [ prepare | switch ] <from_port> <to_port>'

if [[ $# -ne 3 ]] ; then
  moan "$usage"
fi

comm=$1
from_port=$2
to_port=$3

if [[ "$comm" == "prepare" ]] ; then
  echo "Preparing switch from ${from_port} to ${to_port}"
  do_prepare
  echo "Prepared"
elif [[ "$comm" == 'switch' ]] ; then
  echo "Switching from ${from_port} to ${to_port}"
  do_switch
  echo "Switched"
else
  moan "Unrecognised command ${comm}\n$usage"
fi
