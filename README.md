
# Nginx Reverse Proxy Setup

## Project Overview

This project provides a complete solution for setting up and managing an Nginx reverse proxy server. It includes automated installation scripts, configuration management, testing tools, and diagnostic utilities to help you deploy and maintain a production-ready reverse proxy setup.

### What This Project Does

- **Automated Installation**: One-command installation and configuration of Nginx reverse proxy
- **Multi-Domain Support**: Configure multiple domains to forward to different backend services
- **Conflict Resolution**: Automatically detect and resolve common configuration conflicts
- **Testing Tools**: Built-in test servers to verify your reverse proxy configuration
- **Diagnostic Tools**: Comprehensive troubleshooting tools for common issues
- **Production Ready**: Includes error handling, logging, and monitoring capabilities

### Key Features

- 🚀 **Quick Setup**: Get a working reverse proxy in minutes with automated scripts
- 🔧 **Smart Configuration**: Automatically handles Linux distribution differences and common conflicts
- 🧪 **Built-in Testing**: Test your setup before going live with included test servers
- 🐛 **Easy Troubleshooting**: Comprehensive diagnostic tools for common problems
- 📚 **Complete Documentation**: Step-by-step guides for both automated and manual setup

This setup configures an Nginx reverse proxy with the following forwarding rules:
- `www.gerryyang.com` (port 80) -> forwards to `172.19.0.16:8080`
- `llmnews.gerryyang.com` (port 80) -> forwards to `172.19.0.16:8081`



## Prerequisites

- Linux server (Debian/Ubuntu or CentOS/RHEL/Fedora)
- Root or sudo privileges
- Domains `www.gerryyang.com` and `llmnews.gerryyang.com` pointing to your server's IP
- Target server (172.19.0.16) running services on ports 8080 and 8081

## Quick Installation Method

Use the automatic installation script to install and configure Nginx:

```bash
# Add execute permission to the installation script
chmod +x install_nginx.sh

# Execute the installation script
sudo ./install_nginx.sh
```

This script will automatically:
1. Detect your Linux distribution and install Nginx
2. Handle and resolve configuration conflicts
3. Configure Nginx multi-domain reverse proxy
   - www.gerryyang.com -> 172.19.0.16:8080
   - llmnews.gerryyang.com -> 172.19.0.16:8081
4. Start and confirm the service is running normally
5. Verify that port 80 is open

## Testing Tools

To test whether the reverse proxy configuration is working properly, we provide several useful tools:

### 1. Test Server Startup Tool

This tool will start test web servers on ports 8080 and 8081 to verify Nginx reverse proxy functionality (only for local testing):

```bash
# Add execute permission to the script
chmod +x start_test_server.sh

# Start test web servers
./start_test_server.sh
```

After startup, you can access test pages at the following addresses:
- http://www.gerryyang.com - Should display pages from port 8080
- http://llmnews.gerryyang.com - Should display pages from port 8081

### 2. Stop Test Server

Use the following command to stop the test web servers:

```bash
chmod +x stop_test_server.sh
./stop_test_server.sh
```

### 3. Nginx 502 Error Diagnostic Tool

If you encounter a "502 Bad Gateway" error, you can use this tool to diagnose the problem:

```bash
chmod +x check_nginx_backend.sh
sudo ./check_nginx_backend.sh
```

This script will:
- Check Nginx service status
- Check if backend servers (ports 8080 and 8081 on 172.19.0.16) are reachable
- Analyze Nginx error logs
- Test network connectivity
- Provide repair suggestions

## Common Problem Solutions

### 502 Bad Gateway Error

If you encounter a "502 Bad Gateway" error when accessing the website, it's usually because:

1. **Backend service not running**: Ensure services are running on ports 8080 and 8081 of 172.19.0.16
   ```bash
   # Check if connection is reachable
   ping 172.19.0.16

   # Test port connectivity
   nc -zv 172.19.0.16 8080
   nc -zv 172.19.0.16 8081
   ```

2. **Firewall settings**: Check if firewall allows connections to target server
   ```bash
   sudo ufw status
   ```

3. **Nginx configuration error**: Verify proxy_pass settings
   ```bash
   sudo grep -r "proxy_pass" /etc/nginx/
   ```

4. **View Nginx error logs**
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

### Port Conflict Error

If you encounter errors similar to the following during installation:
```
nginx: [emerg] a duplicate default server for 0.0.0.0:8080 in /etc/nginx/sites-enabled/default.orig:22
nginx: configuration file /etc/nginx/nginx.conf test failed
```

Or:
```
nginx: [emerg] bind() to 0.0.0.0:8080 failed (98: Address already in use)
```

You can use the provided port conflict fix tool:

```bash
chmod +x fix_nginx_port.sh
sudo ./fix_nginx_port.sh
```

## Manual Configuration Steps

If you don't want to use the automatic script, you can configure manually following these steps:

1. **Install Nginx**

   Debian/Ubuntu systems:
   ```bash
   sudo apt update
   sudo apt install -y nginx
   ```

   CentOS/RHEL systems:
   ```bash
   sudo yum install -y epel-release
   sudo yum install -y nginx
   ```

2. **Handle possible configuration conflicts**

   ```bash
   # Backup default site configuration
   sudo cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.bak 2>/dev/null || true
   sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

   # Remove any possible conflicting configurations
   sudo rm -f /etc/nginx/sites-enabled/default.orig 2>/dev/null || true
   ```

3. **Create Nginx configuration**

   Save the following configuration to `/etc/nginx/conf.d/gerryyang_proxy.conf`:

   ```nginx
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
   ```

4. **Test and apply configuration**

   ```bash
   # Test configuration file
   sudo nginx -t

   # Restart Nginx
   sudo systemctl restart nginx
   sudo systemctl enable nginx
   ```

## Usage

- Ensure services on target server (172.19.0.16) are running on ports 8080 and 8081 respectively
- Access services through:
  - `http://www.gerryyang.com` -> Access service on 172.19.0.16:8080
  - `http://llmnews.gerryyang.com` -> Access service on 172.19.0.16:8081

## Troubleshooting

If services cannot be accessed normally after configuration, try the following steps:

- Check if Nginx is running: `systemctl status nginx`
- View Nginx error logs: `sudo tail -f /var/log/nginx/error.log`
- Check if firewall allows port 80: `sudo ufw status` or `sudo firewall-cmd --list-all`
- Confirm domain resolution is correct:
  ```bash
  ping www.gerryyang.com
  ping llmnews.gerryyang.com
  ```
- Ensure target server is reachable and running services on corresponding ports:
  ```bash
  ping 172.19.0.16
  nc -zv 172.19.0.16 8080
  nc -zv 172.19.0.16 8081
  ```
- Use diagnostic tool: `sudo ./check_nginx_backend.sh`


## Community and Support

### 🤝 Contributing
We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to:
- Report bugs and request features
- Submit code changes
- Follow our coding standards
- Test your contributions

### 📋 Issue Templates
- [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md) - For reporting problems
- [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md) - For suggesting improvements

### 🔒 Security
- Found a security vulnerability? Please report it privately to [security@gerryyang.com](mailto:security@gerryyang.com)
- See our [Security Policy](SECURITY.md) for more details

### 📖 Project Documentation
- [Code of Conduct](CODE_OF_CONDUCT.md) - Community behavior standards
- [Changelog](CHANGELOG.md) - Version history and updates
- [License](LICENSE) - MIT License for open source use

### 🚀 CI/CD
- Automated testing on every pull request
- Syntax checking and validation
- Cross-platform compatibility testing
- Security scanning for sensitive information

