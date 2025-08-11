#!/bin/bash

# Set colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}===== Nginx Port Conflict Fix Tool =====${NC}"
echo "This script will find and fix issues in Nginx configuration that may cause port 8080 conflicts"
echo ""

# Check if running with root privileges
if [ "$EUID" -ne 0 ]
  then echo -e "${RED}Please run this script with root privileges (sudo $0)${NC}"
  exit 1
fi

# Find processes using port 8080
echo -e "${YELLOW}Checking processes using port 8080...${NC}"
PORT_USERS=$(lsof -i:8080 -P -n | grep LISTEN)
if [ -n "$PORT_USERS" ]; then
    echo -e "${RED}Detected the following processes using port 8080:${NC}"
    echo "$PORT_USERS"
    echo ""
    echo -e "${YELLOW}Note: Port 8080 is already in use, Nginx should not try to listen on this port.${NC}"
    echo "This indicates there may be incorrect listen directives in the Nginx configuration files."
    echo ""
else
    echo "No processes are currently using port 8080."
    echo "However, Nginx still reports being unable to bind to this port, which may be because the system just restarted or the service was just stopped."
    echo ""
fi

# Find all Nginx configuration files
echo -e "${YELLOW}Finding all Nginx configuration files...${NC}"
CONFIG_FILES=$(find /etc/nginx -type f -name "*.conf")
ENABLED_SITES=$(find /etc/nginx/sites-enabled -type f 2>/dev/null)
AVAILABLE_SITES=$(find /etc/nginx/sites-available -type f 2>/dev/null)

# Merge all configuration file paths
ALL_CONFIG_FILES="$CONFIG_FILES $ENABLED_SITES $AVAILABLE_SITES"

# Find configurations listening on port 8080
echo -e "${YELLOW}Finding configurations listening on port 8080...${NC}"
PROBLEM_FILES=""

for file in $ALL_CONFIG_FILES; do
    if grep -q "listen.*8080" "$file"; then
        echo -e "${RED}Found port 8080 listen configuration in file $file${NC}"
        PROBLEM_FILES="$PROBLEM_FILES $file"

        # Display lines containing 8080
        echo "Problematic lines:"
        grep -n "listen.*8080" "$file" | while read -r line; do
            echo "  $line"
        done
        echo ""
    fi
done

if [ -z "$PROBLEM_FILES" ]; then
    echo "No configuration files explicitly listening on port 8080 were found."
    echo "There may be other implicit configuration issues."
    echo ""
fi

# Check include directives in nginx.conf
echo -e "${YELLOW}Checking include directives in main configuration file...${NC}"
MAIN_CONFIG="/etc/nginx/nginx.conf"
if [ -f "$MAIN_CONFIG" ]; then
    echo "Include directives in main configuration file:"
    grep -n "include" "$MAIN_CONFIG" | while read -r line; do
        echo "  $line"
    done
    echo ""
else
    echo "Main configuration file $MAIN_CONFIG not found"
    echo ""
fi

# Fix suggestions
echo -e "${GREEN}====== Fix Suggestions ======${NC}"
echo "1. Please confirm whether you need to keep the service running on port 8080."
echo "   - If you need to keep it, please modify the Nginx configuration to not listen on port 8080"
echo "   - If you don't need to keep it, you can terminate the service to let Nginx use port 8080"
echo ""
echo "2. Fix methods:"
echo "   a) Backup and disable problematic configuration files:"
echo ""

for file in $PROBLEM_FILES; do
    echo "      # Backup configuration file"
    echo "      sudo cp $file ${file}.bak"
    echo ""
    echo "      # Disable configuration file"
    echo "      sudo mv $file ${file}.disabled"
    echo ""
done

echo "   b) Or modify the port settings in the configuration file:"
echo "      Change 8080 in the listen directive to another unused port"
echo ""
echo "3. Verify configuration and restart Nginx:"
echo "      sudo nginx -t"
echo "      sudo systemctl restart nginx"
echo ""

# Auto-fix option
echo -e "${YELLOW}Do you want to try automatic fix? (y/n)${NC}"
read -r AUTO_FIX

if [[ "$AUTO_FIX" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Executing automatic fix...${NC}"

    # Backup and disable problematic configuration files
    for file in $PROBLEM_FILES; do
        echo "Processing file: $file"
        cp "$file" "${file}.bak"
        echo "Backup created: ${file}.bak"

        # Modify the file instead of disabling it
        sed -i 's/listen.*8080/listen 8090/g' "$file"
        echo "Changed port 8080 to 8090"
    done

    # Check main Nginx configuration
    if [ -f "/etc/nginx/nginx.conf" ]; then
        if grep -q "listen.*8080" "/etc/nginx/nginx.conf"; then
            echo "Modifying port 8080 in main configuration file..."
            cp "/etc/nginx/nginx.conf" "/etc/nginx/nginx.conf.bak"
            sed -i 's/listen.*8080/listen 8090/g' "/etc/nginx/nginx.conf"
        fi
    fi

    # Ensure our configuration is correct
    echo "Ensuring gerryyang_proxy.conf configuration is correct..."
    cat > "/etc/nginx/conf.d/gerryyang_proxy.conf" << 'EOL'
# Forward www.gerryyang.com to port 8080
server {
    listen 80;
    server_name www.gerryyang.com;

    location / {
        proxy_pass http://localhost:8080;
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
        proxy_pass http://localhost:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL

    # Test Nginx configuration
    echo "Testing Nginx configuration..."
    if nginx -t; then
        echo -e "${GREEN}Configuration test successful, restarting Nginx service...${NC}"
        systemctl restart nginx

        # Check if Nginx started successfully
        if systemctl is-active --quiet nginx; then
            echo -e "${GREEN}Nginx service started successfully!${NC}"
            echo "You can now access your services at the following addresses:"
            echo "- http://www.gerryyang.com -> forwards to local port 8080"
            echo "- http://llmnews.gerryyang.com -> forwards to local port 8081"
        else
            echo -e "${RED}Nginx service failed to start, please check logs: 'journalctl -xe' and 'sudo nginx -t'${NC}"
        fi
    else
        echo -e "${RED}Nginx configuration test failed, please check configuration manually.${NC}"
    fi
else
    echo "Automatic fix cancelled. Please follow the suggestions above to fix the problem manually."
fi

echo ""
echo -e "${GREEN}====== Script execution completed ======${NC}"
echo "If the problem persists, please consider viewing detailed Nginx logs:"
echo "  sudo journalctl -u nginx.service --no-pager"
echo "Or contact your system administrator for help."