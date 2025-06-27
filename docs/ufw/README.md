```
#!/bin/bash

# === Configuration ===
# Set your current IP address here (IPv4 or IPv6)
ALLOWED_IP="YOUR-IP-HERE"

# === Firewall reset and setup ===

echo "Resetting UFW firewall rules..."

sudo ufw --force reset

echo "Setting default policies: deny incoming, deny outgoing, allow routed"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default allow routed

echo "Allowing essential ports..."
# sudo ufw allow 80/tcp      # HTTP
# sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 7171/tcp
sudo ufw allow 7172/tcp
sudo ufw allow 7172/udp

echo "Allowing access from your IP: $ALLOWED_IP"
sudo ufw allow from $ALLOWED_IP

echo "Enabling UFW..."
sudo ufw --force enable

echo "Current UFW status:"
sudo ufw status verbose
```