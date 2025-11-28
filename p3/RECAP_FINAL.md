# 🎯 P3 - Récapitulatif Final

## ✅ Ce qui a été créé

### 📁 Structure P3
```
p3/
├── Vagrantfile                      # VM avec K3d + ArgoCD (2GB RAM, 2 CPU)
├── README.md                        # Documentation complète
├── GITHUB_PUSH_INSTRUCTIONS.md      # Instructions de push GitHub
├── confs/
│   ├── app.yaml                     # ArgoCD Application manifest
│   └── projects.yaml                # ArgoCD Project (optionnel)
├── github-manifests/                # Manifests à pousser sur GitHub
│   ├── namespace.yaml               # Namespace 'dev'
│   ├── deployment.yaml              # wil42/playground:v1
│   └── service.yaml                 # Service port 8888
└── scripts/
    ├── install_k3d_argocd.sh        # Installation automatique complète
    └── push_to_github.sh            # Push automatique vers GitHub
```

## 🚀 Démarrage Rapide

### Option 1 : Script Automatique (RECOMMANDÉ)

```bash
cd ~/INCEPTION_OF_THINGS/p3

# 1. Push les manifests sur GitHub
./scripts/push_to_github.sh

# 2. Installer K3d + ArgoCD
./scripts/install_k3d_argocd.sh

# 3. Accéder à ArgoCD UI
# URL: https://localhost:8080
# User: admin
# Password: (affiché par le script)
```

### Option 2 : Vagrant (VM automatique)

```bash
cd ~/INCEPTION_OF_THINGS/p3

# 1. Push les manifests sur GitHub
./scripts/push_to_github.sh

# 2. Démarrer la VM
vagrant up

# 3. SSH dans la VM
vagrant ssh

# 4. Port-forward ArgoCD (depuis la VM)
kubectl port-forward -n argocd --address=0.0.0.0 svc/argocd-server 8080:443
```

### Option 3 : Manuel

```bash
# 1. Push sur GitHub
cd ~/iot-manifests
mkdir -p manifests
cp ~/INCEPTION_OF_THINGS/p3/github-manifests/*.yaml manifests/
git add manifests/
git commit -m "Add K8s manifests"
git push

# 2. Créer cluster K3d
k3d cluster create mycluster

# 3. Installer ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# 4. Récupérer le password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 5. Port-forward ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:443 &

# 6. Créer l'application ArgoCD
kubectl apply -f ~/INCEPTION_OF_THINGS/p3/confs/app.yaml
```

## ✅ Vérification

### 1. Vérifier le cluster
```bash
kubectl get nodes
kubectl get namespaces
```

### 2. Vérifier ArgoCD
```bash
kubectl get pods -n argocd
kubectl get applications -n argocd
```

### 3. Vérifier l'application déployée
```bash
# Doit afficher le namespace 'dev'
kubectl get ns

# Doit afficher le pod wil-playground
kubectl get pods -n dev

# Sortie attendue :
# NAME                              READY   STATUS    RESTARTS   AGE
# wil-playground-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
```

### 4. Tester l'application
```bash
# Port-forward le service
kubectl port-forward -n dev svc/playground-service 8888:8888

# Tester (dans un autre terminal)
curl localhost:8888

# Tu devrais voir la réponse de l'app wil42/playground v1
```

## 🔄 Test du GitOps (changement de version v1 → v2)

### 1. Éditer le fichier dans GitHub

Sur GitHub (`https://github.com/Kurama77190/iot-manifests`), édite `manifests/deployment.yaml` :

```yaml
# Ligne 15 - AVANT
image: wil42/playground:v1

# APRÈS
image: wil42/playground:v2
```

Commit le changement : `"Update to version v2"`

### 2. ArgoCD détecte automatiquement

ArgoCD scanne le repo toutes les **3 minutes**.

Tu peux voir le sync dans l'UI : `https://localhost:8080`

### 3. Forcer le sync (optionnel)

```bash
# Forcer le sync immédiat
kubectl patch application myapp -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

### 4. Vérifier le changement

```bash
# Voir l'image utilisée
kubectl describe pod -n dev | grep Image

# Doit afficher : wil42/playground:v2
```

## 📊 Résultat attendu

```bash
$ kubectl get ns
NAME            STATUS   AGE
argocd          Active   10m
dev             Active   5m

$ kubectl get pods -n dev
NAME                              READY   STATUS    RESTARTS   AGE
wil-playground-65f745fdf4-d2l2r   1/1     Running   0          8m9s

$ kubectl get svc -n dev
NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
playground-service    ClusterIP   10.43.123.45   <none>        8888/TCP   8m
```

## 🎓 Concepts Appris

### P1
- ✅ K3s server/worker cluster
- ✅ Vagrant multi-VM
- ✅ Node token sharing

### P2
- ✅ Kubernetes Deployments, Services, Ingress
- ✅ Traefik routing par hostname
- ✅ Namespace management

### P3
- ✅ K3d (K3s in Docker)
- ✅ ArgoCD installation et configuration
- ✅ GitOps workflow
- ✅ Automatic sync et self-healing
- ✅ Changement de version automatique (v1 → v2)

## 🧹 Nettoyage

```bash
# Supprimer le cluster K3d
k3d cluster delete mycluster

# Ou avec Vagrant
vagrant destroy -f
```

## 🎉 C'est fini !

Tu as maintenant :
1. ✅ Un cluster K3d avec ArgoCD
2. ✅ Une application déployée automatiquement depuis Git
3. ✅ Un workflow GitOps fonctionnel
4. ✅ La capacité de changer de version (v1 ↔ v2) via Git

**Le projet INCEPTION_OF_THINGS est COMPLET !** 🚀
