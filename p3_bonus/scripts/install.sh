#!/bin/bash

set -e

ARCH=$(dpkg --print-architecture)

echo "==> Paquets de base"
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates git openssl

echo "==> Docker"
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sudo sh
fi
sudo systemctl start docker

echo "==> kubectl"
if ! command -v kubectl >/dev/null 2>&1; then
    KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
    curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
fi

echo "==> k3d"
if ! command -v k3d >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo ""
docker --version
kubectl version --client
k3d version
echo ""
