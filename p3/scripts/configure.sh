#!/bin/bash

set -e

echo "======================================"
echo "  P3: K3d + ArgoCD Installation"
echo "======================================"

# Créer le cluster K3d
echo "🚀 Creating K3d cluster 'sben-tayS'..."
k3d cluster create sben-tayS || echo "Cluster already exists"

# Attendre que le cluster soit prêt
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s

echo ""
echo "✅ K3d cluster is ready"
echo ""

# Créer le namespace argocd
echo "📦 Installing ArgoCD..."
kubectl create namespace argocd 2>/dev/null || echo "Namespace argocd already exists"

# Installer ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que les pods soient prêts
echo "⏳ Waiting for ArgoCD pods to be ready (this may take 2-3 minutes)..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo ""
echo "✅ ArgoCD is ready"
echo ""

# Récupérer le mot de passe admin
echo "🔑 ArgoCD admin password:"
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "$PASSWORD"
echo "$PASSWORD" > ../confs/.argocd_password.txt
echo ""

# Créer le projet ArgoCD development
echo "📋 Creating ArgoCD project 'development'..."
kubectl apply -f ../confs/projects.yaml

# Appliquer l'application ArgoCD
echo "📋 Creating ArgoCD application 'myapp'..."
kubectl apply -f ../confs/app.yaml
echo ""
echo "✅ ArgoCD Application created"
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
echo "ArgoCD UI: https://localhost:8080"
echo "Username: admin"
echo "Password: $PASSWORD (also saved in ../confs/.argocd_password.txt)"
echo ""
echo "Check the application:"
echo "  kubectl get applications -n argocd"
echo "  kubectl get pods -n dev"
echo ""
echo "Test the app:"
echo "  kubectl exec -n dev deploy/wil-playground -- wget -qO- localhost:8888"
echo ""
echo "To change version (v1 → v2):"
echo "  Edit deployment.yaml in GitHub repo"
echo "  ArgoCD will auto-sync in ~3 minutes"
echo ""

