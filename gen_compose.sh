#!/bin/bash

# Generate a ZK docker compose file

DOCKER_IMAGE=${DOCKER_IMAGE:-"dianplus/zookeeper:latest"}

# Zookeeper needs an ID for each node in an ensemble
ZK_ID=${ZK_ID:-${RANDOM}}

# To customize the run env and cluster id
# ZK_ENV=production ./gen_compose.sh
# ZK_ENV=production ZK_CLUSTER_ID=cluster-fudi5f ./gen_compose.sh

# Values for service discovery in consul
SERVICE_TAGS=${SERVICE_TAGS:-"zookeeper"}
ZK_ENV=${ZK_ENV:-"dev"}
ZK_CLUSTER_ID=${ZK_CLUSTER_ID:-"cluster-id"}

# Consul address
CONSUL_CONNECT=${CONSUL_CONNECT:-"127.0.0.1:8500"}

# What we register in consul
# query at http://consul:8500/v1/catalog/service/${CONSUL_SERVICE}
CONSUL_SERVICE=${CONSUL_SERVICE:-"zookeeper"}

# Used for service discovery in consul template
# for example {{ range "cluster1.zookeeper" }}
CONSUL_QUERY=${CONSUL_QUERY:-"${ZK_CLUSTER_ID}.${CONSUL_SERVICE}"}

CONTAINER_NAME="${CONSUL_SERVICE}-${ZK_ENV}-${ZK_CLUSTER_ID}-${ZK_ID}"
CONTAINER_TIMEZONE=${CONTAINER_TIMEZONE:-"Asia/Shanghai"}

NODE=$(hostname -s)

OUTFILE=zookeeper-compose.yml # Name of the file to generate.

# -----------------------------------------------------------
# 'Here document containing the body of the generated
#  zookeeper docker-compose yml file.

cat > $OUTFILE <<EOF
version: '2'
services:
  zookeeper:
    image: '${DOCKER_IMAGE}'
    volumes:
      - './zk-data:/var/lib/zookeeper'
      - './zk-log:/var/log/zookeeper'
    network_mode: 'host'
    ports:
      - '2181:2181/tcp'
      - '2888:2888/tcp'
      - '3888:3888/tcp'
    environment:
      ZK_ID: $ZK_ID
      CONSUL_CONNECT:    '${CONSUL_CONNECT}'
      CONSUL_QUERY:      '${CONSUL_QUERY}'
      SERVICE_2181_NAME: '${CONSUL_SERVICE}'
      SERVICE_2181_ID:   '${NODE}:${CONTAINER_NAME}:2181:zkid-${ZK_ID}'
      SERVICE_2888_NAME: '${CONSUL_SERVICE}-2888'
      SERVICE_2888_ID:   '${NODE}:${CONTAINER_NAME}:2888:zkid-${ZK_ID}'
      SERVICE_3888_NAME: '${CONSUL_SERVICE}-3888'
      SERVICE_3888_ID:   '${NODE}:${CONTAINER_NAME}:3888:zkid-${ZK_ID}'
      SERVICE_TAGS:      '${SERVICE_TAGS},${ZK_ENV},${ZK_CLUSTER_ID},zkid-${ZK_ID}'
      JAVA_OPTS:         '-Duser.timezone=${CONTAINER_TIMEZONE} -Dfile.encoding=UTF-8'
    container_name: '${CONTAINER_NAME}'
    restart: 'always'
EOF
