# ARR Stack - Hızlı Başlangıç

## 🚀 Otomatik Kurulum (3 Dakika) ⚡

**Tam Otomatik - Tek Script ile Her Şey:**

```bash
# 1. Ana klasörü oluştur
mkdir -p ~/Documents/Arr

# 2. Config'i klonla
cd ~/Documents/Arr
git clone https://github.com/RiveTroy/myarr_stack.git config

# 3. Config dizinine geç
cd config

# 4. .env dosyası oluştur ve VPN bilgilerini düzenle
cp .env.example .env
nano .env  # OPENVPN_USER ve OPENVPN_PASSWORD'u değiştir

# 5. Otomatik kurulum başlat (sudo şifresi isteyecek)
chmod +x quick_setup.sh
./quick_setup.sh
```

**Script otomatik olarak yapar:**
- ✅ .env dosyası oluşturur (AUTHELIA_JWT_SECRET, AUTHELIA_SESSION_SECRET, AUTHELIA_STORAGE_ENCRYPTION_KEY otomatik generate edilir)
- ✅ Hosts dosyasını günceller (auth.arr.local dahil)
- ✅ SSL wildcard sertifikası oluşturur (traefik/certs/ altına)
- ✅ Authelia SSO kullanıcısı oluşturur (sizden kullanıcı adı/şifre ister)
- ✅ ../rr_stack/data/ klasörlerini oluşturur
- ✅ Docker container'ları başlatır (Traefik v3 + Gluetun VPN)
- ✅ VPN kill switch'i aktifleştirir
- ✅ HTTPS/TLS yapılandırmasını yapar (TLS 1.2+ zorunlu)

**macOS Kullanıcıları:** Docker socket path otomatik tanınır (`/Users/<username>/.docker/run/docker.sock`)

**İlk Erişim:** `https://radarr.arr.local` → Authelia login → Servis

---

## 🛠️ Manuel Kurulum (10 Dakika)

```bash
# 1. Ana klasörü oluştur
mkdir -p ~/Documents/Arr
cd ~/Documents/Arr

# 2. Config'i klonla
git clone https://github.com/RiveTroy/myarr_stack.git config
cd config

# 3. .env dosyası oluştur ve VPN bilgilerini düzenle
cp .env.example .env
nano .env  # OPENVPN_USER ve OPENVPN_PASSWORD'u değiştir

# 4. Hosts dosyasını güncelle
chmod +x setup_hosts.sh
sudo ./setup_hosts.sh

# 5. SSL Sertifikası oluştur
chmod +x generate_certs.sh
./generate_certs.sh

# 6. Sertifikayı güvenilir yap (macOS)
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain ./traefik/certs/arr.local.crt

# 6. Authelia kullanıcısı oluştur
chmod +x setup_authelia.sh
./setup_authelia.sh

# 7. Data klasörlerini oluştur
mkdir -p ../rr_stack/data/{radarr,sonarr,prowlarr,bazarr,lidarr,qbittorrent,jellyfin,gluetun}/{config,data}
mkdir -p ../rr_stack/data/{radarr/movies,sonarr/tvseries,lidarr/music,qbittorrent/downloads}

# 10. Docker başlat
docker-compose up -d
# Şu satırları ekle:
# 127.0.0.1 *.arr.local (tüm domain'leri)

# 4. Data klasörlerini oluştur
mkdir -p data/{radarr,sonarr,prowlarr,bazarr,lidarr,qbittorrent,jellyfin,gluetun}/{config,data}
mkdir -p data/{radarr/movies,sonarr/tvseries,lidarr/music,qbittorrent/downloads}

# 5. Başlat!
docker-compose up -d
```

## 📱 Erişim URL'leri (HTTPS + Authelia)

| Servis | URL | Auth | Port |
|--------|-----|------|------|
| **Authelia** | https://auth.arr.local | - | 9091 |
| Traefik Dashboard | http://127.0.0.1:8080 | ❌ | 8080 (localhost only) |
| Radarr | https://radarr.arr.local | ✅ | 7878 |
| Sonarr | https://sonarr.arr.local | ✅ | 8989 |
| Prowlarr | https://prowlarr.arr.local | ✅ | 9696 |
| Bazarr | https://bazarr.arr.local | ✅ | 6767 |
| Lidarr | https://lidarr.arr.local | ✅ | 8686 |
| qBittorrent | https://qbittorrent.arr.local | ✅ | 8080 |
| Jellyfin | https://jellyfin.arr.local | ❌ (own auth) | 8096 |
| Gluetun Health | https://gluetun.arr.local | ✅ | 10001 |
| FlareSolverr | - | - | 8191 (internal) |

**İlk Erişim Akışı:**
1. Herhangi bir servise git (örn: https://radarr.arr.local)
2. Otomatik olarak https://auth.arr.local'e yönlendirilirsin
3. Kullanıcı adı/şifre ile giriş yap
4. İstediğin servise erişim sağla

**Not:** Jellyfin kendi authentication sistemini kullanır (TV/mobil erişim için)

## 🌐 Uzaktan Erişim (Tailscale + AdGuard Home)

**Tailscale ile evdeki sunucuya her yerden erişim:**

1. **Tailscale kur:**
   ```bash
   # macOS
   brew install tailscale
   sudo tailscale up
   
   # Linux
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```

2. **Mac Mini'yi exit node yap:**
   ```bash
   sudo tailscale up --advertise-exit-node --hostname=macmini
   ```

3. **AdGuard Home DNS kurulumu:** (opsiyonel ama önerilen)
   - DNS rewrites ile `*.arr.local` → Tailscale IP
   - Detaylı kurulum: [ADGUARD_SETUP.md](ADGUARD_SETUP.md)

4. **Telefondan/laptoptan erişim:**
   - Tailscale uygulamasında exit node'u aktifleştir
   - `https://radarr.arr.local` → Authelia login → Servis

## 🔧 Temel Komutlar

```bash
# Container'ları başlat
docker-compose up -d

# Container'ları durdur
docker-compose down

# Durumu kontrol et
docker-compose ps

# Logları izle
docker-compose logs -f

# VPN kill switch kontrolü (FIREWALL=on)
docker exec gluetun wget -qO- http://localhost:10001/health

# Tek servisin logunu izle
docker-compose logs -f radarr

# Container'ı restart et
docker-compose restart radarr

# VPN IP'sini kontrol et
docker exec gluetun wget -qO- http://localhost:10001/v1/publicip/ip

# Tüm container'ları güncelle
docker-compose pull && docker-compose up -d
```
### 1️⃣ Authelia'da Login
- https://auth.arr.local
- Setup script'inde oluşturduğun kullanıcı adı/şifre

### 2️⃣ qBittorrent (admin/adminadmin)
- https://qbittorrent.arr.local → Authelia login
- Tools → Options → Web UI → Change password
- Connection → Port: 6881 (already configured)

### 3️⃣ Prowlarr (Indexer Management)
- https://prow Özellikleri

**Aktif Korumalar:**
- ✅ **HTTPS Only** - TLS 1.2+ zorunlu, HTTP → HTTPS redirect
- ✅ **Authelia SSO** - Tek giriş portalı, 2FA/TOTP destekli
- ✅ **VPN Kill Switch** - VPN düşerse torrent trafiği DURUR
- ✅ **Network Access** - Ev ağındaki tüm cihazlar erişebilir (güvenli)
- ✅ **Security Headers** - HSTS, CSP, X-Frame-Options, XSS Protection
- ✅ **Rate Limiting** - Brute-force koruması (100 req/min)
- ✅ **Container Hardening** - no-new-privileges, read-only mounts
- ✅ **Session Management** - 1 saat aktif, 5 dakika inactivity timeout

**VPN Credentials (NordVPN):**
```bash
# .env dosyasını düzenle
nano .env

# Service credentials kullan (normal şifre değil!)
OPENVPN_USER=your_nordvpn_service_username
OPENVPN_PASSWORD=your_nordvpn_service_password

# Al: https://my.nordvpn.com/dashboard/nordaccount/
```

**2FA Aktifleştirme (Opsiyonel):**
1. https://auth.arr.local → Login
2. Settings → Two-Factor Authentication
3. QR kodu Google Authenticator/Authy ile tara
4. TOTP kodunu doğrulaame as Radarr configuration

### 6️⃣ Lidarr (Music)
- https://lidarr.arr.local
- Same as Radarr configuration

### 7️⃣ Bazarr (Subtitles)
- https://bazarr.arr.local
- Settings → Radarr → Add (URL: `http://radarr:7878`)
- Settings → Sonarr → Add (URL: `http://sonarr:8989`)

### 8️⃣ Jellyfin (Media Server)
- https://jellyfin.arr.local (kendi auth'u var)
- Add Libraries:
  - Movies: `/data/movies`
  - TV Shows: `/data/tvshows`
  - Music: `/data/music`larr ile senkronize et
4. **Sonarr** → qBittorrent'i bağla, Prowlarr ile senkronize et
5. **Bazarr** → Radarr ve Sonarr'ı bağla
6. **Jellyfin** → Media library'leri ekle

## 🔒 Güvenlik

### SSL Sertifika Uyarısı
**Sorun:** Tarayıcı "Your connection is not private" diyor

**Çözüm:**
```bash
# Sertifikayı sisteme güvenilir yap
# macOS:
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain ./traefik/certs/arr.local.crt

# Linux (Debian/Ubuntu):
sudo cp ./traefik/certs/arr.local.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Tarayıcıyı yeniden başlat
```

### Authelia Redirect Loop
**Sorun:** auth.arr.local ile servis arasında sonsuz döngü

**Çözüm:**
```bash
# Tarayıcı cookies temizle (*.arr.local)
# Session secret kontrolü
grep "session:" authelia/configuration.yml

# Authelia restart
docker-compose restart authelia
```

### VPN Çalışmıyor
**Sorun:** Torrent indirilmiyor, VPN bağlanamıyor

**Çözüm:**
```bash
# Gluetun logları
docker-compose logs

# VPN Credentials düzenle
OPENVPN_USER=your_nordvpn_service_username
OPENVPN_PASSWORD=your_nordvpn_service_password

# NordVPN credentials al:
# https://my.nordvpn.com/dashboard/nordaccount/
```

## 🐛 Sorun Giderme

```bash
# VPN çalışmıyor
docker-compose logs gluetun
docker-compose restart gluetun

# Servis healthy olmuyor
docker inspect radarr | grep -A 10 Health
docker-compose restart radarr

# Domain'e erişilemiyor
cat /etc/hosts | grep arr.local
sudo dscacheutil -flushcache  # macOS
sudo systemd-resolve --flush-caches  # Linux

# Port çakışması
sudo lsof -i :80
sudo lsof -i :8080
```

## 📊 Monitoring

```bash
# Container kaynak kullanımı
docker stats

# Disk kullanımı
docker system df
**Donanım:**
- ✅ Docker Desktop yüklü ve çalışır durumda
- ✅ 8GB+ RAM (16GB önerilir)
- ✅ 50GB+ boş disk alanı
- ✅ CPU: 4+ core (2 core minimum)

**YazıGitHub'dan Kurulum Kontrolü

**Repository:** https://github.com/RiveTroy/myarr_stack

**Gerekli Dosyalar (hepsi mevcut):**
- ✅ docker-compose.yaml
- ✅ .env.example
- ✅ README.md
- ✅ SECURITY.md
- ✅ QUICKSTART.md
- ✅ quick_setup.sh (otomatik kurulum)
- ✅ generate_certs.sh (SSL)
- ✅ setup_authelia.sh (SSO)
- ✅ setup_hosts.sh (hosts file)
- ✅ monitor_and_restart.sh (healthcheck)
- ✅ traefik/dynamic/middleware.yml
- ✅ authelia/configuration.yml

**Klonla ve Başla:**
```bash
git clone https://github.com/RiveTroy/myarr_stack.git
cd myarr_stack
cp .env.example .env
nano .env  # VPN credentials
./quick_setup.sh
```
- ✅ Self-signed SSL sertifikasına güvenme yetkisi
- ✅ Docker daemon çalışır durumdaurumu
docker-compose ps
```

## 💾 Backup

```bash
# Config'leri yedekle
tar -czf arr-backup-$(date +%Y%m%d).tar.gz data/*/config

# Restore
tar -xzf arr-backup-20260117.tar.gz
```

## 🔄 Güncelleme

```bash
# Image'ları güncelle
docker-compose pull

# Container'ları yeniden başlat
docker-compose up -d

# Eski imageKurulum**: [README.md](README.md)
- **Güvenlik Rehberi**: [SECURITY.md](SECURITY.md)
- **Restart/Monitoring**: [RESTART_REHBERI.md](RESTART_REHBERI.md)

---

## ✅ Kurulum Sonrası Checklist

- [ ] Tüm container'lar çalışıyor: `docker-compose ps`
- [ ] VPN bağlı: `docker exec gluetun wget -qO- http://localhost:10001/v1/publicip/ip`
- [ ] SSL sertifikası güvenilir (tarayıcı uyarısı yok)
- [ ] Authelia login çalışıyor: https://auth.arr.local
- [ ] Servisler Authelia arkasında: https://radarr.arr.local → Login gerekli
- [ ] Jellyfin erişilebilir: https://jellyfin.arr.local (kendi auth'u)
- [ ] qBittorrent şifresi değiştirildi
- [ ] Prowlarr indexer'ları eklendi
- [ ] Radarr/Sonarr qBittorrent'e bağlı
- [ ] VPN kill switch aktif: `FIREWALL=on` (docker-compose.yaml)

**🎉 Kurulum Tamamlandı! İyi kullanımlar!**

---

**⚠️ Önemli Notlar:**
1. `.env` dosyasını asla GitHub'a pushlamayın
2. Authelia şifrelerini güçlü tutun
3. 2FA'yı aktifleştirin (opsiyonel ama önerilen)
4. Haftalık update kontrolü: `docker-compose pull && docker-compose up -d`
5. VPN connection'ı düzenli kontrol edin
- ✅ 8GB+ RAM (16GB önerilir)
- ✅ 50GB+ Disk
- ✅ NordVPN hesabı (veya başka VPN)
- ✅ /etc/hosts düzenlenmiş

## 🎯 Paylaşılacak Dosyalar

Bir arkadaşına göndermek için bu dosyaları paylaş:

1. **docker-compose.yaml** ← Ana dosya
2. **README.md** ← Detaylı kurulum rehberi
3. **.env.example** ← VPN bilgileri için template
4. **quick_setup.sh** ← Otomatik kurulum scripti
5. **setup_hosts.sh** ← Hosts dosyası güncelleyici

**Gönderme öncesi kontrol**:
- [ ] VPN credentials silinmiş mi? (`<your_nordvpn_username>` olmalı)
- [ ] Path'ler relative mi? (`./data/...` olmalı)
- [ ] .gitignore eklenmiş mi?

## 📚 Daha Fazla Bilgi

- **Detaylı Rehber**: README.md
- **Restart Rehberi**: RESTART_REHBERI.md
- **Monitoring**: monitor_and_restart.sh

---

**İyi kullanımlar! 🚀**
