#!/bin/bash

# ARR Stack Monitoring ve Otomatik Restart Script
# Bu script container'ların sağlığını kontrol eder ve gerekirse restart yapar

cd "$(dirname "$0")"

LOG_FILE="monitor.log"
COMPOSE_FILE="docker-compose.yaml"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_container() {
    local container_name=$1
    local status=$(docker inspect -f '{{.State.Health.Status}}' "$container_name" 2>/dev/null)
    
    if [ -z "$status" ]; then
        # Container'da healthcheck yoksa sadece running durumunu kontrol et
        status=$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null)
        if [ "$status" = "running" ]; then
            echo -e "${GREEN}✓${NC} $container_name: running"
            return 0
        else
            echo -e "${RED}✗${NC} $container_name: $status"
            return 1
        fi
    else
        if [ "$status" = "healthy" ]; then
            echo -e "${GREEN}✓${NC} $container_name: healthy"
            return 0
        else
            echo -e "${YELLOW}⚠${NC} $container_name: $status"
            return 1
        fi
    fi
}

restart_container() {
    local container_name=$1
    log "Restarting container: $container_name"
    docker-compose restart "$container_name"
    sleep 10
}

restart_unhealthy_containers() {
    local containers=("gluetun" "traefik" "radarr" "sonarr" "prowlarr" "bazarr" "lidarr" "qbittorrent" "jellyfin")
    local unhealthy_containers=()
    
    echo -e "\n${YELLOW}=== ARR Stack Container Durumu ===${NC}\n"
    
    for container in "${containers[@]}"; do
        if ! check_container "$container"; then
            unhealthy_containers+=("$container")
        fi
    done
    
    if [ ${#unhealthy_containers[@]} -gt 0 ]; then
        echo -e "\n${RED}Sağlıksız container'lar bulundu: ${unhealthy_containers[*]}${NC}"
        log "Unhealthy containers detected: ${unhealthy_containers[*]}"
        
        for container in "${unhealthy_containers[@]}"; do
            restart_container "$container"
        done
        
        echo -e "\n${GREEN}Restart işlemi tamamlandı. 30 saniye bekleniyor...${NC}"
        sleep 30
        
        # Tekrar kontrol et
        echo -e "\n${YELLOW}=== Tekrar Kontrol Ediliyor ===${NC}\n"
        for container in "${unhealthy_containers[@]}"; do
            check_container "$container"
        done
    else
        echo -e "\n${GREEN}✓ Tüm container'lar sağlıklı!${NC}\n"
        log "All containers are healthy"
    fi
}

check_vpn_connection() {
    echo -e "\n${YELLOW}=== VPN Bağlantı Kontrolü ===${NC}\n"
    
    local vpn_ip=$(docker exec gluetun wget -qO- http://localhost:10001/v1/publicip/ip 2>/dev/null)
    
    if [ -n "$vpn_ip" ]; then
        echo -e "${GREEN}✓ VPN IP: $vpn_ip${NC}"
        log "VPN connected: $vpn_ip"
        return 0
    else
        echo -e "${RED}✗ VPN bağlantısı kurulamadı!${NC}"
        log "VPN connection failed"
        return 1
    fi
}

# Ana işlem
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════╗"
echo "║   ARR Stack Health Monitor v1.0       ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

log "=== Monitor script started ==="

# Container'ları kontrol et ve gerekirse restart yap
restart_unhealthy_containers

# VPN bağlantısını kontrol et
if ! check_vpn_connection; then
    log "Restarting Gluetun due to VPN connection failure"
    restart_container "gluetun"
    sleep 30
    check_vpn_connection
fi

echo -e "\n${GREEN}=== Monitoring tamamlandı ===${NC}\n"
log "=== Monitor script completed ==="
