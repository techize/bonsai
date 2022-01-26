#!/bin/bash
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m' # No Color

K3S_VERSION="v1.23.2+k3s1"
echo "version" $K3S_VERSION "to be installed"

echo "############################################################################"
echo "Now deploying k3s on Proxmox VMs"
echo "############################################################################"

echo -e "[${LB}Info${NC}] deploy k3s on k3s-master"
# multipass exec k3s-master -- /bin/bash -c "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} sh -" | grep Using
# disable traefik
ssh -t ubuntu@k3s-master -- "/bin/bash -c 'curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} INSTALL_K3S_EXEC=\"--disable=traefik\" sh -' ";
# Get the IP of the master node
K3S_NODEIP_MASTER="https://$(host k3s-master | cut -d ' ' -f 4 ):6443"
# Get the TOKEN from the master node
K3S_TOKEN="$(ssh -t ubuntu@k3s-master -- '/bin/bash -c \"sudo cat /var/lib/rancher/k3s/server/node-token\"')"
# Deploy k3s on the worker nodes

WORKERS="k3s-worker1 k3s-worker2 k3s-worker3"
for WORKER in ${WORKERS}; 
do echo -e "[${LB}Info${NC}] deploy k3s on ${WORKER}" && ssh -t -l ubuntu ${WORKER} -- "/bin/bash -c 'curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} INSTALL_K3S_VERSION=${K3S_VERSION} sh -'"; 
done
sleep 10

echo "############################################################################"
echo exporting KUBECONFIG file from master node
ssh -t -l ubuntu k3s-master -- "/bin/bash -c 'sudo cat /etc/rancher/k3s/k3s.yaml'" > k3s.yaml
sed -i'.back' -e 's/127.0.0.1/k3s-master/g' k3s.yaml

export KUBECONFIG=`pwd`/k3s.yaml && echo -e "[${LB}Info${NC}] setting KUBECONFIG=${KUBECONFIG}"

kubectl config rename-context default k3s

echo -e "[${LB}Info${NC}] tainting master node: k3s-master"
kubectl taint node k3s-master node-role.kubernetes.io/master=effect:NoSchedule

sleep 3

for WORKER in ${WORKERS}; do kubectl label node ${WORKER} node-role.kubernetes.io/node=  > /dev/null && echo -e "[${LB}Info${NC}] label ${WORKER} with node"; done

sleep 10

kubectl get nodes

echo "are the nodes ready?"
echo "if you face problems, please open an issue on github"

echo "############################################################################"
echo -e "[${GREEN}Success k3s deployment rolled out${NC}]"
echo "############################################################################"
