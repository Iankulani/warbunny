#!/bin/bash
# WARBUNNY v2.0.0 Installation Script for Linux/macOS

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║         🐇 WARBUNNY v2.0.0 - Installation Script                ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [[ -f /etc/debian_version ]]; then
            DISTRO="debian"
        elif [[ -f /etc/redhat-release ]]; then
            DISTRO="redhat"
        else
            DISTRO="other"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    else
        echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Detected OS: $OS ($DISTRO)${NC}"
}

# Check Python version
check_python() {
    if command -v python3 &>/dev/null; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        if [[ $(echo "$PYTHON_VERSION >= 3.7" | bc) -eq 1 ]]; then
            echo -e "${GREEN}✅ Python $PYTHON_VERSION found${NC}"
            return 0
        fi
    fi
    echo -e "${RED}❌ Python 3.7+ required${NC}"
    exit 1
}

# Install system dependencies
install_deps() {
    echo -e "\n${BLUE}📦 Installing system dependencies...${NC}"
    
    case $DISTRO in
        debian)
            sudo apt update
            sudo apt install -y python3-pip python3-dev python3-venv \
                nmap curl netcat-openbsd dnsutils traceroute \
                iputils-ping net-tools nikto whois openssh-client \
                build-essential libssl-dev libffi-dev libpcap-dev
            ;;
        redhat)
            sudo yum install -y python3-pip python3-devel nmap curl nc dnsutils \
                traceroute iputils net-tools nikto whois openssh-clients \
                gcc openssl-devel libffi-devel libpcap-devel
            ;;
        macos)
            if ! command -v brew &>/dev/null; then
                echo -e "${YELLOW}Installing Homebrew...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install python3 nmap curl netcat dnsutils traceroute nikto whois
            ;;
    esac
    echo -e "${GREEN}✅ System dependencies installed${NC}"
}

# Create virtual environment
setup_venv() {
    echo -e "\n${BLUE}🐍 Setting up Python virtual environment...${NC}"
    
    if [[ ! -d "venv" ]]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt
    
    echo -e "${GREEN}✅ Virtual environment created${NC}"
}

# Setup configuration
setup_config() {
    echo -e "\n${BLUE}⚙️  Configuring WARBUNNY...${NC}"
    
    mkdir -p .warbunny
    mkdir -p warbunny_reports
    
    # Generate random secret key
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
    
    # Create default config
    cat > .warbunny/config.json << EOF
{
    "version": "2.0.0",
    "auto_start": false,
    "auto_block_enabled": false,
    "auto_block_threshold": 5,
    "scan_timeout": 30,
    "report_format": "html",
    "generate_graphics": true,
    "web": {
        "enabled": false,
        "port": 5000,
        "host": "0.0.0.0",
        "secret_key": "$SECRET_KEY",
        "require_auth": true,
        "username": "admin",
        "password_hash": ""
    },
    "monitoring": {
        "enabled": true,
        "port_scan_threshold": 10,
        "syn_flood_threshold": 100,
        "http_flood_threshold": 200
    }
}
EOF
    
    echo -e "${GREEN}✅ Configuration created${NC}"
}

# Setup systemd service (Linux only)
setup_service() {
    if [[ "$OS" == "linux" ]]; then
        echo -e "\n${BLUE}🔧 Setting up systemd service...${NC}"
        
        INSTALL_DIR=$(pwd)
        cat > warbunny.service << EOF
[Unit]
Description=WARBUNNY Cybersecurity Platform
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$INSTALL_DIR/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$INSTALL_DIR/venv/bin/python3 warbunny.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        sudo cp warbunny.service /etc/systemd/system/
        sudo systemctl daemon-reload
        echo -e "${GREEN}✅ Systemd service created${NC}"
        echo -e "${YELLOW}   Start with: sudo systemctl start warbunny${NC}"
        echo -e "${YELLOW}   Enable at boot: sudo systemctl enable warbunny${NC}"
    fi
}

# Create desktop entry
create_desktop_entry() {
    if [[ "$OS" == "linux" ]]; then
        cat > ~/.local/share/applications/warbunny.desktop << EOF
[Desktop Entry]
Name=WARBUNNY
Comment=Cybersecurity Command & Control Platform
Exec=$(pwd)/venv/bin/python3 $(pwd)/warbunny.py
Icon=$(pwd)/warbunny.png
Terminal=true
Type=Application
Categories=Security;Network;
EOF
        echo -e "${GREEN}✅ Desktop entry created${NC}"
    fi
}

# Run tests
run_tests() {
    echo -e "\n${BLUE}🧪 Running tests...${NC}"
    source venv/bin/activate
    python3 requirements_check.py
    python3 -m pytest test_commands.py -v --tb=short || echo -e "${YELLOW}Some tests failed, but installation continues${NC}"
}

# Main installation
main() {
    detect_os
    check_python
    
    echo -e "\n${YELLOW}This will install WARBUNNY and its dependencies.${NC}"
    read -p "Continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    install_deps
    setup_venv
    setup_config
    run_tests
    setup_service
    create_desktop_entry
    
    echo -e "\n${GREEN}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}🐇 WARBUNNY v2.0.0 Installation Complete!${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "\n${BLUE}Next steps:${NC}"
    echo -e "  1. Activate environment: ${CYAN}source venv/bin/activate${NC}"
    echo -e "  2. Run WARBUNNY: ${CYAN}python3 warbunny.py${NC}"
    echo -e "  3. Type ${CYAN}help${NC} to see available commands"
    echo -e "\n${YELLOW}For security testing only. Use responsibly.${NC}"
}

main "$@"