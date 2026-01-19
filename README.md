# ARR Stack - Sıfırdan Kurulum Rehberi

## 📦 Gereksinimler

### 1. Sistem Gereksinimleri
- **İşletim Sistemi**: macOS, Linux veya Windows (WSL2)
- **Docker Desktop**: En güncel versiyon
- **Minimum RAM**: 8GB (16GB önerilir)
- **Disk Alanı**: 50GB+ (medya dosyaları için daha fazla)

### 2. Gerekli Yazılımlar

#### macOS
```bash
# Homebrew ile Docker Desktop yüklü değilse:
brew install --cask docker

# Docker Desktop'ı başlat
open -a Docker
```

#### Linux
```bash
# Docker ve Docker Compose kur
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### Windows (WSL2)
```powershell
# Docker Desktop for Windows'u indir ve kur
# https://www.docker.com/products/docker-desktop

# WSL2'de çalıştır
wsl --install
```

### 3. VPN Hesabı (NordVPN veya Başka)
- **NordVPN** (önerilen): https://nordvpn.com
- Service credentials'larını al: https://my.nordvpn.com/dashboard/nordaccount/
- Alternatifler: ProtonVPN, Surfshark, Mullvad (Gluetun destekliyor)

## 🚀 Adım Adım Kurulum

### 1️⃣ Projeyi İndir veya Klonla

```bash
# Ana klasör oluştur
mkdir -p ~/Documents/Arr
cd ~/Documents/Arr

# Config'i klonla
git clone https://github.com/RiveTroy/myarr_stack.git config
cd config
```

### 2️⃣ VPN Bilgilerini Ayarla

**.env dosyası oluştur** (en kolay yöntem):

```bash
# .env.example dosyasını kopyala
cp .env.example .env

# .env dosyasını düzenle
nano .env
```

Şu satırları düzenle:

```bash
# VPN Configuration (NordVPN)
OPENVPN_USER=your_nordvpn_service_username      # ← Buraya NordVPN kullanıcı adını yaz
OPENVPN_PASSWORD=your_nordvpn_service_password  # ← Buraya NordVPN şifresini yaz
SERVER_COUNTRIES=Finland,Switzerland,Albania    # İstediğin ülkeleri seç

# Diğer ayarlar (opsiyonel)
TZ=Europe/Istanbul           # Kendi timezone'unu
PUID=1000                    # Linux için user ID (id -u)
PGID=1000                    # Linux için group ID (id -g)
```

**Önemli**: NordVPN için service credentials kullan (normal hesap şifresi değil!)
- https://my.nordvpn.com/dashboard/nordaccount/ adresinden al

**Alternatif VPN Sağlayıcılar** (.env dosyasında düzenle):

```bash
# ProtonVPN
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=wireguard
WIREGUARD_PRIVATE_KEY=your_protonvpn_key

# Mullvad
VPN_SERVICE_PROVIDER=mullvad
VPN_TYPE=wireguard
WIREGUARD_PRIVATE_KEY=your_mullvad_key

# Surfshark
VPN_SERVICE_PROVIDER=surfshark
VPN_TYPE=openvpn
OPENVPN_USER=your_surfshark_username
OPENVPN_PASSWORD=your_surfshark_password
```

### 3️⃣ Otomatik Kurulum (Önerilen) ⚡

**Tek Komutla Her Şeyi Hazırla**:

```bash
# Scripti çalıştırılabilir yap
chmod +x quick_setup.sh

# Otomatik kurulum başlat
./quick_setup.sh
```

Bu script:
- ✅ .env dosyası oluşturur (.env.example'dan)
- ✅ Authelia encryption key'lerini otomatik generate eder (JWT, SESSION, STORAGE_ENCRYPTION_KEY)
- ✅ VPN credentials kontrolü yapar
- ✅ SSL sertifikası oluşturur (traefik/certs/ altına, TLS 1.2+ zorunlu)
- ✅ Authelia kullanıcısı oluşturur (SSO/2FA)
- ✅ ../rr_stack/data/ klasörlerini oluşturur
- ✅ /etc/hosts dosyasını günceller (sudo gerektirir)
- ✅ Docker container'ları başlatır (Traefik v3 + Gluetun)
- ✅ Servislerin sağlık kontrolünü yapar

**macOS Kullanıcıları:** Docker socket path otomatik tanınır (`~/.docker/run/docker.sock`)

**İlk erişim**: https://radarr.arr.local → Authelia login → Servis

**Hosts dosyasını ayrı güncellemek için**:

```bash
chmod +x setup_hosts.sh
sudo ./setup_hosts.sh
```

### 3️⃣ Manuel Kurulum (Alternatif)

#### Data Klasörlerini Oluştur

```bash
# config dizinindeyken çalıştır:
mkdir -p ../rr_stack/data/{radarr,sonarr,prowlarr,bazarr,lidarr,qbittorrent,jellyfin,gluetun}/{config,data}
mkdir -p ../rr_stack/data/radarr/movies
mkdir -p ../rr_stack/data/sonarr/tvseries
mkdir -p ../rr_stack/data/lidarr/music
mkdir -p ../rr_stack/data/qbittorrent/downloads
```

#### DNS Ayarları

##### Yöntem 1: AdGuard Home (Önerilen) 📡

Tüm cihazlar için otomatik DNS çözümleme + reklam engelleme:

```bash
docker-compose -f docker-compose-adguard.yaml up -d
```

Detaylı kurulum için: [ADGUARD_SETUP.md](ADGUARD_SETUP.md)

##### Yöntem 2: Hosts Dosyası (Manuel)

**macOS / Linux**
```bash
# Hosts dosyasını düzenle
sudo nano /etc/hosts

# Şu satırları ekle (SERVER_IP = sunucu IP adresi, aynı bilgisayarda ise 127.0.0.1):
SERVER_IP traefik.arr.local
SERVER_IP radarr.arr.local
SERVER_IP sonarr.arr.local
SERVER_IP prowlarr.arr.local
SERVER_IP bazarr.arr.local
SERVER_IP lidarr.arr.local
SERVER_IP qbittorrent.arr.local
SERVER_IP jellyfin.arr.local
SERVER_IP gluetun.arr.local
SERVER_IP auth.arr.local

# Kaydet ve çık (Ctrl+O, Enter, Ctrl+X)
```

**Windows (PowerShell Admin)**
```powershell
# Hosts dosyasını aç
notepad C:\Windows\System32\drivers\etc\hosts

# Şu satırları ekle ve kaydet (SERVER_IP = sunucu IP adresi):
SERVER_IP traefik.arr.local
SERVER_IP radarr.arr.local
SERVER_IP sonarr.arr.local
SERVER_IP prowlarr.arr.local
SERVER_IP bazarr.arr.local
SERVER_IP lidarr.arr.local
SERVER_IP qbittorrent.arr.local
SERVER_IP jellyfin.arr.local
SERVER_IP gluetun.arr.local
SERVER_IP auth.arr.local
127.0.0.1 qbittorrent.arr.local
127.0.0.1 jellyfin.arr.local
127.0.0.1 gluetun.arr.local
```

### 4️⃣ Container'ları Başlat
127.0.0.1 bazarr.arr.local
127.0.0.1 lidarr.arr.local
127.0.0.1 qbittorrent.arr.local
127.0.0.1 jellyfin.arr.local
127.0.0.1 gluetun.arr.local
```

### 5️⃣ Container'ları Başlat

```bash
cd ~/arr-stack

# Docker image'larını indir ve container'ları başlat
docker-compose pull
docker-compose up -d

# Container'ların başlamasını bekle (2-3 dakika)
```

### 6️⃣ Durumu Kontrol Et

```bash
# Container durumlarını göster
docker-compose ps

# Logları izle
docker-compose logs -f

# VPN bağlantısını kontrol et
docker exec gluetun wget -qO- http://localhost:10001/v1/publicip/ip
```

## 🌐 Erişim Adresleri

Container'lar hazır olduğunda şu adreslere erişebilirsin:

| Servis | URL | İlk Kullanım |
|--------|-----|--------------|
| **Authelia** | https://auth.arr.local | SSO/2FA login portal |
| **Traefik Dashboard** | http://127.0.0.1:8080 | Monitoring (localhost only) |
| **Radarr** | https://radarr.arr.local | İlk açılışta setup wizard |
| **Sonarr** | https://sonarr.arr.local | İlk açılışta setup wizard |
| **Prowlarr** | https://prowlarr.arr.local | İlk açılışta setup wizard |
| **Bazarr** | https://bazarr.arr.local | Radarr/Sonarr bağla |
| **Lidarr** | https://lidarr.arr.local | İlk açılışta setup wizard |
| **qBittorrent** | https://qbittorrent.arr.local | Admin/adminadmin |
| **Jellyfin** | https://jellyfin.arr.local | İlk açılışta setup wizard |
| **Gluetun Health** | https://gluetun.arr.local | VPN durumu |

**Tüm servisler Authelia SSO arkasında** (Jellyfin hariç - kendi auth sistemi)

## ⚙️ İlk Yapılandırma

### 1. qBittorrent
```
URL: https://qbittorrent.arr.local
Username: admin
Password: adminadmin (ilk girişte değiştir!)
```

### 2. Prowlarr (Indexer Yönetimi)
1. https://prowlarr.arr.local'i aç (Authelia login gerekli)
2. Settings → Apps → Add → Radarr/Sonarr ekle
   - Radarr URL: `http://radarr:7878`
   - Sonarr URL: `http://sonarr:8989`
3. Settings → Indexers → İstediğin torrent sitelerini ekle

### 3. Radarr (Film İndirme)
1. https://radarr.arr.local'i aç (Authelia login gerekli)
2. Settings → Download Clients → qBittorrent ekle
   - Host: `qbittorrent`
   - Port: `8080`
3. Settings → Indexers → Prowlarr'dan otomatik gelecek

### 4. Sonarr (Dizi İndirme)
1. https://sonarr.arr.local'i aç (Authelia login gerekli)
2. Settings → Download Clients → qBittorrent ekle
   - Host: `qbittorrent`
   - Port: `8080`
3. Settings → Indexers → Prowlarr'dan otomatik gelecek

### 5. Bazarr (Altyazı)
1. https://bazarr.arr.local'i aç (Authelia login gerekli)
2. Settings → Radarr → Add
   - URL: `http://radarr:7878`
3. Settings → Sonarr → Add
   - URL: `http://sonarr:8989`

### 6. Jellyfin (Media Server)
1. https://jellyfin.arr.local'i aç (kendi authentication sistemi)
2. İlk kurulum wizard'ını tamamla
3. Media Library ekle:
   - Movies: `/data/movies`
   - TV Shows: `/data/tvshows`
   - Music: `/data/music`

## 🔧 Özelleştirme

### Farklı Port Kullanma

Eğer 80 veya 8080 portları kullanılıyorsa:

```yaml
traefik:
  ports:
    - "8000:80"      # 80 yerine 8000
    - "8090:8080"    # 8080 yerine 8090
```

### Farklı Timezone

```yaml
environment:
  - TZ=America/New_York  # Kendi timezone'unu yaz
```

### Farklı PUID/PGID (Linux için önemli)

```bash
# Kendi user ID'ni öğren
id -u  # Örn: 1001
id -g  # Örn: 1001

# docker-compose.yaml'da değiştir:
environment:
  - PUID=1001
  - PGID=1001
```

## 🛠️ Sorun Giderme

### VPN Bağlantısı Kurulamıyor

```bash
# Gluetun loglarını kontrol et
docker-compose logs gluetun

# Yaygın sorunlar:
# 1. VPN credentials yanlış (service credentials kullan!)
# 2. VPN provider yanlış seçilmiş
# 3. SERVER_COUNTRIES yanlış yazılmış
```

### Container Healthy Olmuyor

```bash
# Specific container loglarına bak
docker-compose logs <servis_ismi>

# Healthcheck durumunu kontrol et
docker inspect <container_name> | grep -A 10 Health

# Container'ı restart et
docker-compose restart <servis_ismi>
```

### Subdomain'lere Erişilemiyor

```bash
# Hosts dosyasını kontrol et
cat /etc/hosts | grep arr.local

# DNS cache'i temizle (macOS)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# DNS cache'i temizle (Linux)
sudo systemd-resolve --flush-caches

# DNS cache'i temizle (Windows)
ipconfig /flushdns
```

### Port Çakışması

```bash
# Hangi portların kullanıldığını kontrol et
sudo lsof -i :80
sudo lsof -i :8080

# Çakışan uygulamayı durdur veya farklı port kullan
```

## 📊 Monitoring ve Bakım

### Container Durumlarını İzle

```bash
# Canlı loglar
docker-compose logs -f

# Disk kullanımı
docker system df

# Container kaynak kullanımı
docker stats
```

### Backup

```bash
# Config dosyalarını yedekle (config dizininde)
tar -czf config-backup-$(date +%Y%m%d).tar.gz .

# Data config'lerini yedekle
tar -czf data-backup-$(date +%Y%m%d).tar.gz ../rr_stack/data/*/config

# Backup'ı başka yere taşı
mv *-backup-*.tar.gz ~/Backups/
```

### Güncelleme

```bash
# Image'ları güncelle
docker-compose pull

# Container'ları yeniden başlat
docker-compose up -d

# Eski image'ları temizle
docker image prune -a
```

## 🎯 Gelişmiş Özellikler

### Otomatik Başlatma (macOS)

```bash
# LaunchAgent oluştur
cat > ~/Library/LaunchAgents/com.arrstack.startup.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.arrstack.startup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>cd ~/arr-stack && /usr/local/bin/docker-compose up -d</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.arrstack.startup.plist
```

### Otomatik Başlatma (Linux Systemd)

```bash
sudo nano /etc/systemd/system/arr-stack.service

# Şu içeriği ekle:
[Unit]
Description=ARR Stack Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/USERNAME/arr-stack
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target

# Etkinleştir
sudo systemctl enable arr-stack
sudo systemctl start arr-stack
```

## 📚 Ek Kaynaklar

- **Gluetun Wiki**: https://github.com/qdm12/gluetun/wiki
- **Traefik Docs**: https://doc.traefik.io/traefik/
- **Servarr Wiki**: https://wiki.servarr.com/
- **Jellyfin Docs**: https://jellyfin.org/docs/

## ✅ Kontrol Listesi

Kurulum tamamlandıktan sonra kontrol et:

- [ ] Docker Desktop çalışıyor
- [ ] VPN credentials doğru girildi
- [ ] Data klasörleri oluşturuldu
- [ ] Hosts dosyası güncellendi
- [ ] Container'lar başladı (`docker-compose ps`)
- [ ] VPN bağlantısı kuruldu (Gluetun health endpoint)
- [ ] Tüm subdomain'ler erişilebilir
- [ ] Prowlarr'da indexer'lar eklendi
- [ ] Radarr/Sonarr'da qBittorrent bağlı
- [ ] Jellyfin media library'leri eklendi

## 🎉 Tamamlandı!

Sisteminiz hazır! Film ve dizi indirmeye başlayabilirsiniz. İyi eğlenceler! 🍿
