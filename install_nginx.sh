#!/bin/bash

# Exit script on failure
set -e

echo "Installing and configuring Nginx reverse proxy service..."

# Detect Linux distribution
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu systems
    echo "Detected Debian/Ubuntu system"
    sudo apt update
    sudo apt install -y nginx
elif [ -f /etc/redhat-release ]; then
    # CentOS/RHEL/Fedora systems
    echo "Detected CentOS/RHEL/Fedora system"
    sudo yum install -y epel-release
    sudo yum install -y nginx
else
    echo "Unsupported Linux distribution, please install Nginx manually"
    exit 1
fi

# Confirm Nginx installation success
if ! command -v nginx &> /dev/null; then
    echo "Nginx installation failed, please check error messages and install manually"
    exit 1
fi

echo "Nginx installed successfully!"

# Handle default configuration files to avoid port conflicts
echo "Processing default configuration to avoid port conflicts..."
if [ -d "/etc/nginx/sites-enabled" ]; then
    # For Debian/Ubuntu systems
    # Check and backup default site configuration
    if [ -f "/etc/nginx/sites-enabled/default" ]; then
        sudo cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.bak
        sudo rm -f /etc/nginx/sites-enabled/default
        echo "Default site configuration backed up and removed"
    fi
    if [ -f "/etc/nginx/sites-enabled/default.orig" ]; then
        sudo rm -f /etc/nginx/sites-enabled/default.orig
        echo "Conflicting default.orig configuration removed"
    fi
fi

# Ensure conf.d directory exists
NGINX_CONF_DIR="/etc/nginx/conf.d"
if [ ! -d "$NGINX_CONF_DIR" ]; then
    sudo mkdir -p "$NGINX_CONF_DIR"
fi

# Backup existing configuration (if exists)
if [ -d "$NGINX_CONF_DIR" ] && [ "$(ls -A $NGINX_CONF_DIR 2>/dev/null)" ]; then
    echo "Creating backup of Nginx configuration directory..."
    sudo mkdir -p /etc/nginx/conf.d.bak
    sudo cp -r $NGINX_CONF_DIR/* /etc/nginx/conf.d.bak/ 2>/dev/null || true

    # Check if there are configurations on port 80
    for conf_file in "$NGINX_CONF_DIR"/*.conf; do
        if [ -f "$conf_file" ]; then
            if grep -q "listen.*80;" "$conf_file"; then
                echo "Found potentially conflicting configuration file: $conf_file, backing up and disabling..."
                sudo mv "$conf_file" "${conf_file}.disabled"
            fi
        fi
    done
fi

# Create our Nginx configuration file
echo "Configuring Nginx reverse proxy..."
CURRENT_DIR=$(pwd)

# Create new reverse proxy configuration file
cat > "$CURRENT_DIR/gerryyang_proxy.conf" << 'EOL'
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
EOL

# Copy Nginx configuration file
sudo cp "$CURRENT_DIR/gerryyang_proxy.conf" "$NGINX_CONF_DIR/gerryyang_proxy.conf"

# Test Nginx configuration
echo "Testing Nginx configuration..."
if ! sudo nginx -t; then
    echo "Nginx configuration test failed. Attempting to fix common issues..."

    # Fix possible configuration issues
    echo "Checking if there are multiple default servers on the same port..."
    NGINX_CONFIG_ERROR=$(sudo nginx -t 2>&1)

    if echo "$NGINX_CONFIG_ERROR" | grep -q "duplicate.*default server"; then
        echo "Detected default server conflict, attempting to fix..."

        # Remove default_server flag from our configuration (if exists)
        sudo sed -i 's/listen 80 default_server;/listen 80;/g' "$NGINX_CONF_DIR/gerryyang_proxy.conf"

        # If problem is in other files, try to backup and disable conflicting files
        ERROR_FILE=$(echo "$NGINX_CONFIG_ERROR" | grep -oE '/[^ ]+:[0-9]+' | cut -d':' -f1 | head -1)
        if [ -n "$ERROR_FILE" ] && [ -f "$ERROR_FILE" ]; then
            echo "Attempting to backup and disable conflicting file: $ERROR_FILE"
            sudo cp "$ERROR_FILE" "${ERROR_FILE}.bak"
            sudo mv "$ERROR_FILE" "${ERROR_FILE}.disabled"
        fi

        # Test configuration again
        echo "Re-testing Nginx configuration..."
        if ! sudo nginx -t; then
            echo "Automatic fix failed, please check Nginx configuration manually."
            exit 1
        fi
    else
        echo "Automatic fix failed, please check Nginx configuration manually."
        exit 1
    fi
fi

# Restart Nginx service
echo "Restarting Nginx service..."
if command -v systemctl &> /dev/null; then
    sudo systemctl restart nginx
    sudo systemctl enable nginx
else
    sudo service nginx restart
fi

# Check if Nginx is running
if pgrep -x "nginx" > /dev/null; then
    echo "Nginx service started successfully!"
else
    echo "Nginx service failed to start, please check error logs: /var/log/nginx/error.log"
    exit 1
fi

# Check if port 80 is open
if command -v netstat &> /dev/null; then
    if netstat -tuln | grep ":80 " > /dev/null; then
        echo "Port 80 is open, reverse proxy service configured successfully!"
    else
        echo "Warning: Port 80 doesn't seem to be listening, please check Nginx logs and configuration."
    fi
elif command -v ss &> /dev/null; then
    if ss -tuln | grep ":80 " > /dev/null; then
        echo "Port 80 is open, reverse proxy service configured successfully!"
    else
        echo "Warning: Port 80 doesn't seem to be listening, please check Nginx logs and configuration."
    fi
else
    echo "Unable to check port status, please manually confirm if port 80 is open."
fi

echo ""
echo "====================================================="
echo "Nginx reverse proxy configuration completed."
echo "Services can now be accessed at the following addresses:"
echo "- http://www.gerryyang.com -> forwards to 172.19.0.16:8080"
echo "- http://llmnews.gerryyang.com -> forwards to 172.19.0.16:8081"
echo "Please ensure the relevant domains are correctly resolved to your server IP."
echo "====================================================="