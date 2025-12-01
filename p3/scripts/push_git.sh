#!/bin/bash

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
    git clone git@github.com:Kurama77190/iot-manifests.git .samy
    cd .samy/manifests/
    cp ../../../confs/will42_v1/deployment.yaml .
    git add deployment.yaml
    git commit -m "Update deployment to will42/playground:$VERSION"
    git push
    cd ../.. && rm -rf .samy
fi

if [ "$VERSION" == "v2" ]; then
    git clone git@github.com:Kurama77190/iot-manifests.git .samy
    cd .samy/manifests/
    cp ../../../confs/will42_v2/deployment.yaml .
    git add deployment.yaml
    git commit -m "Update deployment to will42/playground:$VERSION"
    git push
    cd ../.. && rm -rf .samy
fi
