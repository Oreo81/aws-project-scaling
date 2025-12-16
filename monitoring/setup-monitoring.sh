#!/bin/bash
set -e

# Mettre à jour et installer les dépendances de base sauf curl
yum update -y
yum install -y git docker || true

# Docker
systemctl enable docker
systemctl start docker

# Docker Compose (sans yum)
if ! command -v docker-compose &> /dev/null
then
  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# Node Exporter
useradd --no-create-home --shell /sbin/nologin node_exporter || true
NODE_EXPORTER_VERSION="1.8.2"
curl -LO "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter
chmod 755 /usr/local/bin/node_exporter

cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

################################
# Clone projet
################################
git clone https://github.com/Oreo81/aws-project-scaling.git /opt/aws-project-scaling

chown -R ec2-user:ec2-user /opt/aws-project-scaling

################################
# FIX permissions Grafana
################################
mkdir -p /opt/aws-project-scaling/monitoring/grafana/data
chown -R 472:472 /opt/aws-project-scaling/monitoring/grafana/data
chmod -R 775 /opt/aws-project-scaling/monitoring/grafana/data

################################
# Lancer monitoring stack
################################
cd /opt/aws-project-scaling/monitoring
docker-compose up -d