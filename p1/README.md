# P1

## Vagrant : crée et configure les machines virtuelles (VMs)

Installe 2 VMs Debian : sben-tayS et sben-taySW
Configure leur réseau, RAM, CPU
Lance les scripts de provisioning
K3s : crée les nodes Kubernetes à l'intérieur des VMs

Transforme la VM sben-tayS en node Kubernetes "server"
Transforme la VM sben-taySW en node Kubernetes "worker"
Les connecte pour former un cluster

Analogie :

Vagrant = le constructeur qui bâtit 2 maisons (VMs)
K3s = l'entreprise qui installe le réseau/infrastructure à l'intérieur des maisons pour qu'elles communiquent
Si tu fais kubectl get nodes dans le cluster, tu verras 2 nodes Kubernetes (créés par k3s), pas par Vagrant. Vagrant a juste fourni les VMs hôtes.


## Architecture mise en place :

Dans ma p1, k3s sert à créer un cluster Kubernetes minimal avec 2 nœuds :

**_sben-tayS (192.168.56.110) - Server/Master :

- Installe k3s en mode server (control plane)
- Héberge l'API Kubernetes, le scheduler, le controller
- Génère un token d'authentification pour les workers
- Configure kubectl pour pouvoir gérer le cluster

*sben-taySW* (192.168.56.111) - Worker/Agent :

- Se connecte au server via SSH pour récupérer le token
- Rejoint le cluster en mode agent avec K3S_URL et K3S_TOKEN
- Exécute les workloads (pods) orchestrés par le master


#