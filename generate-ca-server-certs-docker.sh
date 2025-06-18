#!/bin/bash

# Enhanced script for Docker MQTT broker certificate generation
# Usage: ./generate-ca-server-certs-docker.sh [hostname]
# Example: ./generate-ca-server-certs-docker.sh mqtt.example.com

set -e

# Default values
DEFAULT_HOSTNAME="localhost"
CERT_DIR="./certs"

# Parse command line arguments
HOSTNAME=${1:-$DEFAULT_HOSTNAME}

# Get current machine IP
MACHINE_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "127.0.0.1")

# Docker-specific IPs for container networking
DOCKER_NETWORK_IP="172.18.0.0/16"  # Common Docker bridge network
DOCKER_GATEWAY="172.17.0.1"        # Default Docker gateway
DOCKER_CONTAINER_IP="172.18.0.2"   # Typical container IP

# Certificate settings
COUNTRY="IN"
STATE="Gujarat"
CITY="Ahmedabad"
ORGANIZATION="Prahari Technologies"
ORG_UNIT="Prahari Technologies"
CA_COMMON_NAME="Root CA"
SERVER_COMMON_NAME="$HOSTNAME"

# Certificate validity (in days)
CA_VALIDITY=3650    # 10 years
SERVER_VALIDITY=365 # 1 year

# Key size
KEY_SIZE=2048

echo "=== MQTT Docker Certificate Generation ==="
echo "Hostname: $HOSTNAME"
echo "Machine IP: $MACHINE_IP"
echo "Certificate Directory: $CERT_DIR"
echo "Docker Container IP: $DOCKER_CONTAINER_IP"
echo "============================================="

# Create certificate directory if it doesn't exist
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

# Remove existing certificates if they exist
echo "Cleaning up existing certificates..."
rm -f ca.key ca.crt ca.srl server.key server.crt server.csr

echo "Step 1: Generating CA private key..."
openssl genrsa -out ca.key $KEY_SIZE

echo "Step 2: Generating CA certificate..."
openssl req -new -x509 -days $CA_VALIDITY -key ca.key -out ca.crt -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$CA_COMMON_NAME"

echo "Step 3: Generating server private key..."
openssl genrsa -out server.key $KEY_SIZE

echo "Step 4: Generating server certificate signing request..."
openssl req -new -key server.key -out server.csr -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$SERVER_COMMON_NAME"

echo "Step 5: Creating enhanced server certificate extensions file for Docker..."
cat > server_extensions.conf << EOF
[v3_req]
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $HOSTNAME
DNS.2 = localhost
DNS.3 = mosquitto-jwt
DNS.4 = *.local
IP.1 = 127.0.0.1
IP.2 = ::1
IP.3 = $MACHINE_IP
IP.4 = 172.17.0.1
IP.5 = 172.18.0.1
IP.6 = 172.18.0.2
IP.7 = 172.19.0.1
IP.8 = 172.20.0.1
IP.9 = 192.168.196.44
IP.10 = 141.148.202.151
EOF

echo "Step 6: Signing server certificate with CA..."
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days $SERVER_VALIDITY -extensions v3_req -extfile server_extensions.conf

echo "Step 7: Setting appropriate permissions..."
chmod 600 *.key
chmod 644 *.crt

echo "Step 8: Cleaning up temporary files..."
rm -f server.csr server_extensions.conf

echo ""
echo "=== Docker Certificate Generation Complete ==="
echo "Files generated:"
echo "  - CA Certificate: $(pwd)/ca.crt"
echo "  - CA Private Key: $(pwd)/ca.key"
echo "  - Server Certificate: $(pwd)/server.crt"
echo "  - Server Private Key: $(pwd)/server.key"
echo ""
echo "=== Certificate Information ==="
echo "CA Certificate:"
openssl x509 -in ca.crt -text -noout | grep -E "(Subject:|Not Before|Not After)" || echo "Certificate created successfully"
echo ""
echo "Server Certificate (Docker Enhanced):"
openssl x509 -in server.crt -text -noout | grep -E "(Subject:|Not Before|Not After|DNS:|IP Address:)" || echo "Certificate created successfully"
echo ""
echo "=== Docker Usage ==="
echo "1. Restart your Docker container: docker compose down && docker compose up"
echo "2. Use 'bash generate-device-cert.sh <device_name>' to create device certificates"
echo "3. Test connection with mosquitto clients"
echo "=============================================" 