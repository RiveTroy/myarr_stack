# AdGuard Home Kurulumu

AdGuard Home tüm ev ağın için DNS sunucusu ve reklam engelleyici olarak çalışır.

## 🚀 Hızlı Kurulum

### 1. Port Ayarı (Önemli!)

**macOS kullanıyorsan:**
- Port 53 ve 5353 kullanımda (mDNSResponder/Bonjour)
- docker-compose-adguard.yaml'da **5380:53** olarak bırak (varsayılan)
- DNS ayarlarında port **5380** kullanacaksın

**Linux sunucuda:**
- docker-compose-adguard.yaml'ı düzenle:
```yaml
ports:
  - "53:53/tcp"    # 5380 yerine 53
  - "53:53/udp"    # 5380 yerine 53
```

### 2. AdGuard Home'u Başlat

```bash
docker-compose -f docker-compose-adguard.yaml up -d
```

### 3. İlk Yapılandırma

Tarayıcıdan `http://SERVER_IP:3000` adresine git:

1. **Karşılama Ekranı**: "Get Started" tıkla
2. **Admin Interface**: Port 3000 veya 80 seç (3000 önerilir - port çakışması olmasın)
3. **DNS Server**: 
   - **Linux**: Port 53 olarak bırak
   - **macOS**: Port 5380 yaz (macOS portları 53 ve 5353 kullanıyor)
4. **Admin Kullanıcısı**: Kullanıcı adı ve güçlü şifre belirle
5. **Kurulum Tamamlandı**: Dashboard'a yönlendirileceksin

### 3. DNS Rewrites Ekle (Arr Stack için)

Dashboard'da: **Filters → DNS rewrites → Add DNS rewrite**

**Wildcard yöntemi** (önerilen):
```
Domain: *.arr.local
Answer: 192.168.1.X  (sunucu IP'n)
```

**Veya tek tek ekle**:
```
radarr.arr.local → 192.168.1.X
sonarr.arr.local → 192.168.1.X
prowlarr.arr.local → 192.168.1.X
bazarr.arr.local → 192.168.1.X
lidarr.arr.local → 192.168.1.X
qbittorrent.arr.local → 192.168.1.X
jellyfin.arr.local → 192.168.1.X
gluetun.arr.local → 192.168.1.X
auth.arr.local → 192.168.1.X
traefik.arr.local → 192.168.1.X
```

### 4. Reklam Engelleme Filtreleri (Opsiyonel ama Önerilen)

**Filters → DNS blocklists → Add blocklist**

Popüler listeler:
- **AdGuard DNS filter**: `https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt`
- **Steven Black's Unified**: `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`
- **1Hosts (Pro)**: `https://o0.pages.dev/Pro/adblock.txt`

Türkçe odaklı:
- **AdGuard Turkish**: `https://filters.adtidy.org/extension/chromium/filters/13.txt`

### 5. Router'da DNS Ayarla

**Yöntem 1: Router DHCP Ayarları** (tüm cihazlar otomatik):
- Router admin paneline gir (genelde 192.168.1.1)
- DHCP ayarları bulun
- Primary DNS: `192.168.1.X` (AdGuard Home IP)
- Secondary DNS: `8.8.8.8` (fallback için)

**Yöntem 2: Cihaz bazlı ayar** (manuel):
- WiFi ayarlarına git
- DNS ayarlarını manuel yap
- DNS: `192.168.1.X`

### 6. Test Et

Terminal'den:
```bash
# DNS çözümleme testi
nslookup radarr.arr.local 192.168.1.X

# Reklam engelleme testi
nslookup ads.google.com 192.168.1.X
```

Tarayıcıdan:
- `https://radarr.arr.local` - Arr stack'e erişim
- `http://192.168.1.X:3000` - AdGuard Home dashboard

## 📱 Cihazlardan Kullanım

Router DNS'ini ayarladıktan sonra:

- **Telefon**: `https://jellyfin.arr.local` direkt açılır
- **Tablet**: `https://radarr.arr.local` çalışır
- **TV**: `https://jellyfin.arr.local` erişilebilir
- **Laptop**: Tüm domain'ler çözülür

**Hiçbir cihazda hosts dosyası düzenlemeye gerek yok!**

## 🔧 Ayarlar

### Upstream DNS Servers

**Settings → DNS settings → Upstream DNS servers**

Önerilen upstream'ler:
```
https://dns.cloudflare.com/dns-query
https://dns.google/dns-query
tls://dns.quad9.net
```

### Cache Ayarları

- **Cache size**: 8 MB (varsayılan)
- **Cache TTL override**: Disable (varsayılan)

### Query Log

- **Logs configuration**: 90 gün (ayarlanabilir)
- **Statistics interval**: 90 gün

## 🛡️ Güvenlik

### HTTPS (Opsiyonel)

Web UI için HTTPS aktif etmek istersen:

1. **Settings → Encryption settings**
2. Let's Encrypt veya kendi sertifikan kullan
3. Port 443 aktif olur

### Rate Limiting

**Settings → DNS settings → Rate limit**:
- 30 requests per second per IP (varsayılan)

## 📊 Monitoring

Dashboard'da:
- **Query log**: Tüm DNS sorguları
- **Statistics**: Engellenen/izin verilen sorgular
- **Top clients**: En aktif cihazlar
- **Top domains**: En çok kullanılan domain'ler

## 🔄 Güncelleme

```bash
docker-compose -f docker-compose-adguard.yaml pull
docker-compose -f docker-compose-adguard.yaml up -d
```

## 🧹 Temizlik

AdGuard Home'u kaldırmak için:

```bash
docker-compose -f docker-compose-adguard.yaml down
rm -rf ./adguardhome
```

Router DNS ayarlarını eski haline getir.

## 🆘 Sorun Giderme

### DNS çalışmıyor
```bash
# AdGuard Home loglarını kontrol et
docker logs adguardhome

# Port 53 kullanımda mı?
sudo lsof -i :53
```

macOS'ta systemd-resolved veya dnsmasq çalışıyor olabilir:
```bash
# macOS'ta mDNSResponder'ı durdur (dikkatli!)
sudo killall -HUP mDNSResponder
```

### Web UI açılmıyor
```bash
# Container çalışıyor mu?
docker ps | grep adguard

# Port 3000 kullanımda mı?
lsof -i :3000
```

### Reklam engelleme çalışmıyor
- Filtrelerin güncel olduğundan emin ol (Filters → Update filters)
- Query log'da sorgular görünüyor mu?
- Cihazın DNS ayarları doğru mu?

## 💡 İpuçları

1. **Mobile cihazlar için**: Router DNS ayarı en kolay yöntem
2. **Misafir WiFi**: Ayrı DNS kullan (reklam engelleme opsiyonel)
3. **Bazı siteler bozuluyorsa**: Allowlist'e ekle (Filters → Custom filtering rules)
4. **Parental control**: AdGuard Home'da yerleşik parental control var
5. **Safe Search**: Google/Bing/YouTube için safe search zorla

## 🔗 Faydalı Linkler

- [AdGuard Home GitHub](https://github.com/AdguardTeam/AdGuardHome)
- [Filtre Listeleri](https://filterlists.com/)
- [Safe Browsing Test](https://testsafebrowsing.com/)
- [DNS Leak Test](https://dnsleaktest.com/)
