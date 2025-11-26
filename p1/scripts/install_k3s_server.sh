#!/bin/bash
sudo apt update -y
sudo apt-get install -y curl

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --write-kubeconfig-mode=644" sh - 2>&1

# Attendre que K3s soit prêt
while ! sudo k3s kubectl get nodes &>/dev/null; do
  echo "Waiting for K3s to be ready..."
  sleep 2
done

echo "K3s server is ready!"


# Configure kubectl pour vagrant

mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube
