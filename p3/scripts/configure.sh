#!/bin/bash

set -e

# Fonction spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    tput civis  # Masquer le curseur
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    tput cnorm  # Réafficher le curseur
}

echo "======================================"
echo "  P3: K3d + ArgoCD Installation"
echo "======================================"

# Créer le cluster K3d
echo "Creating K3d cluster 'sben-tayS'..."
if ! k3d cluster create sben-tayS > /dev/null 2>&1; then
    echo "[WARNING] Cluster sben-tayS already exists. Deleting and recreating..."
     k3d cluster delete sben-tayS > /dev/null 2>&1
     k3d cluster create sben-tayS > /dev/null 2>&1
     echo "Cluster recreated. ✓"
fi


# Attendre que le cluster soit prêt
echo -n "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s > /dev/null 2>&1 &
spinner $!
echo " ✓"


echo ""
echo "K3d cluster is ready ✓"
echo ""

# Créer le namespace argocd
echo "setup ArgoCD..."

echo "Creating namespace 'argocd'..."
kubectl create namespace argocd > /dev/null 2>&1 || echo "Namespace argocd already exists"

# Installer ArgoCD
echo "Installing ArgoCD in 'argocd' namespace..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml > /dev/null 2>&1

# Attendre que les pods soient prêts
echo -n "Waiting for ArgoCD pods to be ready (this may take 2-3 minutes)..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s > /dev/null 2>&1 &
spinner $!
echo " ✓"

echo ""
echo "ArgoCD is ready ✓"
echo ""

# Récupérer le mot de passe admin
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) && \
echo "$PASSWORD" > ../confs/.argocd_password.txt
echo ""

# Créer le projet ArgoCD development
echo "Creating ArgoCD project 'development'..."
kubectl apply -f ../confs/argoCD/projects.yaml

# Appliquer l'application ArgoCD    
echo "Creating ArgoCD application 'myapp'..."
kubectl apply -f ../confs/argoCD/app.yaml
echo ""
echo "ArgoCD Application created ✓"
echo ""

# Port-forward ArgoCD UI en arrière-plan
echo "🌐 Starting ArgoCD UI port-forward..."
kubectl port-forward -n argocd --address=0.0.0.0 svc/argocd-server 8080:443 > /tmp/argocd-portforward.log 2>&1 &
echo $! > /tmp/argocd-portforward.pid

echo ""
echo "======================================"
echo "  ✅ P3 Installation Complete!"
echo "======================================"
echo ""
echo "'--------------------"
echo "ArgoCD UI: https://localhost:8080"
open "https://localhost:8080"
echo "Username: admin"
echo "Password: $PASSWORD (also saved in ../confs.argocd_password.txt)"
echo "'--------------------"
echo ""
echo "Check the application:"
echo "  kubectl get applications -n argocd"
echo "  kubectl get pods -n dev"
echo ""
echo "Test the app:"
echo "  kubectl exec -n dev deploy/wil-playground -- wget -qO- localhost:8888"
echo ""
echo "To change version (v1 → v2): use push_git.sh script"
echo ""
