#!/bin/bash

# Nginx Reverse Proxy Management Script
# 
# Usage:
#   ./run_nginx.sh install   - Install and configure Nginx
#   ./run_nginx.sh start     - Start Nginx service (auto-sync config if needed)
#   ./run_nginx.sh stop      - Stop Nginx service
#   ./run_nginx.sh restart   - Restart Nginx service (auto-sync config if needed)
#   ./run_nginx.sh reload    - Reload configuration (auto-sync config if needed)
#   ./run_nginx.sh status    - Check Nginx service status
#   ./run_nginx.sh test      - Test Nginx configuration syntax
#   ./run_nginx.sh help      - Show this help message

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_status $RED "Error: This script must be run as root or with sudo"
        exit 1
    fi
}

# Function to check if Nginx is installed
check_nginx_installed() {
    if ! command -v nginx &> /dev/null; then
        print_status $RED "Error: Nginx is not installed on this system"
        print_status $YELLOW "Please run './run_nginx.sh install' first to install Nginx"
        exit 1
    fi
}

# Function to start Nginx
start_nginx() {
    print_status $BLUE "Starting Nginx service..."
    
    if systemctl is-active --quiet nginx; then
        print_status $YELLOW "Nginx is already running"
        return 0
    fi
    
    systemctl start nginx
    
    if systemctl is-active --quiet nginx; then
        print_status $GREEN "✓ Nginx started successfully"
        
        # Verify port 80 is listening
        sleep 1
        if ss -tuln | grep -q ':80'; then
            print_status $GREEN "✓ Port 80 is listening"
        else
            print_status $YELLOW "⚠ Warning: Port 80 may not be properly configured"
        fi
    else
        print_status $RED "✗ Failed to start Nginx"
        print_status $YELLOW "Check logs with: journalctl -xe nginx"
        exit 1
    fi
}

# Function to stop Nginx
stop_nginx() {
    print_status $BLUE "Stopping Nginx service..."
    
    if ! systemctl is-active --quiet nginx; then
        print_status $YELLOW "Nginx is not running"
        return 0
    fi
    
    systemctl stop nginx
    
    if ! systemctl is-active --quiet nginx; then
        print_status $GREEN "✓ Nginx stopped successfully"
    else
        print_status $RED "✗ Failed to stop Nginx"
        exit 1
    fi
}

# Function to restart Nginx
restart_nginx() {
    print_status $BLUE "Restarting Nginx service..."
    
    if ! systemctl is-active --quiet nginx; then
        print_status $YELLOW "Nginx is not running, starting instead..."
        start_nginx
        return 0
    fi
    
    systemctl restart nginx
    
    if systemctl is-active --quiet nginx; then
        print_status $GREEN "✓ Nginx restarted successfully"
    else
        print_status $RED "✗ Failed to restart Nginx"
        print_status $YELLOW "Check logs with: journalctl -xe nginx"
        exit 1
    fi
}

# Function to reload Nginx configuration
reload_nginx() {
    print_status $BLUE "Reloading Nginx configuration (graceful)..."
    
    if ! systemctl is-active --quiet nginx; then
        print_status $YELLOW "Nginx is not running, starting instead..."
        start_nginx
        return 0
    fi
    
    # Test configuration first
    print_status $BLUE "Testing Nginx configuration..."
    if ! nginx -t 2>&1; then
        print_status $RED "✗ Configuration test failed"
        print_status $YELLOW "Please fix the configuration errors before reloading"
        exit 1
    fi
    
    print_status $GREEN "✓ Configuration test passed"
    
    # Reload configuration
    systemctl reload nginx
    
    print_status $GREEN "✓ Nginx configuration reloaded successfully"
}

# Function to check Nginx status
status_nginx() {
    print_status $BLUE "Checking Nginx service status..."
    echo ""
    
    # Service status
    echo "Service Status:"
    if systemctl is-active --quiet nginx; then
        print_status $GREEN "  ✓ Nginx is running"
    else
        print_status $RED "  ✗ Nginx is not running"
    fi
    
    # Enabled status
    echo "Boot Startup:"
    if systemctl is-enabled --quiet nginx; then
        print_status $GREEN "  ✓ Nginx is enabled at boot"
    else
        print_status $YELLOW "  ⚠ Nginx is not enabled at boot"
        print_status $BLUE "  Run: sudo systemctl enable nginx"
    fi
    
    # Process info
    echo ""
    echo "Process Information:"
    ps aux | grep nginx | grep -v grep || echo "  No Nginx processes found"
    
    # Port listening
    echo ""
    echo "Listening Ports:"
    ss -tuln | grep -E ':(80|443)' || echo "  No HTTP/HTTPS ports listening"
    
    # Configuration file
    echo ""
    echo "Configuration File:"
    echo "  Main: $(nginx -V 2>&1 | grep -oP '(?<=--conf-path=)[^ ]+' || echo 'Unknown')"
    echo "  Config Test: $(nginx -t 2>&1 | head -n1)"
    
    # Recent logs
    echo ""
    echo "Recent Error Logs:"
    if [[ -f /var/log/nginx/error.log ]]; then
        tail -n 5 /var/log/nginx/error.log 2>/dev/null || echo "  Unable to read logs"
    else
        echo "  Error log not found"
    fi
}

# Function to test Nginx configuration
test_nginx() {
    print_status $BLUE "Testing Nginx configuration syntax..."
    echo ""
    
    if nginx -t 2>&1; then
        print_status $GREEN "✓ Configuration test passed"
        
        # Show configuration details
        echo ""
        echo "Configuration Details:"
        nginx -V 2>&1 | grep -oP '(?<=configure arguments:).*' | tr ' ' '\n' | grep -E '^--' | sed 's/^/  /'
    else
        print_status $RED "✗ Configuration test failed"
        exit 1
    fi
}

# Function to install Nginx only (without configuration)
install_nginx_only() {
    print_status $BLUE "Installing Nginx..."
    echo ""
    
    # Detect Linux distribution
    print_status $BLUE "Detecting Linux distribution..."
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu systems
        print_status $GREEN "Detected Debian/Ubuntu system"
        print_status $BLUE "Updating package lists..."
        apt update > /dev/null 2>&1
        print_status $BLUE "Installing Nginx..."
        apt install -y nginx > /dev/null 2>&1
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL/Fedora systems
        print_status $GREEN "Detected CentOS/RHEL/Fedora system"
        print_status $BLUE "Installing Nginx (via EPEL)..."
        yum install -y epel-release > /dev/null 2>&1
        yum install -y nginx > /dev/null 2>&1
    else
        print_status $RED "Error: Unsupported Linux distribution"
        echo "Please install Nginx manually according to your distribution"
        exit 1
    fi
    
    # Confirm Nginx installation success
    if ! command -v nginx &> /dev/null; then
        print_status $RED "Error: Nginx installation failed"
        exit 1
    fi
    
    print_status $GREEN "✓ Nginx installed successfully"
    echo ""
}

# Function to sync configuration to Nginx
sync_config() {
    print_status $BLUE "Synchronizing Nginx configuration..."
    echo ""
    
    NGINX_CONF_DIR="/etc/nginx/conf.d"
    
    # Handle default configuration files to avoid port conflicts
    print_status $BLUE "Processing default configuration to avoid port conflicts..."
    if [ -d "/etc/nginx/sites-enabled" ]; then
        # For Debian/Ubuntu systems
        if [ -f "/etc/nginx/sites-enabled/default" ]; then
            cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.bak
            rm -f /etc/nginx/sites-enabled/default
            print_status $GREEN "  Default site configuration backed up and removed"
        fi
        if [ -f "/etc/nginx/sites-enabled/default.orig" ]; then
            rm -f /etc/nginx/sites-enabled/default.orig
            print_status $YELLOW "  Conflicting default.orig configuration removed"
        fi
    fi
    
    # Ensure conf.d directory exists
    if [ ! -d "$NGINX_CONF_DIR" ]; then
        mkdir -p "$NGINX_CONF_DIR"
    fi
    
    # Backup existing configuration (if exists)
    if [ -d "$NGINX_CONF_DIR" ] && [ "$(ls -A $NGINX_CONF_DIR 2>/dev/null)" ]; then
        print_status $BLUE "Creating backup of existing Nginx configuration..."
        mkdir -p /etc/nginx/conf.d.bak
        cp -r $NGINX_CONF_DIR/* /etc/nginx/conf.d.bak/ 2>/dev/null || true
        
        # Check if there are configurations on port 80
        for conf_file in "$NGINX_CONF_DIR"/*.conf; do
            if [ -f "$conf_file" ]; then
                if grep -q "listen.*80;" "$conf_file"; then
                    print_status $YELLOW "  Found potentially conflicting configuration: $conf_file"
                    mv "$conf_file" "${conf_file}.disabled"
                fi
            fi
        done
    fi
    
    # Copy project configuration file to Nginx config directory
    print_status $BLUE "Copying configuration to $NGINX_CONF_DIR/..."
    
    CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    if [ -f "$CURRENT_DIR/gerryyang_proxy.conf" ]; then
        cp "$CURRENT_DIR/gerryyang_proxy.conf" "$NGINX_CONF_DIR/gerryyang_proxy.conf"
        print_status $GREEN "  Copied gerryyang_proxy.conf to $NGINX_CONF_DIR/"
    else
        # Fallback: create configuration from template
        cat > "$NGINX_CONF_DIR/gerryyang_proxy.conf" << 'EOF'
# Forward www.gerryyang.com to port 8080
server {
    listen 80;
    server_name www.gerryyang.com;

    location / {
        proxy_pass http://172.19.0.16:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Forward llmnews.gerryyang.com to port 8081
server {
    listen 80;
    server_name llmnews.gerryyang.com;

    location / {
        proxy_pass http://172.19.0.16:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Forward english.gerryyang.com to port 8082
server {
    listen 80;
    server_name english.gerryyang.com;

    location / {
        proxy_pass http://172.19.0.16:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
        print_status $GREEN "  Created gerryyang_proxy.conf from template"
    fi
    
    # Verify that Nginx main config includes conf.d directory
    print_status $BLUE "Verifying Nginx configuration..."
    if ! grep -q "include.*conf\.d" /etc/nginx/nginx.conf 2>/dev/null; then
        print_status $YELLOW "  Warning: /etc/nginx/nginx.conf does not include conf.d directory"
        print_status $BLUE "  Attempting to add include statement..."
        
        if grep -q "^http {" /etc/nginx/nginx.conf; then
            sed -i '/^http {/a\    include /etc/nginx/conf.d/*.conf;' /etc/nginx/nginx.conf
            print_status $GREEN "  Added include statement to http block"
        else
            print_status $RED "  Could not find http block in nginx.conf"
            print_status $YELLOW "  Please manually add 'include /etc/nginx/conf.d/*.conf;' to nginx.conf"
        fi
    else
        print_status $GREEN "  Nginx main config includes conf.d directory"
    fi
    
    # Test configuration
    print_status $BLUE "Testing Nginx configuration..."
    if ! nginx -t 2>&1; then
        print_status $YELLOW "Configuration test failed, attempting to fix common issues..."
        
        NGINX_CONFIG_ERROR=$(nginx -t 2>&1)
        
        if echo "$NGINX_CONFIG_ERROR" | grep -q "duplicate.*default server"; then
            print_status $BLUE "Detected default server conflict, attempting to fix..."
            
            sed -i 's/listen 80 default_server;/listen 80;/g' "$NGINX_CONF_DIR/gerryyang_proxy.conf"
            
            ERROR_FILE=$(echo "$NGINX_CONFIG_ERROR" | grep -oE '/[^ ]+:[0-9]+' | cut -d':' -f1 | head -1)
            if [ -n "$ERROR_FILE" ] && [ -f "$ERROR_FILE" ]; then
                print_status $BLUE "Backing up and disabling conflicting file: $ERROR_FILE"
                cp "$ERROR_FILE" "${ERROR_FILE}.bak"
                mv "$ERROR_FILE" "${ERROR_FILE}.disabled"
            fi
            
            if ! nginx -t 2>&1; then
                print_status $RED "✗ Automatic fix failed"
                echo "Please check Nginx configuration manually"
                exit 1
            fi
        else
            print_status $RED "✗ Automatic fix failed"
            echo "Please check Nginx configuration manually"
            exit 1
        fi
    fi
    
    print_status $GREEN "✓ Configuration test passed"
    print_status $GREEN "✓ Configuration synchronized successfully"
    echo ""
}

# Function to install Nginx (install + sync config)
install_nginx() {
    # Check if Nginx is already installed
    if command -v nginx &> /dev/null; then
        print_status $YELLOW "Nginx is already installed"
        print_status $BLUE "Running configuration sync only..."
        sync_config
    else
        install_nginx_only
        sync_config
    fi
    
    echo "====================================================="
    print_status $GREEN "Nginx installation completed!"
    echo ""
    echo "Configured forwarding rules:"
    echo "  - http://www.gerryyang.com -> 172.19.0.16:8080"
    echo "  - http://llmnews.gerryyang.com -> 172.19.0.16:8081"
    echo "  - http://english.gerryyang.com -> 172.19.0.16    echo ""
   :8082"
 echo "Next steps:"
    echo "  1. Ensure the relevant domains are correctly resolved to your server IP"
    echo "  2. Ensure services are running on 172.19.0.16:8080, 8081, 8082"
    echo "  3. Use './run_nginx.sh start' to start Nginx service"
    echo "====================================================="
}

# Function to show help
show_help() {
    echo "Nginx Reverse Proxy Management Script"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  install   - Install and configure Nginx"
    echo "  start     - Start Nginx service (auto-sync config if needed)"
    echo "  stop      - Stop Nginx service"
    echo "  restart   - Restart Nginx service (auto-sync config if needed)"
    echo "  reload    - Reload configuration (auto-sync config if needed)"
    echo "  status    - Check Nginx service status"
    echo "  test      - Test Nginx configuration syntax"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install"
    echo "  $0 start"
    echo "  $0 restart"
    echo "  $0 status"
    echo ""
    echo "For more information, see README.md"
}

# Main script logic
main() {
    # Parse command
    case "${1:-help}" in
        install)
            check_root
            install_nginx
            ;;
        start)
            check_root
            check_nginx_installed
            sync_config
            start_nginx
            ;;
        stop)
            check_root
            check_nginx_installed
            stop_nginx
            ;;
        restart)
            check_root
            check_nginx_installed
            sync_config
            restart_nginx
            ;;
        reload)
            check_root
            check_nginx_installed
            sync_config
            reload_nginx
            ;;
        status)
            check_nginx_installed
            status_nginx
            ;;
        test)
            check_nginx_installed
            test_nginx
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_status $RED "Error: Unknown command '$1'"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
