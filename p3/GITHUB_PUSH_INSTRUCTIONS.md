# Instructions pour GitHub

## 📦 Fichiers à pousser sur GitHub

Ces manifests sont dans `p3/github-manifests/` et doivent être poussés sur ton repo `iot-manifests`.

### Structure cible du repo GitHub
```
iot-manifests/
  manifests/
    namespace.yaml       # Crée le namespace 'dev'
    deployment.yaml      # Déploie wil42/playground:v1
    service.yaml         # Expose le service sur port 8888
```

## 🚀 Étapes

### 1. Cloner ton repo GitHub
```bash
cd ~
git clone https://github.com/Kurama77190/iot-manifests.git
cd iot-manifests
```

### 2. Copier les manifests
```bash
# Créer le dossier manifests
mkdir -p manifests

# Copier les fichiers depuis INCEPTION_OF_THINGS
cp ~/INCEPTION_OF_THINGS/p3/github-manifests/*.yaml manifests/
```

### 3. Vérifier le contenu
```bash
# Tu dois avoir :
ls -la manifests/
# deployment.yaml
# namespace.yaml
# service.yaml
```

### 4. Push sur GitHub
```bash
git add manifests/
git commit -m "Add Kubernetes manifests for ArgoCD GitOps"
git push origin main
```

### 5. Vérifier sur GitHub
Va sur `https://github.com/Kurama77190/iot-manifests` et vérifie que le dossier `manifests/` contient les 3 fichiers.

## ✅ Ensuite

Une fois pushé, ArgoCD pourra synchroniser :
- Crée l'application ArgoCD avec `kubectl apply -f p3/confs/app.yaml`
- ArgoCD détecte les manifests et déploie automatiquement
- Pour changer de version : édite `deployment.yaml` dans GitHub (v1 → v2) et push

## 🔄 Test du changement de version

### Version 1 (par défaut)
```yaml
# Dans manifests/deployment.yaml
image: wil42/playground:v1
```

### Version 2 (après modification)
```yaml
# Édite dans GitHub ou localement puis push
image: wil42/playground:v2
```

ArgoCD détecte le changement et redéploie automatiquement ! 🎉
