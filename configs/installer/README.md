# Installer

Calamares, copying the live squashfs to disk.

- `settings.conf`, `modules/`, `branding/` go to `/etc/calamares` on the ISO.
- `install-prepare` removes what belongs to the live session (the `user`
  account, automatic login, the installer itself) and records the keyboard
  layout for new accounts.
- `install-bootloader` installs GRUB from the package pool on the medium
  (`live-build/config/package-lists/installer-*.list.binary`), so installing
  needs no network.
- `live/` is the launcher entry, the sudo rule and the first-boot hint.
  `setxkbmap` there passes the installer's keyboard choice to Hyprland, which
  Calamares cannot do itself; without it passwords are typed on the US layout.

GRUB asks for the passphrase of an encrypted disk on a US layout, whatever was
chosen. A passphrase typed in the installer on a layout that moves its
characters will not be accepted there.
