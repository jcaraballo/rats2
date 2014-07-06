#!/bin/bash

cd "$( dirname "$0" )"
source functions.bash

if [[ $# -ne 3 ]] ; then
  moan 'usage: generate_haproxy_cfg.bash <stats_url> <stats_user> <stats_password>'
fi

stats_url=$1
stats_user=$2
stats_password=$3

cat <<EOF
global
    log 127.0.0.1 local0 notice
    maxconn 2000
    user haproxy
    group haproxy
    stats socket /etc/haproxy/haproxysock level admin

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    retries 3
    option  redispatch
    timeout connect   5000
    timeout client   10000
    timeout server   10000

listen rats 0.0.0.0:80
    mode http
    stats enable
    stats uri ${stats_url}
    stats realm Strictly\ Private
    stats auth ${stats_user}:${stats_password}
    balance roundrobin
    option httpclose
    option forwardfor
    server rats8080 127.0.0.1:8080 check weight 100
    server rats8081 127.0.0.1:8081 check disabled weight 0
EOF
