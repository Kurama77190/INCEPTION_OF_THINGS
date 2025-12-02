#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

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

echo -e "${MAGENTA}"
echo "======================================"
echo "  P3: Clear Previous Installations"
echo "======================================"

# Remettre will42/playground à la version v1
echo -e "${BLUE}Resetting will42/playground to version v1 on github...${NC}"
./push_git.sh << EOF > /dev/null 2>&1
1
EOF
echo -e "${GREEN}Reset complete. ✓${NC}"

echo -e "${MAGENTA}"
echo "======================================"
echo "  P3: K3d + ArgoCD Installation"
echo "======================================"

# Créer le cluster K3d
echo -e "${BLUE}Creating K3d cluster 'sben-tayS'...${NC}"
if ! k3d cluster create sben-tayS > /dev/null 2>&1; then
    echo -e "${YELLOW}[WARNING] Cluster sben-tayS already exists. Deleting and recreating...${NC}"
     k3d cluster delete sben-tayS > /dev/null 2>&1
     k3d cluster create sben-tayS > /dev/null 2>&1
     echo -e "${GREEN}Cluster recreated. ✓${NC}"
fi


# Attendre que le cluster soit prêt
echo -e "${BLUE}Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=60s > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}K3d cluster is ready ✓${NC}"

# Créer le namespace argocd
echo -e "${BLUE}Setting up ArgoCD...${NC}"
echo -e "${BLUE}Creating namespace 'argocd'...${NC}"
kubectl create namespace argocd > /dev/null 2>&1

# Installer ArgoCD
echo -e "${BLUE}Installing ArgoCD in 'argocd' namespace...${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml > /dev/null 2>&1

# Attendre que les pods soient prêts
echo -e "${BLUE}Waiting for ArgoCD pods to be ready (this may take 2-3 minutes)..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}ArgoCD is ready ✓${NC}"

# Récupérer le mot de passe admin
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) && \
echo "$PASSWORD" > ../confs/.argocd_password.txtecho ""

# Créer le projet ArgoCD development
echo -e "${BLUE}Creating ArgoCD project 'development'...${GREEN}"
kubectl apply -f ../confs/argoCD/projects.yaml 2>&1

# Appliquer l'application ArgoCD    
echo -e "${BLUE}Creating ArgoCD application 'myapp'...${GREEN}"
kubectl apply -f ../confs/argoCD/app.yaml 2>&1
# echo -e "${GREEN}ArgoCD Application created ✓${NC}"
echo ""

# Port-forward ArgoCD UI en arrière-plan
echo -e "${WHITE}🌐 Starting ArgoCD UI port-forward..."
kubectl port-forward -n argocd --address=0.0.0.0 svc/argocd-server 8080:443 > /tmp/argocd-portforward.log 2>&1 &
echo $! > /tmp/argocd-portforward.pid

echo -e "${MAGENTA}"
echo "======================================"
echo "  ✅ P3 Installation Complete!"
echo "======================================"
echo -e "${WHITE}"
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
