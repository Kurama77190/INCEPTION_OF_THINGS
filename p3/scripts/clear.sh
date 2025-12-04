#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "======================================"
echo "  P3: Cleaning Up Everything"
echo "======================================"
echo -e "${NC}"

# Arrêter les port-forwards
echo -e "${BLUE}Stopping port-forwards...${NC}"
if [ -f /tmp/argocd-portforward.pid ]; then
    kill $(cat /tmp/argocd-portforward.pid) 2>/dev/null
    rm -f /tmp/argocd-portforward.pid
    echo -e "${GREEN}ArgoCD port-forward stopped ✓${NC}"
fi

# Supprimer le cluster K3d
echo -e "${BLUE}Deleting K3d cluster 'sben-tayS'...${NC}"
k3d cluster delete sben-tayS > /dev/null 2>&1
echo -e "${GREEN}Cluster deleted ✓${NC}"

# Nettoyer les fichiers temporaires
echo -e "${BLUE}Cleaning up temporary files...${NC}"
rm -f ../confs/.argocd_password.txt
rm -f /tmp/argocd-portforward.log
echo -e "${GREEN}Cleanup complete ✓${NC}"

echo -e "${MAGENTA}"
echo "======================================"
echo "  ✅ P3 Cleanup Complete!"
echo "======================================"
echo -e "${NC}"
