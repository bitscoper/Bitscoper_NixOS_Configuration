<div align="center">

# Bitscoper NixOS Configuration

My NixOS Configuration

</div>

---

- **Channel:** [NixOS Unstable](https://nixos.org/channels/nixos-unstable)
- **Bootloader:** [systemd-boot](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix)
- **Kernel:** [Linux Zen](https://github.com/zen-kernel/zen-kernel/)
- **Shells:** [Bash](https://cgit.git.savannah.gnu.org/cgit/bash.git/), and [fish](https://github.com/fish-shell/fish-shell/)
- **Init System / Service Manager:** [systemd](https://github.com/systemd/systemd/)
- **Message Bus:** [D-Bus](https://gitlab.freedesktop.org/dbus/dbus/)
- **Boot Screen:** [Plymouth](https://gitlab.freedesktop.org/plymouth/plymouth/)
- **Network Configurator:** [NetworkManager](https://github.com/NetworkManager/NetworkManager/)
- **Display Server Protocol:** [Wayland](https://gitlab.freedesktop.org/wayland/wayland/) (with Xwayland Support)
- **Login Manager / Greeter:** [greetd](https://git.sr.ht/~kennylevinsen/greetd/) -> [tuigreet](https://github.com/apognu/tuigreet)
- **Session Manager:** [Universal Wayland Session Manager (UWSM)](https://github.com/Vladimir-csp/uwsm/)
- **Wayland Compositor:** [Hyprland](https://github.com/hyprwm/Hyprland/)
- **Low-Level Multimedia Framework:** [PipeWire](https://github.com/PipeWire/pipewire/)
- **Bluetooth Protocol Stack:** [BlueZ](https://github.com/bluez/bluez/)

---

- **[Polkit](https://github.com/polkit-org/polkit/) Agent:** [Soteria](https://github.com/imvaskel/soteria/)
- **Secret Service / Keyring:** [GNOME Keyring](https://gitlab.gnome.org/GNOME/gnome-keyring/)
- **Password Manager:** [KeePassXC](https://github.com/keepassxreboot/keepassxc/)
- **Status Bar:** [Waybar](https://github.com/Alexays/Waybar/)
- **Notification Daemon and Center:** [Sway Notification Center](https://github.com/ErikReider/SwayNotificationCenter/)
- **Input Method (IM) Framework:** [Fcitx 5](https://github.com/fcitx/fcitx5/)
- **Idle Daemon:** [hypridle](https://github.com/hyprwm/hypridle/)
- **Screen Locker:** [hyprlock](https://github.com/hyprwm/hyprlock/)
- **Menu / Launcher:** [wofi](https://hg.sr.ht/~scoopta/wofi)
- **Clipboard History Manager:** [cliphist](https://github.com/sentriz/cliphist/)
- **On-Screen Display (OSD):** [Syshud](https://github.com/System64fumo/syshud/)

---

- **Font Family:** [Noto Nerd](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Noto/)
- **Cursor:** [Bibata Modern Classic](https://github.com/ful1e5/Bibata_Cursor/)
- **GTK Theme:** [Adwaita Dark](https://gitlab.gnome.org/GNOME/gtk/-/blob/gtk-3-24/gtk/theme/Adwaita/gtk-contained-dark.css)
- **Wallpaper Utility:** [hyprpaper](https://github.com/hyprwm/hyprpaper/)

---

- **Terminal Emulator:** [Tilix](https://github.com/gnunn1/tilix/)
- **Font Viewer**: [Fonts](https://gitlab.gnome.org/GNOME/gnome-font-viewer/)
- **Disk Partition Editors:** [GNOME Disks](https://gitlab.gnome.org/GNOME/gnome-disk-utility/), and [GParted](https://gitlab.gnome.org/GNOME/gparted/)
- **File Manager:** [Nautilus](https://gitlab.gnome.org/GNOME/nautilus/)
- **Archive Manager:** [File Roller](https://gitlab.gnome.org/GNOME/file-roller/)

---

- **Image Viewer:** [Eye of GNOME (EOG)](https://gitlab.gnome.org/GNOME/eog/)
- **Media Player:** [VLC media player](https://code.videolan.org/videolan/vlc/)
- **Software Defined Radio (SDR) Clients:** [SDRangel](https://github.com/f4exb/sdrangel/), and [SDR++](https://github.com/AlexandreRouma/SDRPlusPlus/)

---

- **Text Editors:** [VSCodium](https://github.com/VSCodium/vscodium/), and [nano](https://cgit.git.savannah.gnu.org/cgit/nano.git/)
- **Subtitle Editor:** [Subtitle Edit](https://github.com/SubtitleEdit/subtitleedit/)
- **Screenshot Utility:** [slurp](https://github.com/emersion/slurp/) + [grim](https://github.com/emersion/grim/)
- **Image Editor:** [GNU Image Manipulation Program (GIMP)](https://gitlab.gnome.org/GNOME/gimp/)
- **Audio Recorder and Editor:** [Audacity](https://github.com/audacity/audacity/)
- **Video Recorder and Streamer:** [OBS Studio](https://github.com/obsproject/obs-studio/)
- **3D Amination Tool and Video Editor:** [Blender](https://projects.blender.org/blender/blender.git)
- **Office Suite:** [LibreOffice](https://git.libreoffice.org/core/)
- **Electronics Designers:** [KiCad EDA](https://gitlab.com/kicad/code/kicad/), and [Fritzing](https://github.com/fritzing/fritzing-app/)

---

- **Web Browsers:** [Ungoogled Chromium](https://github.com/ungoogled-software/ungoogled-chromium/), and [Tor Browser](https://gitlab.torproject.org/tpo/applications/tor-browser/)
- **Email Client:** [Thunderbird](https://hg-edge.mozilla.org/comm-central/)
- **Database Client:** [DBeaver](https://github.com/dbeaver/dbeaver/)
- **Torrent Client:** [qBittorrent](https://github.com/qbittorrent/qBittorrent/)

---

- **Calculator:** [Qalculate!](https://github.com/Qalculate/qalculate-gtk/)
- **Color Picker and Formatter:** [Eyedropper](https://github.com/FineFindus/eyedropper/)

---

- **Virtual Network Computing (VNC) Server:** [wayvnc](https://github.com/any1/wayvnc/)
- **Domain Name System (DNS) Server:** [Berkeley Internet Name Domain (BIND)](https://gitlab.isc.org/isc-projects/bind9/)
- **Print Server:** [CUPS](https://github.com/OpenPrinting/cups/)
- **Memory Object Cache Server:** [memcached](https://github.com/memcached/memcached/)
- **Database Servers:** [PostgreSQL](https://git.postgresql.org/gitweb/?p=postgresql.git), and [MariaDB](https://github.com/MariaDB/server/)
- **Mail Transfer Agent (MTA) Server:** [Postfix](http://ftp.porcupine.org/mirrors/postfix-release/index.html)
- **Internet Message Access Protocol (IMAP) Server:** [Dovecot](https://github.com/dovecot/core/)
- **Domain Keys Identified Mail (DKIM) Authentication Server:** [OpenDKIM](https://github.com/trusteddomainproject/OpenDKIM/)
- **Media Server:** [Jellyfin](https://github.com/jellyfin/jellyfin/)

---

- **Virtual Machine (VM) Hypervisor:** [QEMU](https://github.com/qemu/qemu/)  -> KVM
- **Container Engine:** [Podman](https://github.com/containers/podman/) -> with Docker Compatibility
- **Android Container Environment:** [Waydroid](https://github.com/waydroid/waydroid/)

---

And many more ...
