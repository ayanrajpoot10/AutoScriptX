# AutoScriptX

<p align="left">
    <a href="LICENSE">
        <img alt="MIT License" src="https://img.shields.io/github/license/ayanrajpoot10/AutoScriptX?style=for-the-badge&color=4caf50">
    </a>
    <a href="#">
        <img alt="Linux Supported" src="https://img.shields.io/badge/Linux-Supported-1976d2?style=for-the-badge&logo=linux&logoColor=white">
    </a>
</p>


## Overview

**AutoScriptX** is a powerful, automated VPS management suite designed to simplify the deployment and administration of SSH, WebSocket, SSL, and related services. It provides a modern, interactive CLI menu for managing user accounts, services, domains, and system information, making it ideal for advanced VPS users.

---

## Images


<div align="center">
  <table>
    <tr>
      <td><img src="images/main-menu.png" alt="Main Menu" width="350"><br><sub>Main Menu</sub></td>
      <td><img src="images/create-account.png" alt="Create Account" width="350"><br><sub>Create Account</sub></td>
      <td><img src="images/edit-banner.png" alt="Edit Banner" width="350"><br><sub>Edit Banner</sub></td>
    </tr>
    <tr>
      <td><img src="images/edit-101-response.png" alt="Edit 101 Response" width="350"><br><sub>Edit 101 Response</sub></td>
      <td><img src="images/lock-unlock.png" alt="Lock/Unlock Account" width="350"><br><sub>Lock/Unlock Account</sub></td>
      <td><img src="images/manage-services.png" alt="Manage Services" width="350"><br><sub>Manage Services</sub></td>
    </tr>
    <tr>
      <td><img src="images/change-domain.png" alt="Change Domain" width="350"><br><sub>Change Domain</sub></td>
    </tr>
  </table>
</div>


---


## Features

- **Automated Installation**: One-command setup for all dependencies and configurations.
- **SSH & WebSocket Management**: Create, renew, lock/unlock, and delete SSH accounts with WebSocket and SSL support.
- **Service Control**: Start, stop, and restart core services (SSH, Nginx, Dropbear, Stunnel, WebSocket Proxy, etc.).
- **Domain & SSL Automation**: Easily set or change your VPS domain and auto-issue SSL certificates.
- **System Information**: View detailed system, network, and service status.
- **Banner & Response Editing**: Customize SSH banners and HTTP 101 responses.
- **Scheduled Maintenance**: Automated cron jobs for rebooting and cleaning expired accounts.
- **Modern & Interactive UI**: Features a user-friendly, interactive CLI menu for seamless VPS management.
 **High Performance WebSocket Proxy**: Handles high load more efficiently than other scripts by using a Go-based WebSocket proxy instead of Python.
 **SSHGuard Protection**: Protects your SSH service from brute-force attacks automatically.

---


## Installation

> **Note:** AutoScriptX is intended for fresh Ubuntu/Debian VPS environments. **You must run as root.**
> 
> If not already root, run:
> 
> ```bash
> sudo su
> ```

Then install AutoScriptX with:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/ayanrajpoot10/AutoScriptX/main/install.sh)
```

Follow the prompts to set your domain and complete the setup.

---

## Usage


After installation, launch the main menu with either command:

```bash
autoscriptx
# or
asx
```

### Menu Options
- Create, delete, renew, lock/unlock SSH accounts
- Edit SSH banner and HTTP 101 response
- Change domain and auto-issue SSL
- Manage services (start/stop/restart)
- View system information

---


## Requirements


- Ubuntu/Debian VPS (root access)
- One domain name with an A record pointing to your VPS IP address
- Internet connection

The installer will automatically set up:
- Nginx, Dropbear, Stunnel, SSHGuard, badvpn-udpgw, ws-proxy

---

## Security

- Only run on trusted, clean VPS environments.
- Regularly update your system and AutoScriptX.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
