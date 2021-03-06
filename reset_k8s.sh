#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
cd ${basedir}

hostList=${1:?"missing 'hostList'"};shift
deploy=${1:-""}

./teardown_k8s.sh ${hostList}

if [ "x${deploy}x" = "xdeployx" ];then
  ./deploy_k8s_bin.sh ${hostList}
  ./deploy_k8s_tls.sh ${hostList}
  ./deploy_k8s_etc.sh ${hostList}
  ./deploy_k8s_scripts.sh ${hostList}
  ./deploy_k8s_systemd.sh ${hostList}
fi

./restart_calico.sh ${hostList}
./doall.sh ${hostList} "\
  sudo rm -fr /opt/kubernetes/logs; \
  sudo -iu kube mkdir -p /opt/kubernetes/logs; \
  sudo systemctl start kube-apiserver kube-scheduler kube-controller-manager kubelet kube-proxy; \
  "
kubectl create -f coredns.yaml
