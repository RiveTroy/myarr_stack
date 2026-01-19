# 🔒 ARR Stack - Security Guide

## Overview

This ARR Stack implementation follows enterprise-grade security best practices:

- ✅ **HTTPS-Only** with TLS 1.2+ encryption
- ✅ **Network Access** - Controlled access for home network devices
- ✅ **Single Sign-On (SSO)** with Authelia authentication portal
- ✅ **Two-Factor Authentication (2FA)** support with TOTP
- ✅ **Security Headers** (HSTS, X-Frame-Options, CSP, etc.)
- ✅ **Rate Limiting** to prevent brute-force attacks
- ✅ **VPN Protection** for all torrent traffic via Gluetun
- ✅ **Secure Secrets Management** with .env files

---

## 🚀 Quick Security Setup

### 1. Generate SSL Certificates

```bash
chmod +x generate_certs.sh
./generate_certs.sh
```

**Trust the certificate on your system:**

```bash
# macOS
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  ./traefik/certs/arr.local.crt

# Linux (Debian/Ubuntu)
sudo cp ./traefik/certs/arr.local.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

### 2. Setup Authelia Authentication

```bash
chmod +x setup_authelia.sh
./setup_authelia.sh
```

Follow the prompts to create an admin user.

**Note:** Authelia encryption keys (JWT_SECRET, SESSION_SECRET, STORAGE_ENCRYPTION_KEY) are **automatically generated** by `quick_setup.sh` and stored in `.env` file. No manual configuration needed!

### 3. Start Secure Stack

```bash
docker-compose up -d
```

**All encryption keys are automatically generated** - check `.env` file for:
- `AUTHELIA_JWT_SECRET`
- `AUTHELIA_SESSION_SECRET`
- `AUTHELIA_STORAGE_ENCRYPTION_KEY`

---

## 🔐 Authentication Flow

1. Access any service: `https://radarr.arr.local`
2. Redirected to: `https://auth.arr.local`
3. Login with your username/password
4. *(Optional)* Enter 2FA TOTP code
5. Redirected back to the original service

**Session Duration:**
- Active: 1 hour
- Inactivity timeout: 5 minutes

---

## 🌐 Network Security

### Network Access Model

**Updated:** Services are accessible from your **local network** (e.g., 192.168.x.x):

```yaml
ports:
  - "0.0.0.0:80:80"      # HTTP → HTTPS redirect (network accessible)
  - "0.0.0.0:443:443"    # HTTPS (network accessible)
  - "127.0.0.1:8080:8080"  # Traefik dashboard (localhost only)
```

**Result:** Services are **accessible** from:
- The host machine
- Other devices on your local network (phones, tablets, laptops)
- Tailscale VPN connections (if configured)

**NOT accessible from:**
- Internet directly (unless port forwarding/VPN configured)

### Remote Access via Tailscale

For secure remote access, use **Tailscale + AdGuard Home**:
- Tailscale exit node on Mac Mini
- AdGuard Home for DNS rewrites (`*.arr.local` → Tailscale IP)
- See [ADGUARD_SETUP.md](ADGUARD_SETUP.md) for details

### VPN Protection

All torrent-related traffic routes through Gluetun VPN:
- ✅ **Protected**: Radarr, Sonarr, Prowlarr, Bazarr, Lidarr, qBittorrent
- ❌ **Not Protected**: Jellyfin (media streaming), Traefik (reverse proxy)

**Check VPN Status:**
```bash
docker exec gluetun wget -qO- http://localhost:10001/v1/publicip/ip
```

---

## 🛡️ Security Features

### 1. HTTPS/TLS Configuration (Traefik v3)

**Enabled:**
- TLS 1.2+ only (TLS 1.0/1.1 disabled)
- Strong cipher suites (ECDHE, AES-GCM, ChaCha20-Poly1305)
- HTTP → HTTPS automatic redirect
- HSTS with 1-year max-age
- SNI strict mode enabled

**Certificate:**
- Self-signed wildcard cert for `*.arr.local`
- Valid for 10 years
- 4096-bit RSA key
- Located in `traefik/certs/`

**Configuration:**
- TLS settings in `traefik/dynamic/tls.yml` (Traefik v3 format)
- Middlewares in `traefik/dynamic/middleware.yml`

### 2. Security Headers

Applied to all services via Traefik middleware:

```yaml
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Robots-Tag: none,noarchive,nosnippet
```

### 3. Rate Limiting

**Configuration:**
- Average: 100 requests/minute
- Burst: 50 requests
- Protection against brute-force attacks

### 4. Authentication Protection

**Authelia Features:**
- Password hashing: Argon2id
- Failed login tracking
- Account lockout after 3 failed attempts (5 minutes ban)
- Session management with automatic timeout

---

## 🔑 Password Management

### Generate Strong Passwords

```bash
# Generate 32-character password
openssl rand -base64 32

# Generate 64-character hex secret
openssl rand -hex 32
```

### Update User Password

```bash
# Generate new password hash
NEW_PASSWORD="your-new-password"
HASH=$(docker run --rm authelia/authelia:latest \
  authelia crypto hash generate argon2 --password "$NEW_PASSWORD" | \
  grep 'Digest:' | awk '{print $2}')

# Update users_database.yml
nano authelia/users_database.yml
# Replace the old hash with $HASH

# Restart Authelia
docker-compose restart authelia
```

### Add New User

```bash
./setup_authelia.sh
# Or manually edit authelia/users_database.yml
```

---

## 🚨 Security Checklist

### Before Public Deployment

- [ ] Change default BasicAuth password in `traefik/dynamic/middleware.yml`
- [ ] Replace `REPLACE_WITH_RANDOM_64_CHAR_STRING` in `authelia/configuration.yml`
- [ ] Generate strong passwords for all users
- [ ] Enable 2FA for all admin accounts
- [ ] Trust SSL certificate on all client devices
- [ ] Verify VPN connection is active
- [ ] Review Authelia access control rules
- [ ] Enable firewall on host machine
- [ ] Backup `.env` and `authelia/` configuration securely

### Regular Maintenance

- [ ] Rotate passwords every 90 days
- [ ] Review Authelia logs for suspicious activity
- [ ] Update Docker images monthly: `docker-compose pull && docker-compose up -d`
- [ ] Monitor VPN connection uptime
- [ ] Backup configuration files weekly

---

## 🌍 External Access (Optional)

### Option 1: Cloudflare Tunnel (Recommended)

Zero Trust network access without exposing ports:

1. Install `cloudflared`
2. Authenticate with Cloudflare
3. Create tunnel: `cloudflared tunnel create arr-stack`
4. Configure routes for `*.arr.local` → `https://127.0.0.1`
5. Services accessible via `https://radarr.yourdomain.com`

**Benefits:**
- No port forwarding required
- DDoS protection
- Zero Trust access
- Cloudflare WAF protection

### Option 2: Tailscale VPN

Private mesh network for secure remote access:

1. Install Tailscale on server and clients
2. Enable MagicDNS
3. Access services via: `https://server-name.tail-scale.ts.net:443`

### Option 3: WireGuard VPN

Self-hosted VPN server:

1. Setup WireGuard on your network
2. Configure firewall to allow WireGuard port
3. Connect clients to your network
4. Access services via local IPs

**⚠️ NOT RECOMMENDED:**
- Port forwarding without VPN/Cloudflare Tunnel
- Exposing services directly to the internet

---

## 📊 Monitoring & Logging

### Check Authentication Logs

```bash
# Authelia logs
docker-compose logs authelia

# Failed login attempts
cat authelia/db.sqlite3  # Use SQLite browser

# Notification log
cat authelia/notification.txt
```

### Monitor Access

```bash
# Traefik access logs
docker-compose logs traefik | grep -i "HTTP"

# Real-time monitoring
docker-compose logs -f --tail=100 traefik authelia
```

### Security Events to Watch

- Multiple failed login attempts from same IP
- Unusual access times (e.g., 3 AM)
- VPN disconnections
- Certificate expiration warnings
- Docker security updates available

---

## 🐛 Troubleshooting

### SSL Certificate Not Trusted

**Symptom:** Browser shows "Your connection is not private"

**Solution:**
```bash
# Verify certificate is generated
ls -lh certs/

# Trust certificate (see Quick Setup section)
# Restart browser after trusting
```

### Authelia Redirect Loop

**Symptom:** Continuously redirected between auth.arr.local and service

**Solution:**
```bash
# Clear browser cookies for *.arr.local
# Verify session secret is set in configuration.yml
grep "session:" authelia/configuration.yml

# Restart Authelia
docker-compose restart authelia
```

### Cannot Access Services

**Symptom:** Connection refused or timeout

**Solution:**
```bash
# Verify containers are running
docker-compose ps

# Check Traefik dashboard
open https://traefik.arr.local:8080

# Verify localhost binding
netstat -an | grep LISTEN | grep "127.0.0.1"

# Check /etc/hosts
cat /etc/hosts | grep arr.local
```

### 2FA Not Working

**Symptom:** TOTP codes rejected

**Solution:**
```bash
# Verify time sync on server
date

# Use time-based authenticator app (Google Authenticator, Authy)
# Ensure phone time is synced

# Reset 2FA for user (remove from users_database.yml)
nano authelia/users_database.yml
docker-compose restart authelia
```

---

## 📚 Additional Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Authelia Documentation](https://www.authelia.com/docs/)
- [OWASP Security Cheat Sheet](https://cheatsheetseries.owasp.org/)
- [Gluetun VPN Documentation](https://github.com/qdm12/gluetun)

---

## ⚖️ Disclaimer

This security setup is designed for **local/home lab environments**. For production or business use:

1. Use a proper CA-signed certificate (Let's Encrypt, commercial CA)
2. Implement additional security layers (IDS/IPS, SIEM)
3. Conduct regular security audits
4. Follow your organization's security policies
5. Consider hiring a security professional

**No security system is 100% foolproof. Stay informed and keep software updated.**
