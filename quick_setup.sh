#!/bin/bash

# ARR Stack Quick Setup Script
# Bu script tüm kurulum adımlarını otomatik yapar

set -e  # Hata durumunda dur

cd "$(dirname "$0")"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║   ARR Stack - Otomatik Kurulum Script v1.0       ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# 1. Hosts dosyasını güncelle
echo -e "${YELLOW}[1/8]${NC} /etc/hosts dosyası güncelleniyor..."
if ! grep -q "auth.arr.local" /etc/hosts; then
    echo -e "${BLUE}Lütfen sudo şifrenizi girin:${NC}"
    
    # Backup oluştur
    sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)
    
    # Domain'leri ekle
    sudo tee -a /etc/hosts > /dev/null <<EOF

# ARR Stack Local Domains (HTTPS)
127.0.0.1 traefik.arr.local
127.0.0.1 radarr.arr.local
127.0.0.1 sonarr.arr.local
127.0.0.1 prowlarr.arr.local
127.0.0.1 bazarr.arr.local
127.0.0.1 lidarr.arr.local
127.0.0.1 qbittorrent.arr.local
127.0.0.1 jellyfin.arr.local
127.0.0.1 gluetun.arr.local
127.0.0.1 auth.arr.local
EOF
    echo -e "${GREEN}✓ Hosts dosyası güncellendi${NC}"
else
    echo -e "${GREEN}✓ Hosts dosyası zaten güncel${NC}"
fi

# 2. Docker kontrol et
echo -e "\n${YELLOW}[2/8]${NC} Docker kontrol ediliyor..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker bulunamadı! Lütfen Docker Desktop'ı yükleyin.${NC}"
    echo "  https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo -e "${RED}✗ Docker çalışmıyor! Lütfen Docker Desktop'ı başlatın.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker çalışıyor${NC}"

# 3. .env dosyası kontrol et ve Authelia key'leri generate et
echo -e "\n${YELLOW}[3/8]${NC} .env dosyası kontrol ediliyor..."
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo -e "${BLUE}Copying .env.example to .env${NC}"
        cp .env.example .env
        echo -e "${RED}⚠ ÖNEMLI: .env dosyasını düzenleyip VPN bilgilerini girin!${NC}"
        echo -e "${YELLOW}nano .env${NC} komutuyla düzenleyebilirsiniz."
        echo -e "${BLUE}Devam etmek için Enter'a basın...${NC}"
        read
    else
        echo -e "${RED}✗ .env.example dosyası bulunamadı!${NC}"
        exit 1
    fi
fi

# Authelia key'lerini otomatik generate et (eğer yoksa)
if grep -q "WILL_BE_AUTO_GENERATED" .env 2>/dev/null; then
    echo -e "${BLUE}Authelia encryption key'leri generate ediliyor...${NC}"
    JWT_SECRET=$(openssl rand -hex 32)
    SESSION_SECRET=$(openssl rand -hex 32)
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/AUTHELIA_JWT_SECRET=WILL_BE_AUTO_GENERATED/AUTHELIA_JWT_SECRET=$JWT_SECRET/" .env
        sed -i '' "s/AUTHELIA_SESSION_SECRET=WILL_BE_AUTO_GENERATED/AUTHELIA_SESSION_SECRET=$SESSION_SECRET/" .env
        sed -i '' "s/AUTHELIA_STORAGE_ENCRYPTION_KEY=WILL_BE_AUTO_GENERATED/AUTHELIA_STORAGE_ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env
    else
        sed -i "s/AUTHELIA_JWT_SECRET=WILL_BE_AUTO_GENERATED/AUTHELIA_JWT_SECRET=$JWT_SECRET/" .env
        sed -i "s/AUTHELIA_SESSION_SECRET=WILL_BE_AUTO_GENERATED/AUTHELIA_SESSION_SECRET=$SESSION_SECRET/" .env
        sed -i "s/AUTHELIA_STORAGE_ENCRYPTION_KEY=WILL_BE_AUTO_GENERATED/AUTHELIA_STORAGE_ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env
    fi
    echo -e "${GREEN}✓ Authelia key'leri oluşturuldu${NC}"
else
    echo -e "${GREEN}✓ Authelia key'leri zaten mevcut, korunuyor${NC}"
fi

# VPN credentials kontrolü
if grep -q "your_nordvpn" .env; then
    echo -e "${RED}⚠ VPN credentials hala placeholder değerlerinde!${NC}"
    echo -e "${YELLOW}.env dosyasını düzenleyip OPENVPN_USER ve OPENVPN_PASSWORD'u girin.${NC}"
    echo -e "${BLUE}Devam etmek için Enter'a basın (veya Ctrl+C ile çıkın)${NC}"
    read
else
    echo -e "${GREEN}✓ .env dosyası mevcut${NC}"
fi

# 4. SSL Sertifikası oluştur
echo -e "\n${YELLOW}[4/8]${NC} SSL sertifikası oluşturuluyor..."
if [ ! -f "traefik/certs/arr.local.crt" ]; then
    echo -e "${BLUE}Generating self-signed certificate for *.arr.local${NC}"
    chmod +x generate_certs.sh
    ./generate_certs.sh
    
    echo -e "\n${YELLOW}Sertifikayı sisteme güvenilir yapın:${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${BLUE}sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./traefik/certs/arr.local.crt${NC}"
    else
        echo -e "${BLUE}sudo cp ./traefik/certs/arr.local.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates${NC}"
    fi
else
    echo -e "${GREEN}✓ SSL sertifikası zaten mevcut${NC}"
fi

# 5. Authelia kullanıcısı oluştur
echo -e "\n${YELLOW}[5/8]${NC} Authelia authentication kurulumu..."
if [ ! -f "authelia/users_database.yml" ]; then
    echo -e "${BLUE}Creating Authelia admin user${NC}"
    ./setup_authelia.sh
    
    # Update JWT and SESSION secrets
    JWT_SECRET=$(openssl rand -hex 32)
    SESSION_SECRET=$(openssl rand -hex 32)
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "1,/REPLACE_WITH_RANDOM_64_CHAR_STRING/s/REPLACE_WITH_RANDOM_64_CHAR_STRING/$JWT_SECRET/" authelia/configuration.yml
        sed -i '' "1,/REPLACE_WITH_RANDOM_64_CHAR_STRING/s/REPLACE_WITH_RANDOM_64_CHAR_STRING/$SESSION_SECRET/" authelia/configuration.yml
    else
        sed -i "0,/REPLACE_WITH_RANDOM_64_CHAR_STRING/s//$JWT_SECRET/" authelia/configuration.yml
        sed -i "0,/REPLACE_WITH_RANDOM_64_CHAR_STRING/s//$SESSION_SECRET/" authelia/configuration.yml
    fi
    echo -e "${GREEN}✓ Authelia secrets updated${NC}"
else
    echo -e "${GREEN}✓ Authelia zaten yapılandırılmış${NC}"
fi

# 6. Dizinleri oluştur
echo -e "\n${YELLOW}[6/8]${NC} Data dizinleri oluşturuluyor..."
mkdir -p ../rr_stack/data/{radarr,sonarr,prowlarr,bazarr,lidarr,qbittorrent,jellyfin,gluetun}/{config,data}
mkdir -p ../rr_stack/data/radarr/movies
mkdir -p ../rr_stack/data/sonarr/tvseries
mkdir -p ../rr_stack/data/lidarr/music
mkdir -p ../rr_stack/data/qbittorrent/downloads
echo -e "${GREEN}✓ Dizinler oluşturuldu${NC}"

# 7. Script'lere execute permission ver
echo -e "\n${YELLOW}[7/8]${NC} Script permission'ları ayarlanıyor..."
chmod +x monitor_and_restart.sh generate_certs.sh setup_authelia.sh setup_hosts.sh
echo -e "${GREEN}✓ Permission'lar ayarlandı${NC}"

# 8. Docker Compose başlat
echo -e "\n${YELLOW}[8/8]${NC} Docker container'ları başlatılıyor..."
echo -e "${BLUE}Bu işlem birkaç dakika sürebilir...${NC}\n"

docker-compose pull
echo -e "  ${GREEN}•${NC} Authelia Login: ${YELLOW}https://auth.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Traefik Dashboard: ${YELLOW}https://traefik.arr.local:8080${NC}"
echo -e "  ${GREEN}•${NC} Radarr: ${YELLOW}https://radarr.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Sonarr: ${YELLOW}https://sonarr.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Prowlarr: ${YELLOW}https://prowlarr.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Bazarr: ${YELLOW}https://bazarr.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Lidarr: ${YELLOW}https://lidarr.arr.local${NC}"
echo -e "  ${GREEN}•${NC} qBittorrent: ${YELLOW}https://qbittorrent.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Jellyfin: ${YELLOW}https://jellyfin.arr.local${NC} (veya http://<IP>:8096)"
echo -e "  ${GREEN}•${NC} Gluetun Health: ${YELLOW}https://gluetun.arr.local${NC}"

echo -e "\n${YELLOW}⚠️  İlk erişimde:${NC}"
echo -e "  1. Tarayıcı SSL uyarısı verecek (self-signed cert)"
echo -e "  2. 'Advanced' → 'Proceed to site' tıklayın"
echo -e "  3. Authelia login sayfası açılacak"
echo -e "  4. Oluşturduğunuz kullanıcı adı/şifre ile giriş yapın"
# 6. Durumu kontrol et
echo -e "\n${YELLOW}Container durumları kontrol ediliyor...${NC}\n"
docker-compose ps

# 7. VPN kontrolü
echo -e "\n${YELLOW}VPN bağlantısı kontrol ediliyor...${NC}"
sleep 10
VPN_IP=$(docker exec gluetun wget -qO- http://localhost:10001/v1/publicip/ip 2>/dev/null || echo "")

if [ -n "$VPN_IP" ]; then
    echo -e "${GREEN}✓ VPN bağlantısı başarılı! IP: $VPN_IP${NC}"
else
    echo -e "${YELLOW}⚠ VPN bağlantısı henüz kurulamadı. Biraz daha bekleyin ve 'docker-compose logs gluetun' ile kontrol edin.${NC}"
fi

# 8. DNS cache temizle (macOS)
echo -e "\n${YELLOW}DNS cache temizleniyor...${NC}"
sudo dscacheutil -flushcache 2>/dev/null || true
sudo killall -HUP mDNSResponder 2>/dev/null || true
echo -e "${GREEN}✓ DNS cache temizlendi${NC}"

# Başarı mesajı
echo -e "\n${GREEN}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║          ✓ Kurulum Başarıyla Tamamlandı!         ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}\n"

echo -e "${BLUE}Şimdi tarayıcınızda şu adresleri açabilirsiniz:${NC}\n"
echo -e "  ${GREEN}•${NC} Traefik Dashboard: ${YELLOW}http://traefik.arr.local:8080${NC}"
echo -e "  ${GREEN}•${NC} Radarr: ${YELLOW}http://radarr.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Sonarr: ${YELLOW}http://sonarr.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Prowlarr: ${YELLOW}http://prowlarr.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Bazarr: ${YELLOW}http://bazarr.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Lidarr: ${YELLOW}http://lidarr.arr.local${NC}"
echo -e "  ${GREEN}•${NC} qBittorrent: ${YELLOW}http://qbittorrent.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Jellyfin: ${YELLOW}http://jellyfin.arr.local${NC}"
echo -e "  ${GREEN}•${NC} Gluetun Health: ${YELLOW}http://gluetun.arr.local${NC}"

echo -e "\n${BLUE}Faydalı komutlar:${NC}\n"
echo -e "  ${GREEN}•${NC} Güvenlik rehberi: ${YELLOW}SECURITY.md${NC}"
echo -e "  ${GREEN}•${NC} Kurulum rehberi: ${YELLOW}README.md${NC}"
echo -e "  ${GREEN}•${NC} Restart rehberi: ${YELLOW}RESTART_REHBERI.md${NC}"
echo -e "  ${GREEN}•${NC} AdGuard DNS kurulum: ${YELLOW}ADGUARD_SETUP.md${NC}"

echo -e "\n${YELLOW}🔒 Güvenlik Özellikleri:${NC}"
echo -e "  ${GREEN}✓${NC} HTTPS zorunlu (TLS 1.2+)"
echo -e "  ${GREEN}✓${NC} SSO/2FA authentication (Authelia)"
echo -e "  ${GREEN}✓${NC} VPN kill switch (VPN düşerse torrent durur)"
echo -e "  ${GREEN}✓${NC} Localhost binding (dış erişim yok)"
echo -e "  ${GREEN}✓${NC} Security headers (HSTS, CSP, XSS protection)}"

echo -e "\n${YELLOW}📡 İsteğe Bağlı: AdGuard Home DNS${NC}"
echo -e "  ${GREEN}•${NC} DNS sunucusu + reklam engelleyici"
echo -e "  ${GREEN}•${NC} Tüm ağdaki cihazlar için domain çözümleme"
echo -e "  ${GREEN}•${NC} Kurulum: ${YELLOW}docker-compose -f docker-compose-adguard.yaml up -d${NC}"
echo -e "  ${GREEN}•${NC} Detaylı rehber: ${YELLOW}ADGUARD_SETUP.md${NC}"

echo -e "\n${BLUE}Docker komutları:${NC}\n"
echo -e "  ${GREEN}•${NC} Health check çalıştır: ${YELLOW}./monitor_and_restart.sh${NC}"
echo -e "  ${GREEN}•${NC} Container'ları durdur: ${YELLOW}docker-compose down${NC}"
echo -e "  ${GREEN}•${NC} Container'ları restart et: ${YELLOW}docker-compose restart${NC}"

echo -e "\n${BLUE}Detaylı bilgi için:${NC}"
echo -e "  ${GREEN}•${NC} Kurulum rehberi: ${YELLOW}KURULUM_REHBERI.md${NC}"
echo -e "  ${GREEN}•${NC} Restart rehberi: ${YELLOW}RESTART_REHBERI.md${NC}"

echo -e "\n${GREEN}İyi kullanımlar! 🚀${NC}\n"
