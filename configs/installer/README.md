# Installer

Calamares, copying the live squashfs to disk.

- `settings.conf`, `modules/`, `branding/` go to `/etc/calamares` on the ISO.
- `install-prepare` removes what belongs to the live session (the `user`
  account, automatic login, the installer itself) and records the keyboard
  layout for new accounts.
- `install-bootloader` installs GRUB from the package pool on the medium
  (`live-build/config/package-lists/installer.list.binary`), so installing
  needs no network.
- `live/` is the launcher entry, the sudo rule and the first-boot hint.
