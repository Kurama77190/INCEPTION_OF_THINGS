#!/bin/bash

GITLAB_TOKEN=$(cat ../confs/.gitlab_token.txt)

if [ ! -d "../confs/repo_gitlab" ]; then
    cd ../confs
    git clone ssh://git@gitlab.localhost:2222/root/iot-manifests.git repo_gitlab
    cd repo_gitlab
    mkdir manifests
    cp ../will42_v1/deployment.yaml manifests/
    cp ../will42_v1/service.yaml manifests/
    cp ../will42_v1/namespace.yaml manifests/
    git add manifests/
    git commit -m "Initial commit with will42/playground:v1 manifests"
    git push
    exit 0
fi

echo "choose version of will42/playground to deploy:"
    echo "  1) v1"
    echo "  2) v2"
    read -p "Enter choice [1-2]: " choice
    case $choice in
        1) VERSION="v1" ;;
        2) VERSION="v2" ;;
        *) echo "Invalid choice, defaulting to v1"; VERSION="v1" ;;
    esac
    echo "Updating ArgoCD application to use image version: $VERSION"

if [ "$VERSION" == "v1" ]; then
    cd ../confs/repo_gitlab
    cp ../will42_v1/deployment.yaml manifests/
    git add manifests/deployment.yaml
    git commit -m "Update deployment to will42/playground:$VERSION"
    git push
fi

if [ "$VERSION" == "v2" ]; then
    cd ../confs/repo_gitlab
    cp ../will42_v2/deployment.yaml manifests/
    git add manifests/deployment.yaml
    git commit -m "Update deployment to will42/playground:$VERSION"
    git push
fi
