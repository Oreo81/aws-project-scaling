#!/bin/bash
set -euo pipefail

NODE_EXPORTER_VERSION="1.8.2"
NODE_EXPORTER_USER="node_exporter"

sudo useradd --no-create-home --shell /usr/sbin/nologin $NODE_EXPORTER_USER 2>/dev/null || true

cd /tmp
curl -LO "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
sudo chown $NODE_EXPORTER_USER:$NODE_EXPORTER_USER /usr/local/bin/node_exporter
sudo chmod 755 /usr/local/bin/node_exporter

rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_USER
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
