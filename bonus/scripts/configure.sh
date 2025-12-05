#!/bin/bash

#set -e
#set -x

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)

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
echo "  BONUS: Clear Previous Installations"
echo "======================================"

# Lancer le script clear.sh pour nettoyer les installations précédentes
./clear.sh

echo -e "${MAGENTA}"
echo "======================================"
echo "  BONUS: Cluster K3D Installation"
echo "======================================"

# Créer le cluster K3d
echo -e "${BLUE}Creating K3d cluster 'sben-tayS'...${NC}"
if ! k3d cluster create sben-tayS > /dev/null 2>&1; then
    echo -e "${YELLOW}[WARNING] Cluster sben-tayS already exists. Deleting and recreating...${NC}"
    k3d cluster delete sben-tayS > /dev/null 2>&1 || true
    k3d cluster create sben-tayS > /dev/null 2>&1 || true
    echo -e "${GREEN}Cluster recreated. ✓${NC}"
fi


# Attendre que le cluster soit prêt
echo -e "${BLUE}Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=60s > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}K3d cluster is ready ✓${NC}"

echo -e "${MAGENTA}"
echo "======================================"
echo "  Step 2: GitLab Installation"
echo "======================================"

# Créer le namespace gitlab
echo -e "${BLUE}Creating namespace 'gitlab'...${NC}"
kubectl create namespace gitlab > /dev/null 2>&1

# Ajouter le repo Helm GitLab
echo -e "${BLUE}Adding GitLab Helm repository...${NC}"
helm repo add gitlab https://charts.gitlab.io/ > /dev/null 2>&1
helm repo update > /dev/null 2>&1
echo -e "${GREEN}GitLab Helm repo added ✓${NC}"

# Installer GitLab avec Helm
echo -e "${BLUE}Installing GitLab with Helm (this may take 3-5 minutes)...${NC}"
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --create-namespace \
  -f ../confs/GitLab/values.yaml \
  --set certmanager-issuer.email=false \
  --timeout 15m > /dev/null 2>&1

# Attendre que GitLab soit prêt
echo -e "${BLUE}Waiting for GitLab pods to be ready ..."
kubectl wait --for=condition=Ready pods -l app=webservice -n gitlab --timeout=600s > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}GitLab webservice is ready ✓${NC}"

# Récupérer le mot de passe root de GitLab
GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 -d) && \
echo "$GITLAB_PASSWORD" > ../confs/.gitlab_password.txt
echo -e "${GREEN}GitLab root password saved to ../confs/.gitlab_password.txt ✓${NC}"

# Créer un token d'accès GitLab API
echo -e "${BLUE}Creating GitLab API token...${NC}"
GITLAB_TOKEN=$(kubectl exec -n gitlab deploy/gitlab-toolbox -- gitlab-rails runner 'user = User.find_by(username: "root"); token = user.personal_access_tokens.create!(name: "iot-api", scopes: ["api", "read_repository", "write_repository"], expires_at: 365.days.from_now); puts token.token' 2>/dev/null | tail -n1) && \
echo "$GITLAB_TOKEN" > ../confs/.gitlab_token.txt
echo -e "${GREEN}GitLab API token saved to ../confs/.gitlab_token.txt ✓${NC}"

# Ajouter la clé SSH à GitLab
echo -e "${BLUE}Adding SSH key to GitLab...${GREEN}"
kubectl exec -n gitlab deploy/gitlab-toolbox -- gitlab-rails runner 'user = User.find_by(username: "root"); key = user.keys.create!(title: "iot-ssh-key", key: "'"${SSH_KEY}"'"); puts "SSH key added"' 2>/dev/null
echo -e "${BLUE}"

echo -e "${MAGENTA}"
echo "======================================"
echo "  Step 3: ArgoCD Installation"
echo "======================================"

# Créer le namespace argocd
echo -e "${BLUE}Creating namespace 'argocd'...${NC}"
kubectl create namespace argocd > /dev/null 2>&1

# Installer ArgoCD
echo -e "${BLUE}Installing ArgoCD in 'argocd' namespace...${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml > /dev/null 2>&1

# Attendre que les pods soient prêts
echo -e "${BLUE}Waiting for ArgoCD pods to be ready (this may take few minutes)..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s > /dev/null 2>&1 &
spinner $!
echo -e "${GREEN}ArgoCD is ready ✓${NC}"

# Récupérer le mot de passe admin
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) && \
echo "$ARGOCD_PASSWORD" > ../confs/.argocd_password.txt

echo -e "${MAGENTA}"
echo "======================================"
echo "  Step 4: Configure GitLab & ArgoCD"
echo "======================================"

# Port-forward ArgoCD UI && GitLab UI en arrière-plan
echo -e "${WHITE}"
echo -e "🌐 Starting ArgoCD UI port-forward..."
kubectl port-forward -n argocd --address=0.0.0.0 svc/argocd-server 8080:443 > /tmp/argocd-portforward.log 2>&1 &
echo $! > /tmp/argocd-portforward.pid
echo -e "🌐 Starting GitLab UI port-foward ..."
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8181:8080 > /tmp/gitlab-portforward.log 2>&1 &
echo $! > /tmp/gitlab-portforward.pid
echo -e "🌐 Starting GitLab SSH port-forward..."
kubectl port-forward -n gitlab svc/gitlab-gitlab-shell 2222:2222 > /tmp/gitlab-ssh-portforward.log 2>&1 &
echo $! > /tmp/gitlab-ssh-portforward.pid
echo -e "${GREEN}Port-forwards ready ✓${NC}"

# Attendre que les port-forwards soient stables
echo -e "${BLUE}Waiting for port-forwards to be ready...${NC}"
sleep 5

# Configuration du projet GitLab
echo -e "${BLUE}Creating GitLab project 'iot-manifests' via API...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k --request POST "http://gitlab.localhost:8181/api/v4/projects" \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "iot-manifests",
    "description": "IoT manifests for ArgoCD",
    "visibility": "public",
    "initialize_with_readme": false
  }')

if [ "$HTTP_CODE" = "201" ]; then
    echo -e "${GREEN}Project 'iot-manifests' created successfully ✓${NC}"
else
    echo -e "${RED}Failed to create project (HTTP: $HTTP_CODE)${NC}"
    #./clear.sh > /dev/null 2>&1
    #exit 1
fi

# Ajouter le dépôt Git au projet
echo -e "${BLUE}Adding Git repository to GitLab project...${NC}"
./push_gitlab.sh << EOF > /dev/null 2>&1
1
EOF
echo -e "${GREEN}Git repository added to project ✓${NC}"

# Créer le projet ArgoCD development
echo -e "${BLUE}Creating ArgoCD project 'development'...${NC}"
kubectl apply -f ../confs/argoCD/projects.yaml

# Appliquer l'application ArgoCD    
echo -e "${BLUE}Creating ArgoCD application 'myapp'...${NC}"
kubectl apply -f ../confs/argoCD/app.yaml
echo -e "${GREEN}ArgoCD Application created ✓${NC}"
echo ""

echo -e "${MAGENTA}"
echo "================================================"
echo "  ✅ BONUS Installation Complete!"
echo "================================================"
echo -e "${WHITE}"
echo "┌────────────────────────────────────────────────────────┐"
echo "│ ArgoCD UI: https://localhost:8080                      │"
echo "│ Username: admin                                        │"
echo "│ Password: $ARGOCD_PASSWORD                             │"
echo "│ (saved in ../confs/.argocd_password.txt)               │"
echo "├────────────────────────────────────────────────────────┤"
echo "│ GitLab UI: http://localhost:8181                       │"
echo "│ Username: root                                         │"
echo "│ Password: $GITLAB_PASSWORD                             │"
echo "│ (saved in ../confs/.gitlab_password.txt)               │"
echo "└────────────────────────────────────────────────────────┘"
echo ""
echo "Check the application:"
echo "  kubectl get applications -n argocd"
echo "  kubectl get pods -n dev"
echo ""
echo "Test the app:"
echo "  kubectl exec -n dev deploy/wil-playground -- wget -qO- localhost:8080"
echo ""
echo "To change version (v1 → v2): use ./push_gitlab.sh script"
echo ""
