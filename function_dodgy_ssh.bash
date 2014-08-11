#!/bin/bash

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