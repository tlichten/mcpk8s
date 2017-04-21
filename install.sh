#!/bin/bash -x


# Bootstrap nodes
salt -C 'I@salt:master' state.sls linux
salt -C 'I@salt:master' state.sls salt.master,reclass
salt -C 'I@salt:master' state.sls salt.minion
salt '*' state.sls linux,openssh,ntp,salt.minion
