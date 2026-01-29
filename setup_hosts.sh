#!/bin/bash

# ARR Stack Local DNS Setup Script
# Bu script /etc/hosts dosyasına gerekli domain'leri ekler

echo "ARR Stack için local domain'leri ekleniyor..."
echo ""
echo "Lütfen sudo şifrenizi girin:"

# Backup oluştur
sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)

# ARR Stack domain'lerini ekle
sudo tee -a /etc/hosts > /dev/null <<EOF

# ARR Stack Local Domains (HTTPS with Authelia)
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

echo ""
echo "✅ Domain'ler başarıyla eklendi!"
echo ""
echo "✅ Domain'ler başarıyla eklendi!"
echo ""
echo "🔒 HTTPS Erişim Adresleri (Authelia SSO):"
echo "  • Auth Portal: https://auth.arr.local"
echo "  • Traefik Dashboard: https://traefik.arr.local:8080"
echo "  • Radarr: https://radarr.arr.local"
echo "  • Sonarr: https://sonarr.arr.local"
echo "  • Prowlarr: https://prowlarr.arr.local"
echo "  • Bazarr: https://bazarr.arr.local"
echo "  • Lidarr: https://lidarr.arr.local"
echo "  • qBittorrent: https://qbittorrent.arr.local"
echo "  • Jellyfin: https://jellyfin.arr.local"
echo "  • Gluetun Health: https://gluetun.arr.local"
echo ""
echo "⚠️  Sonraki adımlar:"
echo "  1. SSL sertifikası oluştur: ./generate_certs.sh"
echo "  2. Authelia kullanıcı oluştur: ./setup_authelia.sh"
echo "  3. Docker başlat: docker-compose up -d"
echo ""
