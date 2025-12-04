#!/bin/bash
sudo apt update -y 
sudo apt-get install -y curl

mkdir -p ~/.ssh
cp /vagrant/.vagrant/machines/sben-tayS/libvirt/private_key ~/.ssh/id_rsa_master
chmod 600 ~/.ssh/id_rsa_master
ssh-keyscan -H 192.168.56.110 >> ~/.ssh/known_hosts

SERVER_IP="192.168.56.110"

# Attendre que le token soit disponible sur le serveur
echo "Waiting for K3s server token..."
for i in {1..30}; do
  TOKEN=$(ssh -i ~/.ssh/id_rsa_master -o StrictHostKeyChecking=no vagrant@$SERVER_IP "sudo cat /var/lib/rancher/k3s/server/node-token" 2>/dev/null)
  if [ -n "$TOKEN" ]; then
    echo "Token retrieved successfully!"
    break
  fi
  echo "Attempt $i/30: Token not ready yet, waiting..."
  sleep 5
done

if [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to retrieve K3s token after 30 attempts"
  exit 1
fi

curl -sfL https://get.k3s.io | K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="$TOKEN" INSTALL_K3S_EXEC="--node-ip=192.168.56.111" sh -
