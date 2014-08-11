#!/bin/bash

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