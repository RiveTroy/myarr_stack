#!/bin/bash

# ARR Stack - Self-Signed Wildcard Certificate Generator
# Generates *.arr.local certificate for local HTTPS development

set -e

CERTS_DIR="./traefik/certs"
DOMAIN="arr.local"
WILDCARD_DOMAIN="*.arr.local"
VALIDITY_DAYS=3650  # 10 years

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║   SSL Certificate Generator - *.arr.local         ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Create certs directory
mkdir -p "$CERTS_DIR"

echo -e "${YELLOW}[1/4]${NC} Generating private key..."
openssl genrsa -out "$CERTS_DIR/arr.local.key" 4096

echo -e "${YELLOW}[2/4]${NC} Creating certificate signing request..."
openssl req -new -key "$CERTS_DIR/arr.local.key" \
  -out "$CERTS_DIR/arr.local.csr" \
  -subj "/C=TR/ST=Istanbul/L=Istanbul/O=ARR Stack/OU=Home Lab/CN=*.arr.local"

echo -e "${YELLOW}[3/4]${NC} Creating certificate extensions config..."
cat > "$CERTS_DIR/arr.local.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = arr.local
DNS.2 = *.arr.local
DNS.3 = traefik.arr.local
DNS.4 = radarr.arr.local
DNS.5 = sonarr.arr.local
DNS.6 = prowlarr.arr.local
DNS.7 = bazarr.arr.local
DNS.8 = lidarr.arr.local
DNS.9 = qbittorrent.arr.local
DNS.10 = jellyfin.arr.local
DNS.11 = gluetun.arr.local
DNS.12 = auth.arr.local
EOF

echo -e "${YELLOW}[4/4]${NC} Generating self-signed certificate (valid for $VALIDITY_DAYS days)..."
openssl x509 -req \
  -in "$CERTS_DIR/arr.local.csr" \
  -signkey "$CERTS_DIR/arr.local.key" \
  -out "$CERTS_DIR/arr.local.crt" \
  -days $VALIDITY_DAYS \
  -sha256 \
  -extfile "$CERTS_DIR/arr.local.ext"

# Cleanup CSR and extension file
rm "$CERTS_DIR/arr.local.csr" "$CERTS_DIR/arr.local.ext"

# Set permissions
chmod 600 "$CERTS_DIR/arr.local.key"
chmod 644 "$CERTS_DIR/arr.local.crt"

echo -e "\n${GREEN}✓ Certificate generation completed!${NC}\n"
echo -e "${BLUE}Generated files:${NC}"
echo -e "  • ${GREEN}$CERTS_DIR/arr.local.key${NC} (Private Key)"
echo -e "  • ${GREEN}$CERTS_DIR/arr.local.crt${NC} (Certificate)"

echo -e "\n${YELLOW}Certificate Information:${NC}"
openssl x509 -in "$CERTS_DIR/arr.local.crt" -text -noout | grep -A 1 "Validity" | tail -2
echo ""
openssl x509 -in "$CERTS_DIR/arr.local.crt" -text -noout | grep -A 15 "Subject Alternative Name"

echo -e "\n${YELLOW}⚠️  Trust Certificate in Your Browser:${NC}\n"
echo -e "${BLUE}macOS:${NC}"
echo -e "  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $CERTS_DIR/arr.local.crt"
echo -e "\n${BLUE}Linux (Debian/Ubuntu):${NC}"
echo -e "  sudo cp $CERTS_DIR/arr.local.crt /usr/local/share/ca-certificates/arr.local.crt"
echo -e "  sudo update-ca-certificates"
echo -e "\n${BLUE}Firefox:${NC}"
echo -e "  Settings → Privacy & Security → Certificates → View Certificates → Import"
echo -e "\n${BLUE}Chrome/Edge:${NC}"
echo -e "  Settings → Privacy and security → Security → Manage certificates → Import"

echo -e "\n${GREEN}Done! Start Docker Compose to use HTTPS.${NC}\n"
