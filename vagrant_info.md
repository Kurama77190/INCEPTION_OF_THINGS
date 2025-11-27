## Commande Vagrant

Pour interagir avec vos environnements, Vagrant propose une série de commandes simples mais puissantes :*

    vagrant init : initialise un projet Vagrant et crée un Vagrantfile.
    vagrant up : démarre l’environnement.
    vagrant halt : arrête la machine virtuelle.
    vagrant destroy : supprime l’environnement.
    vagrant ssh : se connecter à la machine virtuelle via SSH.

## Installation de libvirt (KVM)

Libvirt est une bibliothèque open-source et un ensemble d’outils de gestion pour la virtualisation. Il fournit une interface de programmation (API) pour gérer des outils de virtualisation, telles que KVM, QEMU, Xen, VirtualBox et d’autres. Ma préférence va bien sûr à l’utilisation de KVM et QEMU car plus rapide que les autres solutions pourtant plus populaires comme VirtualBox ou vmWare Player.

Je préfère utiliser libvirt avec QEMU et KVM, sur un serveur de la famille Debian :

```bash
sudo apt update
sudo apt install build-dep qemu-kvm libvirt-daemon-system libguestfs-tools ksmtuned libvirt-clients libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev ruby-libvirt ebtables
sudo usermod -aG libvirt $USER
vagrant plugin install vagrant-libvirt
```

Si vous n’êtes pas un pro de la commande virsh je vous conseille d’installer cockpit.
Terminal window
```bash
sudo apt update
sudo apt install cockpit cockpit-machines
```
Ensuite pour gérer vos vm cliquez sur ce lien http://localhost:9090 ↗. Pour vous connecter, entrez votre user / mdp. La gestion des machines virtuelles se retrouve dans la section du même nom.

## Premières lignes de Vagrantfile

```c
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
end
```

Ici, on ne fait que configurer avec la version (“2”) de vagrant un objet config qui utilise une image ubuntu precise 32 bits.

À partir de là, on peut configurer plus finement notre VM avec différentes sections :

- config.vm : pour paramétrer la machine
- config.ssh : pour définir comment Vagrant accédera à votre machine
- config.vagrant : pour modifier le comportement de Vagrant en lui-même.
