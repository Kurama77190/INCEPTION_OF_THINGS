#!/bin/bash
sudo apt update -y
sudo apt-get install -y curl

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --write-kubeconfig-mode=644" sh - 2>&1

# Attendre que K3s soit prêt
while ! sudo k3s kubectl get nodes 2>/dev/null; do
  echo "Waiting for K3s to be ready..."
  sleep 2
done

echo "K3s server is ready!"

# Configure kubectl pour vagrant
mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

# Déployer les applications
echo "Deploying applications..."

# Créer le namespace d'abord
sudo kubectl apply -f /vagrant/manifests/namespace.yaml

# Attendre que le namespace soit créé
while ! sudo kubectl get namespace applications-web 2>/dev/null; do
  sleep 0.2
done

sudo kubectl apply -f /vagrant/manifests/deployments/app1-deployment.yaml
sudo kubectl apply -f /vagrant/manifests/deployments/app2-deployment.yaml
sudo kubectl apply -f /vagrant/manifests/deployments/app3-deployment.yaml
sudo kubectl apply -f /vagrant/manifests/services/app1-service.yaml
sudo kubectl apply -f /vagrant/manifests/services/app2-service.yaml
sudo kubectl apply -f /vagrant/manifests/services/app3-service.yaml
sudo kubectl apply -f /vagrant/manifests/ingress.yaml

# Attendre que les pods soient créés (peut prendre du temps pour télécharger les images)
echo "Waiting for pods to be created..."
while [ "$(sudo kubectl get pods -n applications-web --no-headers 2>/dev/null | wc -l)" -lt 5 ]; do
  sleep 1
done

echo "Waiting for pods to be ready..."
# Attendre que les pods soient prêts (timeout de 120s pour le téléchargement des images)
sudo kubectl wait --for=condition=ready pod -l app=app1 -n applications-web --timeout=120s
sudo kubectl wait --for=condition=ready pod -l app=app2 -n applications-web --timeout=120s
sudo kubectl wait --for=condition=ready pod -l app=app3 -n applications-web --timeout=120s

# Vérifier que tous les containers sont prêts
echo "All set! K3s server is installed and applications are deployed."

echo "Testing access to applications..."

printf "curl http://app1.com"
printf "curl http://app2.com"
printf "curl http://app3.com"
printf "curl http://app.com"
printf "curl http://192.168.56.110"