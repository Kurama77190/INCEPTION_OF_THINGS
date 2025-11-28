# P3 - K3d + ArgoCD + GitOps

## 📋 Description

Configuration d'un environnement de CI/CD avec K3d (Kubernetes in Docker) et ArgoCD pour le déploiement automatique d'applications via GitOps.

## 🎯 Objectifs

- Installer K3d (K3s dans Docker)
- Déployer ArgoCD
- Configurer un déploiement GitOps automatique
- Synchronisation automatique avec un repo Git

## 🔧 K3d vs K3s - Quelle différence ?

| K3s | K3d |
|-----|-----|
| K3s = Kubernetes léger pour production | K3d = K3s dans Docker |
| Tourne directement sur la machine/VM | Tourne dans des containers Docker |
| Pour serveurs, edge, IoT | Pour développement local |
| Installation : `curl https://get.k3s.io` | Installation : nécessite Docker |
| Plus lourd (processus système) | Plus léger (containers) |
| Persist après reboot | Éphémère (comme les containers) |

**En résumé :** K3d = version "dockerisée" de K3s pour le développement local.

## 🤖 C'est quoi ArgoCD ?

**ArgoCD = outil de déploiement continu (CD) pour Kubernetes avec GitOps.**

### Principe GitOps
```
Git (code source)  →  ArgoCD surveille  →  Déploie automatiquement dans K8s
```

### Workflow traditionnel (manuel)
```bash
# 1. Tu modifies le fichier localement
vim deployment.yaml

# 2. Tu appliques manuellement
kubectl apply -f deployment.yaml

# Problème : pas de traçabilité, pas d'automatisation
```

### Workflow avec ArgoCD (automatique)
```bash
# 1. Tu modifies dans Git
git add deployment.yaml
git commit -m "Update replicas to 3"
git push

# 2. ArgoCD détecte et déploie AUTOMATIQUEMENT
# Pas besoin de kubectl apply !
```

### Avantages
✅ **Automatisation** : Push Git = déploiement automatique  
✅ **Traçabilité** : Tout versionné dans Git (qui, quand, quoi)  
✅ **Self-healing** : Si modification manuelle → ArgoCD restaure l'état du Git  
✅ **Rollback facile** : Retour à un ancien commit Git = rollback automatique  
✅ **Déclaratif** : Le Git définit l'état désiré, ArgoCD s'assure qu'il est appliqué  

### Exemple concret
1. **Tu crées un repo GitHub** avec tes manifests Kubernetes
2. **ArgoCD surveille ce repo** (ex: toutes les 3 minutes)
3. **Tu changes `replicas: 1` en `replicas: 5` dans Git**
4. **ArgoCD détecte → applique → 5 pods tournent automatiquement**

**En résumé : ArgoCD = robot qui synchronise ton cluster K8s avec ton repo Git !** 🤖

## 🚀 Installation

### Prérequis
```bash
# Docker doit être installé
docker --version

# Installer K3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Vérifier l'installation
k3d version
```

### Installation du CLI ArgoCD (optionnel)

**Le CLI n'est pas obligatoire** - tu peux tout faire via l'UI web ou kubectl !

**Si tu veux l'installer :**
```bash
# Linux
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd-linux-amd64
sudo mv argocd-linux-amd64 /usr/local/bin/argocd

# macOS
brew install argocd

# Vérifier
argocd version
```

**Login CLI (si installé) :**
```bash
# Se connecter
argocd login localhost:8080 --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
```

### Créer un cluster K3d
```bash
# Créer un cluster avec 1 server
k3d cluster create mycluster

# Vérifier le cluster
kubectl cluster-info
kubectl get nodes
```

## 📦 Déploiement ArgoCD

### Installation
```bash
# Créer le namespace
kubectl create namespace argocd

# Installer ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que les pods soient prêts
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### Accès à l'interface ArgoCD
```bash
# Récupérer le mot de passe admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward pour accéder à l'UI (en arrière-plan)
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

# Accéder à : https://localhost:8080
# User: admin
# Password: (celui récupéré ci-dessus)
```
## 🔄 Configuration GitOps

### Créer une Application ArgoCD
```bash
# Via CLI
argocd app create myapp \
  --repo https://github.com/Kurama77190/iot-manifests \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Synchroniser
argocd app sync myapp
```

### Via fichier YAML
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/votre-repo/manifests
    targetRevision: HEAD
    path: manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## 🧪 Tests et Vérification

### Vérifier le cluster K3d
```bash
# Lister les clusters
k3d cluster list

# Info détaillées
kubectl get all --all-namespaces
```

### Vérifier ArgoCD
```bash
# Status des pods ArgoCD
kubectl get pods -n argocd

# Lister les applications
kubectl get applications -n argocd

# Voir les logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Tester la synchronisation GitOps
```bash
# Modifier un fichier dans le repo Git
# ArgoCD détecte automatiquement et synchronise

# Forcer une synchronisation manuelle
kubectl patch application myapp -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

## 🛑 Nettoyage

```bash
# Supprimer le cluster K3d
k3d cluster delete mycluster

# Ou tout supprimer
k3d cluster delete --all
```

## 📚 Commandes K3d utiles

```bash
# Créer un cluster avec port mapping
k3d cluster create mycluster -p "8080:80@loadbalancer"

# Lister les clusters
k3d cluster list

# Stopper un cluster
k3d cluster stop mycluster

# Démarrer un cluster
k3d cluster start mycluster

# Supprimer un cluster
k3d cluster delete mycluster

# Importer une image dans k3d
k3d image import myimage:latest -c mycluster
```

## 📝 Notes

- K3d utilise des containers Docker pour simuler des nodes Kubernetes
- Parfait pour le développement local sans VM
- ArgoCD permet le GitOps : le repo Git = source de vérité
- Tout changement dans Git est automatiquement déployé dans le cluster

## 🔗 Ressources

- [Documentation K3d](https://k3d.io/)
- [Documentation ArgoCD](https://argo-cd.readthedocs.io/)
- [GitOps avec ArgoCD](https://argoproj.github.io/argo-cd/)
