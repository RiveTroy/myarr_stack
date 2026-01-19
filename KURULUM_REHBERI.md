# ARR Stack - Güncel Kurulum Rehberi

## 📋 Yapılan Değişiklikler (Son Güncellemeler)

### 1. ✅ Authelia SSO Authentication
- Tüm servislere erişim için **Authelia login** zorunlu
- Encryption key'leri otomatik generate edilir (JWT, SESSION, STORAGE_ENCRYPTION_KEY)
- 2FA/TOTP desteği
- Session yönetimi (1 saat aktif, 5 dakika inactivity timeout)

### 2. 🔒 HTTPS Zorunlu (Traefik v3)
- TLS 1.2+ zorunlu, self-signed wildcard certificate (`*.arr.local`)
- HTTP otomatik HTTPS'e redirect
- Security headers (HSTS, CSP, X-Frame-Options)
- TLS configuration `traefik/dynamic/tls.yml` (Traefik v3 format)

### 3. 🌐 Network Access Model
- Port 80/443: Network accessible (0.0.0.0) - ev ağındaki tüm cihazlar erişebilir
- Port 8080: Localhost only (127.0.0.1) - Traefik dashboard
- Tailscale + AdGuard Home ile uzaktan erişim (opsiyonel)

### 4. 🛠️ macOS Uyumluluğu
- Docker socket path otomatik tanınır (`~/.docker/run/docker.sock`)
- `DOCKER_SOCKET` environment variable desteği

### 5. 🔄 Gluetun VPN Koruması
- Tüm arr servisleri + qBittorrent VPN koruması altında
- Ping-based healthcheck (HTTP 401 hatası düzeltildi)
- VPN kill switch aktif

## 🚀 Hızlı Kurulum (Önerilen)

### Otomatik Kurulum

```bash
# 1. Repository'yi klonla
git clone https://github.com/RiveTroy/myarr_stack.git
cd myarr_stack

# 2. .env dosyası oluştur ve VPN bilgilerini gir
cp .env.example .env
nano .env  # OPENVPN_USER ve OPENVPN_PASSWORD'u düzenle

# 3. Otomatik kurulum
chmod +x quick_setup.sh
./quick_setup.sh
```

**Script otomatik olarak:**
- ✅ Authelia encryption key'lerini generate eder
- ✅ SSL sertifikası oluşturur ve sisteme güvenilir yapar
- ✅ Authelia kullanıcısı oluşturur
- ✅ Hosts dosyasını günceller
- ✅ Data klasörlerini oluşturur
- ✅ Docker container'ları başlatır

## 🌐 Erişim Adresleri (HTTPS Zorunlu)

| Servis | URL | Auth | Port |
|--------|-----|------|------|
| **Authelia** | https://auth.arr.local | - | 9091 |
| Traefik Dashboard | http://127.0.0.1:8080 | ❌ (localhost only) | 8080 |
| Radarr | https://radarr.arr.local | ✅ | 7878 |
| Sonarr | https://sonarr.arr.local | ✅ | 8989 |
| Prowlarr | https://prowlarr.arr.local | ✅ | 9696 |
| Bazarr | https://bazarr.arr.local | ✅ | 6767 |
| Lidarr | https://lidarr.arr.local | ✅ | 8686 |
| qBittorrent | https://qbittorrent.arr.local | ✅ | 8080 |
| Jellyfin | https://jellyfin.arr.local | ❌ (own auth) | 8096 |
| Gluetun Health | https://gluetun.arr.local | ✅ | 10001 |

**İlk Erişim Akışı:**
1. Herhangi bir servise git (örn: https://radarr.arr.local)
2. Otomatik olarak https://auth.arr.local'e yönlendirilirsin
3. Kullanıcı adı/şifre ile giriş yap
4. İstediğin servise erişim sağla

## 🛠️ Faydalı Komutlar

### Logları İzle
```bash
# Tüm container'lar
docker-compose logs -f

# Sadece Traefik
docker-compose logs -f traefik

# Sadece Gluetun (VPN durumu)
docker-compose logs -f gluetun
```

### VPN Durumunu Kontrol Et
```bash
curl http://gluetun.arr.local/v1/publicip/ip
```

### Container'ları Yeniden Başlat
```bash
docker-compose restart
```

### Container'ları Durdur
```bash
docker-compose down
```

### Tüm Container'ları Sil ve Temizle
```bash
docker-compose down -v
```

## 🎯 Yapılandırma Önerileri

### 1. Prowlarr'da Indexer Ayarları
- URL'leri subdomain ile güncelle: `http://prowlarr.arr.local`

### 2. Radarr/Sonarr Download Client Ayarları
- qBittorrent URL: `http://qbittorrent.arr.local`

### 3. Bazarr Entegrasyonu
- Radarr URL: `http://radarr.arr.local`
- Sonarr URL: `http://sonarr.arr.local`

## ⚠️ Sorun Giderme

### Domain'lere erişilemiyor
```bash
# Hosts dosyasını kontrol et
cat /etc/hosts | grep arr.local

# DNS cache'i temizle (macOS)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### VPN bağlantısı kurulmuyor
```bash
# Gluetun loglarını kontrol et
docker-compose logs gluetun

# VPN bilgilerini kontrol et
# OPENVPN_USER ve OPENVPN_PASSWORD değerlerini doğrula
```

### Traefik servisleri görmüyor
```bash
# Traefik dashboard'u kontrol et
open http://traefik.arr.local:8080

# Network'ü kontrol et
docker network inspect rr_stack_arr_network
```

## 📚 Ek Bilgiler

### Alternatif DNS Çözümleri
Eğer daha gelişmiş bir DNS çözümü istersen:

1. **dnsmasq** kurulumu (macOS için):
   ```bash
   brew install dnsmasq
   echo 'address=/.arr.local/127.0.0.1' >> /opt/homebrew/etc/dnsmasq.conf
   sudo brew services start dnsmasq
   ```

2. **PiHole Container** eklemek için docker-compose'a:
   ```yaml
   pihole:
     image: pihole/pihole:latest
     container_name: pihole
     ports:
       - "53:53/tcp"
       - "53:53/udp"
       - "67:67/udp"
       - "8053:80/tcp"
     environment:
       TZ: 'Europe/Istanbul'
       WEBPASSWORD: 'admin'
     volumes:
       - './pihole/etc-pihole:/etc/pihole'
       - './pihole/etc-dnsmasq.d:/etc/dnsmasq.d'
     restart: unless-stopped
   ```

### SSL/HTTPS Eklemek İstersen
Traefik'e Let's Encrypt sertifikası eklemek için `docker-compose.yaml`'da Traefik komutlarına şunları ekle:

```yaml
- "--certificatesresolvers.myresolver.acme.email=your@email.com"
- "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
- "--certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web"
```

## 🎉 Tamamlandı!

Sisteminiz artık VPN korumalı ve subdomain'lerle erişilebilir durumda. İyi kullanımlar! 🚀
