# Makefile for deb12-awesome-xcfe-config deployment

.PHONY: install-system stow-user clean

install-system:
	@echo "Deploying system-level files..."
	install -m 644 rootfs/etc/X11/xorg.conf /etc/X11/xorg.conf
	install -m 644 rootfs/etc/systemd/system/kiosk-host.service /etc/systemd/system/kiosk-host.service
	install -m 755 rootfs/usr/local/bin/kiosk_host.sh /usr/local/bin/kiosk_host.sh
	systemctl daemon-reload
	systemctl enable kiosk-host.service
	@echo "System deployment complete."

stow-user:
	@echo "Linking user dotconfigs using GNU Stow..."
	cd stow-user && stow -t ~ awesome
	cd stow-user && stow -t ~ picom
	cd stow-user && stow -t ~ xfce4
	@echo "User configuration stowed."

clean:
	@echo "Removing Stow symlinks..."
	cd stow-user && stow -D -t ~ awesome
	cd stow-user && stow -D -t ~ picom
	cd stow-user && stow -D -t ~ xfce4
	@echo "Cleanup complete."
