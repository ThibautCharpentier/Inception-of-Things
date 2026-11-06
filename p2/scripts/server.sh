#!/bin/bash

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --bind-address=192.168.56.110 \
    --node-ip=192.168.56.110 \
    --flannel-iface=eth1 \
    --write-kubeconfig-mode 644" sh -

TIMEOUT=60
ELAPSED=0
until systemctl is-active k3s --quiet; do
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "ERREUR : K3s n'a pas démarré après ${TIMEOUT}s"
        exit 1
    fi
done

echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc

kubectl apply -f /vagrant_shared/app1/deployment.yaml -f /vagrant_shared/app1/service.yaml -f /vagrant_shared/app2/deployment.yaml -f /vagrant_shared/app2/service.yaml -f /vagrant_shared/app3/deployment.yaml -f /vagrant_shared/app3/service.yaml -f /vagrant_shared/ingress.yaml
