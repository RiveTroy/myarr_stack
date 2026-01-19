# ARR Stack - Dizin Yapısı

Bu proje ayrı config ve runtime klasörleri kullanır.

## 📁 Klasör Yapısı

```
./Arr/
├── config/                    # Git repository (güncellenebilir)
│   ├── docker-compose.yaml   # Ana orchestration dosyası
│   ├── .env                  # VPN credentials (git ignore)
│   ├── .gitignore
│   ├── README.md
│   ├── QUICKSTART.md
│   ├── SECURITY.md
│   ├── quick_setup.sh        # Otomatik kurulum
│   ├── generate_certs.sh     # SSL cert generator
│   ├── setup_authelia.sh     # Authelia user creator
│   ├── setup_hosts.sh        # Hosts file updater
│   ├── monitor_and_restart.sh
│   ├── traefik/
│   │   ├── dynamic/
│   │   │   └── middleware.yml
│   │   └── certs/            # SSL certificates (git ignore)
│   │       ├── arr.local.crt
│   │       └── arr.local.key
│   └── authelia/
│       ├── configuration.yml
│       └── users_database.yml (git ignore)
│
└── rr_stack/                 # Runtime data (git ignore)
    └── data/                 # Docker volumes
        ├── radarr/
        │   ├── config/
        │   └── movies/
        ├── sonarr/
        │   ├── config/
        │   └── tvseries/
        ├── prowlarr/
        │   └── config/
        ├── bazarr/
        │   └── config/
        ├── lidarr/
        │   ├── config/
        │   └── music/
        ├── qbittorrent/
        │   ├── config/
        │   └── downloads/
        ├── jellyfin/
        │   └── config/
        └── gluetun/
```

## 🎯 Avantajları

### 1. **Temiz Git Repository**
- Config dosyaları versiyon kontrolünde
- Runtime data (filmler, diziler, indirmeler) git'e girmez
- `git pull` yapınca sadece config güncellenir

### 2. **Kolay Backup**
```bash
# Config backup
cd ~/Documents/Arr/config
tar -czf config-backup-$(date +%Y%m%d).tar.gz .

# Data backup (seçici)
cd ~/Documents/Arr/rr_stack
tar -czf data-backup-$(date +%Y%m%d).tar.gz data/*/config
```

### 3. **Kolay Taşıma**
```bash
# Yeni sisteme sadece config'i taşı
scp -r ~/Documents/Arr/config user@newhost:~/Arr/

# rr_stack klasörü otomatik oluşacak
```

### 4. **Güncelleme Kolaylığı**
```bash
cd ~/Documents/Arr/config
git pull origin main
docker-compose pull
docker-compose up -d
# rr_stack hiç etkilenmez
```

## 🚀 Kurulum

### Yeni Kurulum

```bash
# 1. Ana klasörü oluştur
mkdir -p ~/Documents/Arr

# 2. Config'i klonla
cd ~/Documents/Arr
git clone https://github.com/RiveTroy/myarr_stack.git config

# 3. Config dizinine geç
cd config

# 4. .env dosyasını oluştur
cp .env.example .env
nano .env  # VPN credentials gir

# 5. Otomatik kurulum (rr_stack klasörünü otomatik oluşturur)
./quick_setup.sh
```

Script otomatik olarak:
- ✅ `../rr_stack/data/` klasörlerini oluşturur
- ✅ SSL sertifikalarını `traefik/certs/` altına koyar
- ✅ Authelia kullanıcısı oluşturur
- ✅ Docker container'ları başlatır

### Manuel Kurulum

```bash
cd ~/Documents/Arr/config

# 1. rr_stack klasörünü oluştur
mkdir -p ../rr_stack/data/{radarr,sonarr,prowlarr,bazarr,lidarr,qbittorrent,jellyfin,gluetun}/{config,data}
mkdir -p ../rr_stack/data/radarr/movies
mkdir -p ../rr_stack/data/sonarr/tvseries
mkdir -p ../rr_stack/data/lidarr/music
mkdir -p ../rr_stack/data/qbittorrent/downloads

# 2. Hosts dosyasını güncelle
sudo ./setup_hosts.sh

# 3. SSL sertifikası oluştur
./generate_certs.sh

# 4. Authelia kullanıcısı oluştur
./setup_authelia.sh

# 5. Docker başlat
docker-compose up -d
```

## 🔧 Volume Path'leri

docker-compose.yaml'daki tüm volume'lar relative path kullanır:

```yaml
volumes:
  - ../rr_stack/data/radarr/config:/config
  - ../rr_stack/data/radarr/movies:/movies
  - ../rr_stack/data/qbittorrent/downloads:/downloads
```

## 📊 Disk Kullanımı

```bash
# Config boyutu (scriptler, yaml'lar)
du -sh ~/Documents/Arr/config
# ~50MB

# Runtime data boyutu (filmler, diziler, config'ler)
du -sh ~/Documents/Arr/rr_stack
# Büyük (medya içeriğine bağlı)
```

## 🗑️ Temizlik

```bash
# Sadece data'yı sil (config kalsın)
rm -rf ~/Documents/Arr/rr_stack

# Yeniden başlat
cd ~/Documents/Arr/config
./quick_setup.sh
```

## 🔄 Güncelleme Workflow

```bash
cd ~/Documents/Arr/config

# Git güncelleme
git pull origin main

# Docker image'ları güncelle
docker-compose pull

# Restart
docker-compose up -d

# rr_stack/data/ hiç etkilenmez
```

## ⚠️ Önemli Notlar

1. **Her zaman config dizininde çalış:**
   ```bash
   cd ~/Documents/Arr/config
   docker-compose up -d  # Doğru ✓
   ```

2. **rr_stack'i asla manuel düzenleme:**
   - Docker otomatik yönetir
   - Sadece backup için kullan

3. **Git operations:**
   ```bash
   cd ~/Documents/Arr/config
   git status  # Sadece config değişikliklerini gösterir
   ```

4. **.env dosyası:**
   - `config/.env` konumunda
   - Git'e girmez (.gitignore)
   - Her sistemde yeniden oluştur

5. **SSL Sertifikaları:**
   - `config/traefik/certs/` konumunda
   - Git'e girmez
   - `generate_certs.sh` ile oluştur
