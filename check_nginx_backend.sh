#!/bin/bash

# Set colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}===== Nginx 502 Bad Gateway Diagnostic Tool =====${NC}"
echo "This script will check for possible causes of Nginx reverse proxy 502 errors"
echo ""

# Check if running with root privileges
if [ "$EUID" -ne 0 ]
  then echo -e "${RED}Please run this script with root privileges (sudo $0)${NC}"
  exit 1
fi

# 1. Check Nginx status
echo -e "${YELLOW}Checking Nginx service status...${NC}"
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}Nginx service is running.${NC}"
else
    echo -e "${RED}Nginx service is not running! Attempting to start...${NC}"
    systemctl start nginx
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}Nginx service started successfully.${NC}"
    else
        echo -e "${RED}Unable to start Nginx service. Please check errors: 'journalctl -xe'${NC}"
        exit 1
    fi
fi
echo ""

# 2. Check backend service status
echo -e "${YELLOW}Checking service status on 172.19.0.16:8080...${NC}"
if command -v nc &> /dev/null; then
    if nc -z -w3 172.19.0.16 8080; then
        echo -e "${GREEN}Successfully connected to 172.19.0.16:8080, service is running.${NC}"
    else
        echo -e "${RED}Warning: Unable to connect to 172.19.0.16:8080!${NC}"
        echo "This is the most common cause of 502 errors."
        echo -e "${YELLOW}Please ensure there is a service running on port 8080 on the target server.${NC}"
    fi
else
    echo "nc command not found, trying other methods to check..."

    echo -e "${YELLOW}Attempting to check service using curl...${NC}"
    if command -v curl &> /dev/null; then
        CURL_RESULT=$(curl -s -o /dev/null -w "%{http_code}" http://172.19.0.16:8080 -m 3 2>/dev/null)
        if [ "$CURL_RESULT" = "000" ]; then
            echo -e "${RED}Unable to connect to 172.19.0.16:8080. Connection refused or timeout.${NC}"
        else
            echo -e "Connection status code: $CURL_RESULT (${GREEN}Successfully connected to backend service${NC})"
        fi
    else
        echo -e "${RED}No suitable tool found to check remote service status.${NC}"
        echo "Please ensure there is a service running on 172.19.0.16:8080."
    fi
fi
echo ""

# 3. Check Nginx error logs
echo -e "${YELLOW}Checking for 502 errors in Nginx error logs...${NC}"
NGINX_ERROR_LOG="/var/log/nginx/error.log"
if [ -f "$NGINX_ERROR_LOG" ]; then
    ERROR_LOGS=$(grep -i "502\|connect\|refused\|timeout\|no live upstreams\|172.19.0.16" $NGINX_ERROR_LOG | tail -n 20)
    if [ -n "$ERROR_LOGS" ]; then
        echo -e "${RED}Found related errors in Nginx error logs:${NC}"
        echo "$ERROR_LOGS"
    else
        echo "No obvious 502-related errors found in Nginx error logs."
    fi
else
    echo "Nginx error log file does not exist or is not accessible."
fi
echo ""

# 4. Test local to target connection
echo -e "${YELLOW}Testing connection to backend service...${NC}"
if command -v curl &> /dev/null; then
    echo "Using curl to test connection to 172.19.0.16:8080..."
    CURL_RESULT=$(curl -s -o /dev/null -w "%{http_code}" http://172.19.0.16:8080 2>/dev/null -m 3)
    if [ "$CURL_RESULT" = "000" ]; then
        echo -e "${RED}Unable to connect to 172.19.0.16:8080. Connection refused or timeout.${NC}"
    else
        echo -e "Connection status code: $CURL_RESULT (${GREEN}Successfully connected to backend service${NC})"
    fi
else
    echo "curl tool not found, skipping connection test."
fi
echo ""

# 5. Check Nginx configuration
echo -e "${YELLOW}Checking Nginx reverse proxy configuration...${NC}"
PROXY_CONFIG=$(grep -r "proxy_pass.*172.19.0.16:8080" /etc/nginx/ --include="*.conf" 2>/dev/null)
if [ -n "$PROXY_CONFIG" ]; then
    echo -e "${GREEN}Found reverse proxy configuration related to 172.19.0.16:8080:${NC}"
    echo "$PROXY_CONFIG"
else
    echo -e "${RED}No reverse proxy configuration found related to 172.19.0.16:8080!${NC}"
    echo "This may be a configuration error or the config file is not in the standard location."
fi
echo ""

# 6. Check network connectivity
echo -e "${YELLOW}Checking network connectivity to target server 172.19.0.16...${NC}"
ping -c 3 172.19.0.16 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}ping 172.19.0.16 successful, network connectivity is normal.${NC}"
else
    echo -e "${RED}Warning: ping 172.19.0.16 failed!${NC}"
    echo "Unable to reach target server, please check network settings."
fi
echo ""

# 7. Possible solutions
echo -e "${GREEN}====== Diagnostic Results and Solutions ======${NC}"

# Provide solutions based on check results
if ping -c 1 172.19.0.16 > /dev/null 2>&1; then
    if nc -z -w3 172.19.0.16 8080 2>/dev/null || [ "$CURL_RESULT" != "000" ]; then
        echo -e "${GREEN}Target server connectivity is normal and port 8080 is accessible.${NC}"
        echo "If 502 errors still occur, possible causes are:"
        echo "  1. Backend service response time is too long, causing Nginx timeout"
        echo "  2. Nginx configuration issues"
        echo ""
        echo "Recommended solutions:"
        echo "  - Modify Nginx configuration to increase timeout:"
        echo "    proxy_connect_timeout 300;"
        echo "    proxy_send_timeout 300;"
        echo "    proxy_read_timeout 300;"
        echo ""
    else
        echo -e "${RED}Problem diagnosis: Target server 172.19.0.16 is accessible, but port 8080 is not connectable.${NC}"
        echo "Solutions:"
        echo "  1. Ensure the service on the target server is running normally on port 8080"
        echo "  2. Check firewall settings on the target server to ensure connections to port 8080 are allowed"
        echo ""
    fi
else
    echo -e "${RED}Problem diagnosis: Unable to connect to target server 172.19.0.16${NC}"
    echo "Solutions:"
    echo "  1. Check network configuration to ensure the server can access 172.19.0.16"
    echo "  2. Verify the IP address is correct"
    echo "  3. Check routing and firewall settings"
    echo ""
fi

echo "General solutions:"
echo "  1. Ensure services on 172.19.0.16 are running normally on ports 8080 and 8081"
echo ""
echo "  2. Check firewall settings to ensure connections to the target server are allowed"
echo "     sudo ufw status  # if UFW firewall is enabled"
echo ""
echo "  3. If the problem persists, try modifying Nginx configuration to add debug information"
echo "     Add in the server block: error_log /var/log/nginx/debug.log debug;"
echo ""
echo "  4. Restart Nginx service"
echo "     sudo systemctl restart nginx"
echo ""

echo -e "${GREEN}====== Script execution completed ======${NC}"
echo "If you have fixed the problem or need more help, please refer to Nginx documentation or seek professional support."