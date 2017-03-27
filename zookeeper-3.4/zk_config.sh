#!/bin/bash


# Configure a zookeeper ensemble using consul-template
# to populate server lists

set -e 
set -x 

# set up SSL
if [ "$(ls -A /usr/local/share/ca-certificates)" ]; then
    # normally we'd use update-ca-certificates, but something about running it in
    # Alpine is off, and the certs don't get added. Fortunately, we only need to
    # add ca-certificates to the global store and it's all plain text.
    cat /usr/local/share/ca-certificates/* >> /etc/ssl/certs/ca-certificates.crt
fi

#This is the Zookeeper ID for the node.
# Supply if more than one node in the cluster
export ZK_ID=${ZK_ID:-1}

export ZK_HOME=${ZK_HOME:-/opt/zookeeper}

#ZK super user
ZK_SUPER_USER=${ZK_SUPER_USER:-super}
ZK_SUPER_PW=${ZK_SUPER_PW:-}


#Consul server
CONSUL_CONNECT=${CONSUL_CONNECT:-"consul:8500"}
CONSUL_SERVICE=${CONSUL_SERVICE:-zookeeper}

#If we have consul-template update immediately, we 
#get into a start/stop cycle with all the zk procs
CONSUL_MINWAIT=${CONSUL_MINWAIT:-4s}
CONSUL_MAXWAIT=${CONSUL_MAXWAIT:-20s}

args=()
#Optional: Set up auth to consul server
[[ -n "${CONSUL_TOKEN}" ]]        && args+=" -token ${CONSUL_TOKEN}"
[[ -n "${CONSUL_SSL}" ]]          && args+=" -ssl"
[[ -n "${CONSUL_SSL_VERIFY}" ]]   && args+=" -ssl-verify=${CONSUL_SSL_VERIFY}"

CONSUL_TEMPLATE=/usr/local/bin/consul-template
TEMPLATE_DIR=/consul-template/templates

RESTART_COMMAND=zk_launch.sh

# We can search for "servicename" or "tag.servicename"?
if [ -z ${CONSUL_TAG+x} ]; then 
  CONSUL_QUERY=${CONSUL_SERVICE}
else 
  CONSUL_QUERY="${CONSUL_TAG}.${CONSUL_SERVICE}" 
fi

${CONSUL_TEMPLATE} -consul-addr ${CONSUL_CONNECT} \
                   -wait ${CONSUL_MINWAIT}:${CONSUL_MAXWAIT} \
                   $args -template "${TEMPLATE_DIR}/zoo.env.tmpl:${ZK_HOME}/conf/zoo.env:${RESTART_COMMAND}" $@ 
