# P2 - K3s avec Ingress et Applications Web

## 📋 Description

Déploiement d'une application web sur un cluster K3s à node unique avec routing basé sur le hostname via Ingress.

## 🏗️ Architecture

- **1 VM** : `sben-tayS` (192.168.56.110)
- **K3s** : mode server avec Traefik (Ingress Controller)
- **1 Application** : app1 accessible via `app1.com`

## 🚀 Démarrage

### Lancer la VM
```bash
cd p2
vagrant up
```

### Se connecter à la VM
```bash
vagrant ssh sben-tayS
```

## 🧪 Tests

### Option 1 : Depuis votre machine hôte (avec curl)
```bash
curl --header "Host: app1.com" http://192.168.56.110
```
**Résultat attendu :** `Hello from App 1`

### Option 2 : Depuis votre navigateur

1. Modifier `/etc/hosts` :
```bash
sudo nano /etc/hosts
```

2. Ajouter cette ligne :
```
192.168.56.110  app1.com
```

3. Ouvrir dans le navigateur :
```
http://app1.com
```

## 🔍 Commandes kubectl utiles

### Vérifier les ressources déployées
```bash
# Voir tous les pods
kubectl get pods

# Voir les pods avec plus de détails
kubectl get pods -o wide

# Voir les services
kubectl get services
kubectl get svc

# Voir l'ingress
kubectl get ingress

# Voir tous les objets
kubectl get all
```

### Debugging
```bash
# Logs d'un pod spécifique
kubectl logs <pod-name>

# Logs de l'application app1
kubectl logs -l app=app1

# Détails complets d'un pod
kubectl describe pod <pod-name>

# Détails de l'ingress
kubectl describe ingress app-ingress

# Vérifier les événements du cluster
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Informations détaillées
```bash
# Voir les nodes
kubectl get nodes

# Détails d'un node
kubectl describe node sben-tays

# Voir les namespaces
kubectl get namespaces

# Voir les pods système (Traefik, CoreDNS, etc.)
kubectl get pods -n kube-system
```

### Tests depuis la VM
```bash
# Tester localement
curl --header "Host: app1.com" localhost

# Voir les ressources consommées
kubectl top pods
kubectl top nodes
```

## 🛑 Arrêt et nettoyage

```bash
# Arrêter la VM
vagrant halt

# Détruire la VM
vagrant destroy

# Redémarrer proprement
vagrant destroy -f && vagrant up
```

## 📁 Structure du projet

```
p2/
├── Vagrantfile                          # Configuration VM
├── scripts/
│   └── install_k3s_server.sh           # Installation K3s + déploiement apps
└── manifests/
    ├── deployments/
    │   └── app1-deployment.yaml        # Déploiement app1
    ├── services/
    │   └── app1-service.yaml           # Service app1
    └── ingress.yaml                     # Règles de routing
```

## ✅ Vérification rapide

Tout fonctionne si :
1. `kubectl get pods` → pod app1 en status `Running`
2. `kubectl get ingress` → ingress avec une ADDRESS
3. `curl --header "Host: app1.com" 192.168.56.110` → retourne "Hello from App 1"
