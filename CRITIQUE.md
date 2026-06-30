# Critique of deb12-awesome-xcfe-config

Based on a review of the repository, here is a critique of the project's approach to setting up a hybrid AwesomeWM and XFCE kiosk environment on Debian 12.

## 1. Security: Running X as Root
The most critical issue in this setup is found in `rootfs/etc/systemd/system/kiosk-host.service`. The service is configured to run the X session as `root`:
```ini
[Service]
User=root
Group=root
```
Running a window manager and desktop environment as the root user is highly discouraged, especially for a kiosk. A kiosk is typically an environment exposed to public or untrusted users. If an attacker manages to break out of the kiosk interface, they will immediately have full system privileges. A dedicated unprivileged user should be created for the kiosk session.

## 2. Desktop Environment and Window Manager Conflicts
The project attempts a "hybrid" approach by starting `xfce4-session` and substituting the window manager with AwesomeWM. While this is possible, the current implementation shows signs of conflict and redundancy:

*   **Autostarting:** At the end of `stow-user/awesome/.config/awesome/rc.lua`, several commands are spawned:
    ```lua
    awful.spawn.with_shell("xfsettingsd")
    awful.spawn.with_shell("nm-applet")
    awful.spawn.with_shell("picom -b")
    ```
    If `startxfce4` is used to initialize the session (as seen in `kiosk_host.sh`), XFCE's session manager will automatically start `xfsettingsd` and standard applets like `nm-applet`. Starting them again from AwesomeWM can lead to race conditions, duplicated processes, or settings being applied multiple times.
*   **Failsafe Session Configuration:** The `stow-user/xfce4/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml` defines `awesome` as the failsafe client. This relies on XFCE's legacy session management to launch AwesomeWM, but failsafe sessions are generally a fallback mechanism, not intended as the primary method for replacing a window manager. A better approach would be to properly define `awesome` as the default window manager in XFCE's session settings or use an xsession desktop file.

## 3. "Kiosk" Implementation Flaws
A true kiosk mode typically restricts user actions to a single application or a tightly controlled environment. The current AwesomeWM configuration provides a full desktop experience that defeats the purpose of a kiosk:
*   **Unrestricted Keybindings:** The `rc.lua` contains standard AwesomeWM keybindings that allow launching arbitrary terminals (`Mod4 + Return`), executing commands (`Mod4 + r`), switching tags, moving windows, and logging out (`Mod4 + Shift + q`).
*   **Full Menu and Tasklist:** The Wibar includes a tasklist and a launcher menu providing access to terminals and settings.
In a real kiosk, you would want to strip out almost all window management features, disable terminals, and automatically restart the target kiosk application if it closes.

## 4. Hardcoded Hardware-Specific Configurations
The `rc.lua` file contains a highly specific hardware configuration command:
```lua
awful.spawn.with_shell("xinput map-to-output 'GAOMON Gaomon Tablet Pen stylus' HDMI-1")
```
This is a bad practice for configuration management. It makes the configuration non-portable. If this configuration is deployed on a machine without that specific tablet or an `HDMI-1` output, this command will fail (though silently, it clutters the logs). Hardware-specific setups should be placed in separate scripts or system-wide `xorg.conf.d` snippets, not hardcoded into the window manager's primary configuration.

## 5. Deployment and Stow Inconsistencies
The `Makefile` uses GNU Stow for user configurations but hardcodes the target user environment to `~` (the home directory of the user running the `make` command):
```makefile
stow-user:
	cd stow-user && stow -t ~ awesome
```
However, the systemd service starts the kiosk as `root`. If a normal user runs `make stow-user`, the configurations will be placed in `/home/user/`, but the `startx` command executed by systemd as root will look in `/root/`. This disconnect means the custom AwesomeWM and XFCE configs will likely not be applied to the actual kiosk session unless `make stow-user` is explicitly run with `sudo` (which is generally bad practice for user-level dotfiles).

## Conclusion
The project successfully assembles components for a hybrid environment but struggles with clear separation of concerns, fundamental security practices, and a true understanding of "kiosk mode." The primary focus should be on shifting the kiosk service to an unprivileged user, stripping down the AwesomeWM configuration to restrict actions, and untangling the startup process between XFCE and AwesomeWM.
