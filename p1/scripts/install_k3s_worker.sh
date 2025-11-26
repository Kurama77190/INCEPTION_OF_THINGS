#!/bin/bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110" sh -
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/
chown vagrant:vagrant /home/vagrant/k3s.yaml
