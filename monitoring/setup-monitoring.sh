#!/bin/bash

# Mise à jour et installation des prérequis
yum update -y
yum install -y git docker

# Installation Docker Compose
curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Démarrage de Docker
systemctl enable docker
systemctl start docker

# Cloner le repository GitHub contenant les fichiers nécessaires
git clone https://github.com/ton-utilisateur/monitoring-setup.git /opt/monitoring

# Lancer Docker Compose
cd /opt/monitoring
docker-compose up -d
