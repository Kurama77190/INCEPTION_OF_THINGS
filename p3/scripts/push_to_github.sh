#!/bin/bash

set -e

echo "======================================"
echo "  GitHub Push Script"
echo "======================================"
echo ""

REPO_URL="https://github.com/Kurama77190/iot-manifests.git"
REPO_DIR="$HOME/iot-manifests"
SOURCE_DIR="$HOME/INCEPTION_OF_THINGS/p3/github-manifests"

# Check if repo already exists
if [ -d "$REPO_DIR" ]; then
    echo "📁 Repo already cloned at $REPO_DIR"
    cd "$REPO_DIR"
    git pull origin main || git pull origin master || echo "Pull failed, continuing..."
else
    echo "📥 Cloning repository..."
    cd "$HOME"
    git clone "$REPO_URL"
    cd "$REPO_DIR"
fi

echo ""
echo "📦 Creating manifests directory..."
mkdir -p manifests

echo "📋 Copying manifest files..."
cp "$SOURCE_DIR/namespace.yaml" manifests/
cp "$SOURCE_DIR/deployment.yaml" manifests/
cp "$SOURCE_DIR/service.yaml" manifests/

echo ""
echo "✅ Files copied:"
ls -lh manifests/

echo ""
echo "📤 Pushing to GitHub..."
git add manifests/
git commit -m "Add Kubernetes manifests for ArgoCD GitOps (wil42/playground:v1)" || echo "Nothing to commit"
git push origin main || git push origin master

echo ""
echo "======================================"
echo "  ✅ Push Complete!"
echo "======================================"
echo ""
echo "🔗 Verify on: $REPO_URL"
echo ""
echo "Next steps:"
echo "  1. Verify files on GitHub"
echo "  2. Create K3d cluster: k3d cluster create mycluster"
echo "  3. Install ArgoCD: kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
echo "  4. Apply app.yaml: kubectl apply -f ~/INCEPTION_OF_THINGS/p3/confs/app.yaml"
echo ""
