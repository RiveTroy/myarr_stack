# ARR Stack - Otomatik Restart ve Monitoring Rehberi

## 🔄 Otomatik Restart Özellikleri

### ✅ Yapılan İyileştirmeler

#### 1. **Restart Policy: `always`**
Tüm container'lar artık `restart: always` kullanıyor:
- Sistem restart atsa bile otomatik başlayacaklar
- Container crash olsa bile Docker otomatik restart edecek
- `unless-stopped` yerine `always` daha güçlü

#### 2. **Healthcheck'ler Eklendi**
Her servis için healthcheck mekanizması:
- **Interval**: 30 saniye (ne sıklıkta kontrol edilecek)
- **Timeout**: 10 saniye (yanıt süresi)
- **Retries**: 10 (başarısız denemeler - toplam 360 saniye tolerans)
- **Start Period**: 60 saniye (ilk başlangıçta bekleme)

#### 3. **Dependency Chain (Bağımlılık Zinciri)**
Servisler doğru sırada başlayacak:
```
1. Gluetun (VPN) → healthy
2. Traefik (Reverse Proxy) → healthy
3. Diğer tüm servisler → healthy olmaları bekleniyor
```

#### 4. **Gelişmiş Gluetun Yapılandırması**
- `HEALTH_VPN_DURATION_INITIAL=60s`: İlk VPN kontrolü 60 saniye bekliyor
- `HEALTH_VPN_DURATION_ADDITION=5s`: Her denemede 5 saniye daha ekliyor
- VPN bağlantısı kopmaz, kopsa bile otomatik düzeliyor

## 🔍 Manuel Monitoring

### Container Durumlarını Kontrol Et

```bash
cd ~/arr-stack  # veya projenin bulunduğu klasör

# Tüm container'ların durumu
docker-compose ps

# Health durumları
docker ps --format "table {{.Names}}\t{{.Status}}"

# Otomatik monitoring script'i
chmod +x monitor_and_restart.sh
./monitor_and_restart.sh
```

## 🤖 Otomatik Monitoring Kurulumu

### 1. Cron Job ile Otomatik Kontrol (Her 5 dakikada)

```bash
# Crontab'ı aç
crontab -e

# Şu satırı ekle (her 5 dakikada bir çalışır)
# NOT: Aşağıdaki path'i kendi kurulum klasörünüzle değiştirin
*/5 * * * * ~/arr-stack/monitor_and_restart.sh >> ~/arr-stack/cron.log 2>&1
```

### 2. LaunchAgent ile macOS Startup'ta Otomatik Başlatma

Sistem açılışında otomatik başlatmak için:

```bash
# LaunchAgent dosyası oluştur
# NOT: Aşağıdaki path'leri kendi kurulum klasörünüzle değiştirin
cat > ~/Library/LaunchAgents/com.arrstack.monitor.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.arrstack.monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/KULLANICI_ADINIZ/arr-stack/monitor_and_restart.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>StandardOutPath</key>
    <string>/Users/KULLANICI_ADINIZ/arr-stack/monitor.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/KULLANICI_ADINIZ/arr-stack/monitor_error.log</string>
</dict>
</plist>
EOF

# LaunchAgent'ı yükle
launchctl load ~/Library/LaunchAgents/com.arrstack.monitor.plist

# Kontrol et
launchctl list | grep arrstack
```

### 3. Docker Compose Otomatik Başlatma

macOS'ta Docker Desktop açıldığında container'ları otomatik başlatmak için:

```bash
# Docker Desktop'ın başlangıçta açılmasını ayarla
# Docker Desktop → Settings → General → "Start Docker Desktop when you log in"

# Ayrıca şu LaunchAgent'ı da ekleyebilirsin:
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
        <string>cd /Users/onurakarsu/Documents/RR_STACK && /usr/local/bin/docker-compose up -d</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/onurakarsu/Documents/RR_STACK/startup.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/onurakarsu/Documents/RR_STACK/startup_error.log</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.arrstack.startup.plist
```

## 📊 Monitoring Script Özellikleri

`monitor_and_restart.sh` scripti şunları yapar:

1. **Health Check**: Tüm container'ların sağlık durumunu kontrol eder
2. **Auto Restart**: Sağlıksız container'ları otomatik restart eder
3. **VPN Kontrolü**: Gluetun'un VPN bağlantısını kontrol eder
4. **Logging**: Tüm işlemleri `monitor.log` dosyasına kaydeder
5. **Colored Output**: Terminal çıktısında renkli gösterimler

## 🧪 Test Senaryoları

### 1. Tek Container'ı Crash'le ve İzle

```bash
# Radarr'ı durdur
docker stop radarr

# 30 saniye bekle (restart policy devreye girer)
sleep 30

# Durumu kontrol et
docker ps | grep radarr
```

### 2. VPN Bağlantısını Kontrol Et

```bash
# VPN IP'yi kontrol et
docker exec gluetun wget -qO- http://localhost:10001/v1/publicip/ip

# VPN'in gerçekten çalıştığını doğrula (kendi IP'n değil)
curl ifconfig.me
```

### 3. Tüm Sistemi Restart Et

```bash
# Container'ları durdur
docker-compose down

# Sistemi restart et
sudo reboot

# Sistem açıldıktan sonra kontrol et (2-3 dakika bekle)
docker-compose ps
./monitor_and_restart.sh
```

### 4. Rassal Crash Simülasyonu

```bash
# Random container'ları crash'le
docker kill sonarr prowlarr bazarr

# Monitoring script'i çalıştır
./monitor_and_restart.sh

# Durumu kontrol et
docker-compose ps
```

## 📈 Log Takibi

### Real-time Container Logs

```bash
# Tüm container'ların logları
docker-compose logs -f

# Sadece restart olayları
docker-compose logs -f | grep -i restart

# Sadece healthcheck hataları
docker-compose logs -f | grep -i health
```

### Monitoring Script Logları

```bash
# Son 50 satır
tail -50 /Users/onurakarsu/Documents/RR_STACK/monitor.log

# Canlı takip
tail -f /Users/onurakarsu/Documents/RR_STACK/monitor.log

# Sadece hataları göster
grep -i "unhealthy\|failed\|error" /Users/onurakarsu/Documents/RR_STACK/monitor.log
```

## 🚨 Sorun Giderme

### Container Sürekli Restart Oluyor

```bash
# Container'ın loglarını kontrol et
docker-compose logs --tail=100 <container_name>

# Healthcheck durumunu kontrol et
docker inspect <container_name> | grep -A 10 Health

# Manuel olarak durdur ve tekrar başlat
docker-compose stop <container_name>
docker-compose rm -f <container_name>
docker-compose up -d <container_name>
```

### VPN Bağlantısı Kurulmuyor

```bash
# Gluetun loglarını kontrol et
docker-compose logs gluetun | tail -100

# NordVPN credentials'ları kontrol et
docker-compose config | grep -A 5 OPENVPN

# Gluetun'u temiz başlat
docker-compose stop gluetun
docker-compose rm -f gluetun
docker-compose up -d gluetun

# VPN durumunu kontrol et (60 saniye bekle)
sleep 60
docker exec gluetun wget -qO- http://localhost:10001/v1/publicip/ip
```

### Traefik Servisleri Görmüyor

```bash
# Traefik dashboard'u kontrol et
open http://traefik.arr.local:8080

# Network bağlantılarını kontrol et
docker network inspect rr_stack_arr_network

# Container'ların label'larını kontrol et
docker inspect radarr | grep traefik
```

## ✅ Otomatik Restart Kontrol Listesi

Sistem restart attıktan sonra şunları kontrol et:

- [ ] Docker Desktop açıldı mı?
- [ ] `/etc/hosts` dosyası korundu mu? (`cat /etc/hosts | grep arr.local`)
- [ ] Gluetun başladı mı? (`docker ps | grep gluetun`)
- [ ] VPN bağlantısı kuruldu mu? (`docker exec gluetun wget -qO- http://localhost:10001/v1/publicip/ip`)
- [ ] Traefik başladı mı? (`curl -I http://traefik.arr.local:8080`)
- [ ] Tüm arr servisleri healthy mi? (`./monitor_and_restart.sh`)
- [ ] Domain'ler çalışıyor mu? (http://radarr.arr.local)

## 🎯 Özet

**Evet, artık manual müdahale gerekmeden erişebilirsin!**

✅ Sistem restart atsa → Container'lar otomatik başlayacak (`restart: always`)  
✅ Container crash olsa → Docker otomatik restart edecek  
✅ VPN kopsa → Healthcheck algılayıp restart edecek  
✅ Rassal sırayla crash → Dependency chain doğru sırada başlatacak  
✅ Monitoring → Cron job ile otomatik kontrol (isteğe bağlı)

**Tek yapman gereken**: Docker Desktop'ı başlangıçta otomatik açılacak şekilde ayarlamak. Geri kalanı tamamen otomatik! 🎉
