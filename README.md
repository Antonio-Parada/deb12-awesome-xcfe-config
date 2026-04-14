# AwesomeWM + XFCE Setup (deb12-awesome-xcfe-config)

This repository contains the configuration files for a hybrid AwesomeWM and XFCE desktop environment on Debian Bookworm 12.

## Features
- **AwesomeWM** as the window manager (v4.3)
- **XFCE** session components (panel, settings daemon, power manager)
- **Kiosk Mode** via a systemd service starting X on boot.
- **Custom Kiosk Script** for automated session startup.

## Structure
- `dotconfig/awesome/`: AwesomeWM configuration (`rc.lua`).
- `dotconfig/xfce4/`: XFCE configuration files (panel, xfconf settings).
- `etc/systemd/system/kiosk-host.service`: Systemd unit for the kiosk.
- `usr/local/bin/kiosk_host.sh`: Startup script for the X session.
- `etc/X11/xorg.conf`: X11 server configuration.

## Installation / Restore
To apply these configurations:
1. Copy `dotconfig/awesome` to `~/.config/awesome`.
2. Copy `dotconfig/xfce4` to `~/.config/xfce4`.
3. Copy `etc/systemd/system/kiosk-host.service` to `/etc/systemd/system/`.
4. Copy `usr/local/bin/kiosk_host.sh` to `/usr/local/bin/`.
5. Copy `etc/X11/xorg.conf` to `/etc/X11/`.
6. Reload systemd: `systemctl daemon-reload`.
7. Enable the kiosk service: `systemctl enable kiosk-host.service`.

## Known Issues
- `light-locker` might crash if running as root.
- Potential keybinding conflicts between AwesomeWM and XFCE.
