#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "======================================"
echo "  BONUS: Cleaning Up Everything"
echo "======================================"
echo -e "${NC}"

# Arrêter les port-forwards
echo -e "${BLUE}Stopping port-forwards...${NC}"
if [ -f /tmp/argocd-portforward.pid ]; then
    kill $(cat /tmp/argocd-portforward.pid) 2>/dev/null
    rm -f /tmp/argocd-portforward.pid
    echo -e "${GREEN}ArgoCD port-forward stopped ✓${NC}"
fi

if [ -f /tmp/gitlab-portforward.pid ]; then
    kill $(cat /tmp/gitlab-portforward.pid) 2>/dev/null
    rm -f /tmp/gitlab-portforward.pid
    echo -e "${GREEN}GitLab port-forward stopped ✓${NC}"
fi

if [ -f /tmp/gitlab-ssh-portforward.pid ]; then
    kill $(cat /tmp/gitlab-ssh-portforward.pid) 2>/dev/null
    rm -f /tmp/gitlab-ssh-portforward.pid
    echo -e "${GREEN}GitLab SSH port-forward stopped ✓${NC}"
fi

# Supprimer le cluster K3d
echo -e "${BLUE}Deleting K3d cluster 'sben-tayS'...${NC}"
k3d cluster delete sben-tayS > /dev/null 2>&1
echo -e "${GREEN}Cluster deleted ✓${NC}"

# Nettoyer les fichiers temporaires
echo -e "${BLUE}Cleaning up temporary files...${NC}"
rm -f ../confs/.argocd_password.txt
rm -f ../confs/.gitlab_password.txt
rm -f ../confs/.gitlab_token.txt
rm -rf ../confs/.gitlab
rm -f /tmp/argocd-portforward.log
rm -f /tmp/gitlab-portforward.log
echo -e "${GREEN}Cleanup complete ✓${NC}"

# Netoyer les images Docker utilisées
echo -e "${BLUE}Removing Docker images used...${NC}"
docker system prune -a --volumes -f
echo -e "${GREEN}Docker images removed ✓${NC}"

# Supprimer le dépôt Git cloné
echo -e "${BLUE}Removing cloned Git repository...${NC}"
rm -rf ../confs/repo_gitlab
git remote set-url origin git@github.com:Kurama77190/INCEPTION_OF_THINGS.git
echo -e "${GREEN}Cloned Git repository removed ✓${NC}"

echo -e "${MAGENTA}"
echo "======================================"
echo "  BONUS Cleanup Complete!"
echo "======================================"
echo -e "${NC}"
