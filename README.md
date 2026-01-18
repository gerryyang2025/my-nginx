
# Nginx Reverse Proxy Setup

## Project Overview

This project provides Nginx reverse proxy configuration files and management scripts to help you set up and manage a multi-domain reverse proxy server.

### What This Project Does

- **Automated Installation**: One-command installation and configuration of Nginx reverse proxy
- **Multi-Domain Support**: Configure multiple domains to forward to different backend services
- **Testing Tools**: Built-in test servers to verify your reverse proxy configuration
- **Service Management**: Start, stop, restart, reload, and monitor Nginx service

### Key Features

- 🚀 **Quick Setup**: Get a working reverse proxy in minutes with automated scripts
- 🔧 **Cross-Platform**: Supports Debian/Ubuntu and CentOS/RHEL distributions
- 🧪 **Built-in Testing**: Test your setup before going live with included test servers
- 📚 **Complete Documentation**: Step-by-step guides for both automated and manual setup

This setup configures an Nginx reverse proxy with the following forwarding rules:
- `www.gerryyang.com` (port 80) -> forwards to `172.19.0.16:8080`
- `llmnews.gerryyang.com` (port 80) -> forwards to `172.19.0.16:8081`
- `english.gerryyang.com` (port 80) -> forwards to `172.19.0.16:8082`


## Prerequisites

- Linux server (Debian/Ubuntu or CentOS/RHEL/Fedora)
- Root or sudo privileges
- Domains `www.gerryyang.com`, `llmnews.gerryyang.com`, and `english.gerryyang.com` pointing to your server's IP
- Target server (172.19.0.16) running services on ports 8080, 8081, and 8082

## Quick Installation Method

Use the built-in installation command to install and configure Nginx:

```bash
# Add execute permission to the script
chmod +x run_nginx.sh

# Install and configure Nginx
sudo ./run_nginx.sh install
```

This command will automatically:
1. Detect your Linux distribution and install Nginx
2. Handle and resolve configuration conflicts
3. Configure Nginx multi-domain reverse proxy
   - www.gerryyang.com -> 172.19.0.16:8080
   - llmnews.gerryyang.com -> 172.19.0.16:8081
   - english.gerryyang.com -> 172.19.0.16:8082
4. Start and confirm the service is running normally
5. Verify that port 80 is open

### Service Management

After installation, you can use the `run_nginx.sh` script to manage the Nginx service:

```bash
# Start Nginx service
sudo ./run_nginx.sh start

# Check service status
sudo ./run_nginx.sh status

# Stop Nginx service
sudo ./run_nginx.sh stop

# Restart Nginx service
sudo ./run_nginx.sh restart

# Reload configuration (graceful)
sudo ./run_nginx.sh reload

# Test configuration syntax
sudo ./run_nginx.sh test
```

## Testing Tools

To test whether the reverse proxy configuration is working properly, we provide the test server management tool.

### Test Server Management Tool

This tool provides unified management for test web servers. It supports starting, stopping, restarting, and checking the status of test servers on ports 8080, 8081, and 8082:

```bash
# Add execute permission to the script
chmod +x run_test_server.sh

# Start test web servers
./run_test_server.sh start

# Check test server status
./run_test_server.sh status

# Stop test web servers
./run_test_server.sh stop

# Restart test web servers
./run_test_server.sh restart
```

After startup, you can access test pages at the following addresses:
- http://www.gerryyang.com - Should display pages from port 8080
- http://llmnews.gerryyang.com - Should display pages from port 8081
- http://english.gerryyang.com - Should display pages from port 8082

## Common Problem Solutions

### 502 Bad Gateway Error

If you encounter a "502 Bad Gateway" error when accessing the website, it's usually because:

1. **Backend service not running**: Ensure services are running on ports 8080, 8081, and 8082 of 172.19.0.16
   ```bash
   # Check if connection is reachable
   ping 172.19.0.16

   # Test port connectivity
   nc -zv 172.19.0.16 8080
   nc -zv 172.19.0.16 8081
   nc -zv 172.19.0.16 8082
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

You can manually resolve the conflict:

```bash
# Check what is using the port
sudo lsof -i :80

# Stop any process using port 80
sudo fuser -k 80/tcp

# Stop conflicting service
sudo systemctl stop <service-name>

# Restart Nginx
sudo ./run_nginx.sh restart
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
   ```

4. **Test and apply configuration**

   ```bash
   # Test configuration file
   sudo ./run_nginx.sh test
   # Or: sudo nginx -t

   # Restart Nginx
   sudo ./run_nginx.sh restart
   # Or: sudo systemctl restart nginx

   # Enable Nginx at boot
   sudo systemctl enable nginx
   ```

## Usage

- Ensure services on target server (172.19.0.16) are running on ports 8080, 8081, and 8082 respectively
- Access services through:
  - `http://www.gerryyang.com` -> Access service on 172.19.0.16:8080
  - `http://llmnews.gerryyang.com` -> Access service on 172.19.0.16:8081
  - `http://english.gerryyang.com` -> Access service on 172.19.0.16:8082

## Troubleshooting

If services cannot be accessed normally after configuration, try the following steps:

- Check if Nginx is running: `sudo ./run_nginx.sh status` or `systemctl status nginx`
- View Nginx error logs: `sudo tail -f /var/log/nginx/error.log`
- Check if firewall allows port 80: `sudo ufw status` or `sudo firewall-cmd --list-all`
- Restart Nginx service: `sudo ./run_nginx.sh restart`
- Reload configuration: `sudo ./run_nginx.sh reload`
- Test configuration syntax: `sudo ./run_nginx.sh test`
- Confirm domain resolution is correct:
  ```bash
  ping www.gerryyang.com
  ping llmnews.gerryyang.com
  ping english.gerryyang.com
  ```
- Ensure target server is reachable and running services on corresponding ports:
  ```bash
  ping 172.19.0.16
  nc -zv 172.19.0.16 8080
  nc -zv 172.19.0.16 8081
  nc -zv 172.19.0.16 8082
  ```

## Project Files

This project contains the following files:

| File | Description |
|------|-------------|
| `run_nginx.sh` | Main management script - install, start, stop, restart, reload, status, test |
| `run_test_server.sh` | Test server management tool for local testing |
| `nginx.conf` | Nginx reverse proxy configuration file |
| `README.md` | This documentation file |

### Quick Reference

```bash
# Install and configure Nginx
sudo ./run_nginx.sh install

# Manage Nginx service
sudo ./run_nginx.sh start      # Start Nginx
sudo ./run_nginx.sh stop       # Stop Nginx
sudo ./run_nginx.sh restart    # Restart Nginx
sudo ./run_nginx.sh reload     # Reload configuration
sudo ./run_nginx.sh status     # Check service status
sudo ./run_nginx.sh test       # Test configuration syntax

# Manage test servers (for local testing)
./run_test_server.sh start   # Start test servers on ports 8080, 8081, 8082
./run_test_server.sh stop    # Stop test servers
./run_test_server.sh status  # Check test server status
```

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please:
1. Check this README documentation
2. Use `./run_nginx.sh help` for command reference
3. Check Nginx error logs: `sudo tail -f /var/log/nginx/error.log`
