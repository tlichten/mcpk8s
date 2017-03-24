#!/bin/bash -x

set -e

# Bootstrap nodes
salt -C 'I@salt:master' state.sls linux
salt -C 'I@salt:master' state.sls salt.master,reclass
salt -C 'I@salt:master' state.sls salt.minion
salt '*' state.sls linux,openssh,ntp,salt.minion

## Create and distribute SSL certificates for services using salt state
salt '*' state.sls salt

# Install keepalived
salt -C 'I@keepalived:cluster' state.sls keepalived -b 1

# Install haproxy
salt -C 'I@haproxy:proxy' state.sls haproxy
salt -C 'I@haproxy:proxy' service.status haproxy

# Install docker
salt -C 'I@docker:host' state.sls docker.host
salt -C 'I@docker:host' cmd.run 'docker ps'

# Install etcd with ssl support
salt -C 'I@etcd:server' state.sls salt.minion.cert,etcd.server.service
salt -C 'I@etcd:server' cmd.run '. /var/lib/etcd/configenv && etcdctl cluster-health'

# Install Kubernetes and Calico
salt -C 'I@kubernetes:master' state.sls kubernetes.master.kube-addons
salt -C 'I@kubernetes:pool' state.sls salt.minion.cert,kubernetes.pool
salt -C 'I@kubernetes:pool' cmd.run 'calicoctl node status'

# Setup NAT for Calico
salt -C 'I@etcd:server' --subset 1 state.sls etcd.server.setup

# Run whole master to check consistency
salt -C 'I@kubernetes:master' state.sls kubernetes exclude=kubernetes.master.setup

# Register addons
salt -C 'I@kubernetes:master' --subset 1 state.sls kubernetes.master.setup
