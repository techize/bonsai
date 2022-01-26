#!/bin/bash
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m' # No Color

echo -e "[${LB}Info${NC}] uninstall k3s on k3s-master"
ssh -t -l ubuntu k3s-master -- "/bin/bash -c 'k3s-uninstall.sh'"

WORKERS="k3s-worker1 k3s-worker2 k3s-worker3"
for WORKER in ${WORKERS}; 
  do echo -e "[${LB}Info${NC}] uninstall k3s on ${WORKER}" && ssh -t -l ubuntu ${WORKER} -- "/bin/bash -c 'k3s-agent-uninstall.sh'"; 
done

