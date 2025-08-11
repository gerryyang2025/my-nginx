# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup with Nginx reverse proxy configuration
- Automated installation script for multiple Linux distributions
- Test server tools for development and testing
- Diagnostic tools for troubleshooting common issues
- Port conflict resolution utilities
- Comprehensive documentation and README

### Changed
- All scripts translated from Chinese to English for international accessibility
- Improved error handling and user feedback in installation scripts
- Enhanced configuration conflict detection and resolution

### Fixed
- Port conflict detection in Ubuntu/Debian systems
- Configuration file backup and restoration procedures
- Service startup verification and error reporting

## [1.0.0] - 2024-12-19

### Added
- Initial release of Nginx Reverse Proxy Setup
- Support for Debian/Ubuntu and CentOS/RHEL/Fedora systems
- Multi-domain reverse proxy configuration
- Automated installation and configuration scripts
- Built-in testing and diagnostic tools
- Comprehensive documentation and troubleshooting guides

### Features
- **install_nginx.sh**: Automated Nginx installation and configuration
- **check_nginx_backend.sh**: Diagnostic tool for 502 errors and connectivity issues
- **fix_nginx_port.sh**: Port conflict detection and resolution
- **start_test_server.sh**: Test web server startup for development
- **stop_test_server.sh**: Test web server shutdown utility
- **nginx.conf**: Sample Nginx configuration template

### Supported Systems
- Debian/Ubuntu (apt-based)
- CentOS/RHEL/Fedora (yum/dnf-based)
- Other Linux distributions with manual configuration

### Configuration
- Domain: www.gerryyang.com → Backend: 172.19.0.16:8080
- Domain: llmnews.gerryyang.com → Backend: 172.19.0.16:8081
- Automatic conflict resolution and port management
- Comprehensive error handling and logging

---

## Version History

- **1.0.0**: Initial release with full functionality
- **Unreleased**: Development version with ongoing improvements

## Notes

- All scripts require root/sudo privileges for installation
- Test servers are intended for development use only
- Production deployments should use proper SSL certificates
- Regular backups of configuration files are recommended
