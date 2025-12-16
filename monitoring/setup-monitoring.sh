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
git clone https://github.com/Oreo81/aws-project-scaling.git /opt/aws-project-scaling/


chown -R ec2-user:ec2-user /opt/aws-project-scaling/monitoring
chown -R 472:472 /opt/aws-project-scaling/monitoring/grafana/data
chown -R 472:472 /opt/aws-project-scaling/monitoring/grafana
chmod -R 755 /opt/aws-project-scaling/monitoring/grafana/data


# Lancer Docker Compose
cd /opt/aws-project-scaling/monitoring
docker-compose up -d
