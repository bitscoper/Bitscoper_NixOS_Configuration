# By Abdullah As-Sadeed

{ config
, pkgs
, ...
}:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/refs/heads/master.tar.gz";

  secrets = import ./secrets.nix;

  # existingLibraryPaths = builtins.getEnv "LD_LIBRARY_PATH";
in
{
  imports = [
    (import "${home-manager}/nixos")
    ./hardware-configuration.nix
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 2;

      systemd-boot = {
        enable = true;
        consoleMode = "max";
        configurationLimit = null;
        memtest86.enable = true;
      };
    };

    initrd = {
      enable = true;
      luks.devices."luks-023f8417-62dd-4e65-b327-6c33b065486b".device = "/dev/disk/by-uuid/023f8417-62dd-4e65-b327-6c33b065486b";

      systemd = {
        enable = true;
      };

      network.ssh.enable = true;

      verbose = true;
    };

    kernelPackages = pkgs.linuxPackages_zen;
    extraModprobeConfig = "options kvm_intel nested=1";
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "boot.shell_on_fail"
      "rd.systemd.show_status=true"
      # "rd.udev.log_level=3"
      # "udev.log_priority=3"
    ];
    consoleLogLevel = 5; # KERN_NOTICE

    tmp.cleanOnBoot = true;

    plymouth = {
      enable = true;
      themePackages = [
        pkgs.nixos-bgrt-plymouth
      ];
      theme = "nixos-bgrt";
      extraConfig = ''
        UseFirmwareBackground=true
      '';
    };
  };

  time = {
    timeZone = "Asia/Dhaka";
    hardwareClockInLocalTime = true;
  };

  system = {
    switch.enable = true;

    autoUpgrade = {
      enable = false;
      channel = "https://nixos.org/channels/nixos-unstable";
      operation = "boot";
      allowReboot = false;
    };

    activationScripts = { };

    userActivationScripts = {
      stdio = {
        text = '' '';
        deps = [

        ];
      };
    };
  };

  nix = {
    enable = true;
    settings = {
      experimental-features = [
        "nix-command"
      ];
      # max-jobs = 1;
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };

    # overlays = [
    #
    # ];
  };

  appstream.enable = true;

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
    supportedLocales = [
      "all"
    ];

    inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        waylandFrontend = true;
        plasma6Support = true;

        addons = with pkgs; [
          fcitx5-openbangla-keyboard
        ];
      };
    };
  };

  networking = {
    hostName = "Bitscoper-WorkStation";

    networkmanager.enable = true;

    firewall = {
      enable = false;
      allowPing = true;
      allowedTCPPorts = [

      ];
      allowedUDPPorts = [

      ];
    };
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    pulseaudio.enable = false;

    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
      ];
    };

    sensor.hddtemp = {
      enable = true;
      unit = "C";
      drives = [
        "/dev/disk/by-path/*"
      ];
    };

    rtl-sdr.enable = true;

    sane = {
      enable = true;
      openFirewall = true;
    };
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };
      };
    };
    spiceUSBRedirection.enable = true;

    containers.enable = true;

    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    waydroid.enable = true;
  };

  systemd = {
    packages = with pkgs; [
      cloudflare-warp
    ];
    targets.multi-user.wants = [
      "warp-svc.service"
    ];
  };

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };

    fwupd.enable = true;

    power-profiles-daemon.enable = true;

    logind = {
      killUserProcesses = true;

      lidSwitch = "ignore";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";

      powerKey = "poweroff";
      powerKeyLongPress = "poweroff";

      rebootKey = "reboot";
      rebootKeyLongPress = "reboot";

      suspendKey = "ignore";
      suspendKeyLongPress = "ignore";

      hibernateKey = "ignore";
      hibernateKeyLongPress = "ignore";
    };

    dbus.enable = true;

    displayManager = {
      enable = true;
      defaultSession = "hyprland-uwsm";
      preStart = '' '';

      autoLogin = {
        enable = false;
        user = null;
      };

      logToJournal = true;
      logToFile = true;
    };

    greetd = {
      enable = true;
      restart = true;

      settings = {
        default_session = {
          command = "tuigreet --time --user-menu --greet-align center --asterisks --asterisks-char \"*\" --cmd -- uwsm start -S -F /run/current-system/sw/bin/Hyprland";
          user = "greeter";
        };
      };
    };

    libinput.enable = true;

    pipewire = {
      enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;

      pulse.enable = true;

      jack.enable = true;

      wireplumber.extraConfig.bluetoothEnhancements = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [
            "a2dp_sink"
            "a2dp_source"
            "bap_sink"
            "bap_source"
            "hfp_ag"
            "hfp_hf"
            "hsp_ag"
            "hsp_hs"
          ];
          "bluez5.codecs" = [
            "aac"
            "aptx"
            "aptx_hd"
            "aptx_ll"
            "aptx_ll_duplex"
            "faststream"
            "faststream_duplex"
            "lc3"
            "lc3plus_h3"
            "ldac"
            "opus_05"
            "opus_05_51"
            "opus_05_71"
            "opus_05_duplex"
            "opus_05_pro"
            "sbc"
            "sbc_xq"
          ];
        };
      };
    };

    udev.packages = with pkgs; [
      android-udev-rules
      game-devices-udev-rules
      rtl-sdr
      usb-blaster-udev-rules
    ];

    avahi = {
      enable = true;

      ipv4 = true;
      ipv6 = true;
      nssmdns4 = true;
      nssmdns6 = true;

      wideArea = true;

      publish = {
        enable = true;
        domain = true;
        addresses = true;
        workstation = true;
        hinfo = true;
        userServices = true;
      };

      domainName = "Bitscoper";
      hostName = config.networking.hostName;

      openFirewall = true;
    };

    openssh = {
      enable = true;

      listenAddresses = [
        {
          addr = "0.0.0.0";
        }
      ];
      ports = [
        22
      ];
      allowSFTP = true;

      banner = "Bitscoper-WorkStation";

      authorizedKeysInHomedir = true;

      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
        X11Forwarding = false;
        StrictModes = true;
        UseDns = true;
        LogLevel = "ERROR";
      };

      openFirewall = true;
    };
    sshd.enable = true;

    system-config-printer.enable = true;

    printing = {
      enable = true;

      listenAddresses = [
        "*:631"
      ];
      browsing = true;
      webInterface = true;
      allowFrom = [
        "all"
      ];
      defaultShared = true;

      cups-pdf.enable = true;
      drivers = with pkgs; [
        gutenprint
      ];

      startWhenNeeded = true;

      extraConf = ''
        DefaultLanguage en
        ServerName Bitscoper-WorkStation
        ServerAlias *
        ServerTokens Full
        ServerAdmin bitscoper@Bitscoper-WorkStation
        BrowseLocalProtocols all
        BrowseWebIF On
        HostNameLookups On
        AccessLogLevel config
        AutoPurgeJobs Yes
        PreserveJobHistory Off
        PreserveJobFiles Off
        DirtyCleanInterval 30
        LogTimeFormat standard
      '';

      logLevel = "warn";

      openFirewall = true;
    };
    ipp-usb.enable = true;

    cockpit = {
      enable = true;
      port = 9090;
      openFirewall = true;
    };

    phpfpm = {
      phpOptions = ''
        default_charset = "UTF-8"
        error_reporting = E_ALL
        display_errors = Off
        log_errors = On
        cgi.force_redirect = 1
        expose_php = On
        file_uploads = On
        session.cookie_lifetime = 0
        session.use_cookies = 1
        session.use_only_cookies = 1
        session.use_strict_mode = 1
        session.cookie_httponly = 1
        session.cookie_secure = 1
        session.cookie_samesite = "Strict"
        session.gc_maxlifetime = 43200
        session.use_trans_sid = O
        session.cache_limiter = nocache
        session.sid_length = 248
      '';
    };

    postgresql = {
      package = pkgs.postgresql;
      enable = true;
      enableTCPIP = true;
      settings = pkgs.lib.mkForce {
        listen_addresses = "*";
        port = 5432;
        jit = true;
      };
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 0.0.0.0/0 md5
        host all all ::/0 md5
        local replication all trust
        host replication all 0.0.0.0/0 md5
        host replication all ::/0 md5
      '';
      initialScript = pkgs.writeText "initScript" ''
        ALTER USER postgres WITH PASSWORD '${secrets.password_1_of_bitscoper}';
      '';
      checkConfig = true;
    };

    mysql = {
      package = pkgs.mariadb;
      enable = true;
      settings = {
        mysqld = {
          bind-address = "0.0.0.0";
          port = 3306;
          sql_mode = "";
        };
      };
      initialScript = pkgs.writeText "initScript" ''
        grant all privileges on *.* to 'root'@'%' identified by password '${secrets.hashed_password_1_of_bitscoper}' with grant option;
        DELETE FROM mysql.user WHERE `Host`='localhost' AND `User`='root';
        flush privileges;
      '';
    };

    memcached = {
      enable = true;
      listen = "0.0.0.0";
      port = 11211;
      enableUnixSocket = false;
      maxMemory = 64; # Megabytes
      maxConnections = 256;
    };

    bind = {
      enable = false;
      listenOn = [
        "any"
      ];
      ipv4Only = false;
      listenOnIpv6 = [
        "any"
      ];
      cacheNetworks = [
        "127.0.0.0/24"
        "::1/128"
      ];
      extraOptions = ''
        recursion no;
      '';
    };

    icecast = {
      enable = true;
      hostname = "Bitscoper-WorkStation";
      listen = {
        address = "0.0.0.0";
        port = 17101;
      };
      admin = {
        user = "bitscoper";
        password = secrets.password_1_of_bitscoper;
      };
      extraConf = ''
        <location>Bitscoper-WorkStation</location>
        <admin>bitscoper@Bitscoper-WorkStation</admin>
        <authentication>
          <source-password>${secrets.password_2_of_bitscoper}</source-password>
          <relay-password>${secrets.password_2_of_bitscoper}</relay-password>
        </authentication>
        <directory>
          <yp-url-timeout>15</yp-url-timeout>
          <yp-url>http://dir.xiph.org/cgi-bin/yp-cgi</yp-url>
        </directory>
        <logging>
          <loglevel>2</loglevel>
        </logging>
        <server-id>Bitscoper-WorkStation</server-id>
      '';
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
    };
    ollama = {
      enable = true;
      host = "0.0.0.0";
      port = 11434;
      openFirewall = true;
    };
  };

  xdg = {
    mime = {
      enable = true;

      addedAssociations = { };

      removedAssociations = { };

      defaultApplications = {
        "application/pdf" = "firefox.desktop";
      };
    };

    icons.enable = true;
    sounds.enable = true;

    menus.enable = true;
    autostart.enable = true;

    terminal-exec.enable = true;

    portal = {
      enable = true;
      xdgOpenUsePortal = false; # Opening Programs
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
      ];
    };
  };

  security = {
    rtkit.enable = true;

    polkit = {
      enable = true;
    };

    wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
  };

  users = {
    enforceIdUniqueness = true;
    mutableUsers = true;

    motd = "Welcome";

    users.bitscoper = {
      isNormalUser = true;

      name = "bitscoper";
      description = "Abdullah As-Sadeed"; # Full Name

      extraGroups = [
        "adbusers"
        "audio"
        "dialout"
        "input"
        "jellyfin"
        "kvm"
        "libvirtd"
        "lp"
        "networkmanager"
        "plugdev"
        "podman"
        "qemu-libvirtd"
        "scanner"
        "tty"
        "uucp"
        "video"
        "wheel"
        "wireshark"
      ];
    };
  };

  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [

      ];
    };

    uwsm = {
      enable = true;
      waylandCompositors = {
        hyprland = {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/Hyprland";
        };
      };
    };

    hyprland = {
      enable = true;
      withUWSM = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };

    hyprlock.enable = true;

    appimage.enable = true;

    nix-index.enableBashIntegration = true;

    bash = {
      completion.enable = true;
      enableLsColors = true;

      shellAliases = {
        clean_build = "sudo nix-channel --update && sudo nix-env -u --always && sudo rm -rf /nix/var/nix/gcroots/auto/* && sudo nix-collect-garbage -d && nix-collect-garbage -d && sudo nix-store --gc && sudo nixos-rebuild switch --upgrade-all";
      };

      loginShellInit = ''
        setfacl --modify user:jellyfin:--x ~
      '';

      shellInit = '' '';

      interactiveShellInit = ''
        PROMPT_COMMAND="history -a"
      '';
    };

    ssh = {
      startAgent = true;
      agentTimeout = null;
    };

    gnupg = {
      agent = {
        enable = true;

        enableBrowserSocket = true;
        enableExtraSocket = true;
        enableSSHSupport = false;

        pinentryPackage = pkgs.pinentry-rofi;
      };

      dirmngr.enable = true;
    };

    adb.enable = true;

    waybar.enable = true;

    nm-applet = {
      enable = true;
      indicator = true;
    };

    virt-manager.enable = true;

    system-config-printer.enable = true;

    neovim = {
      enable = true;

      withPython3 = true;
      withRuby = false;
      withNodeJs = false;

      vimAlias = true;
      viAlias = true;

      defaultEditor = true;
    };

    nano.enable = false;

    firefox = {
      enable = true;
      languagePacks = [
        "en-US"
      ];
    };

    thunderbird.enable = true;

    dconf = {
      enable = true;
      profiles.user.databases = [
        {
          lockAll = true;
          settings = {
            "system/locale" = {
              region = "en_US.UTF-8";
            };

            "org/virt-manager/virt-manager/connections" = {
              autoconnect = [
                "qemu:///system"
              ];
              uris = [
                "qemu:///system"
              ];
            };
            "org/virt-manager/virt-manager" = {
              xmleditor-enabled = true;
            };
            "org/virt-manager/virt-manager/stats" = {
              enable-cpu-poll = true;
              enable-disk-poll = true;
              enable-memory-poll = true;
              enable-net-poll = true;
            };
            "org/virt-manager/virt-manager/confirm" = {
              delete-storage = true;
              forcepoweroff = true;
              pause = true;
              poweroff = true;
              removedev = true;
              unapplied-dev = true;
            };
            "org/virt-manager/virt-manager/console" = {
              auto-redirect = false;
              autoconnect = true;
            };
            "org/virt-manager/virt-manager/vmlist-fields" = {
              cpu-usage = true;
              disk-usage = true;
              host-cpu-usage = true;
              memory-usage = true;
              network-traffic = true;
            };
            "org/virt-manager/virt-manager/new-vm" = {
              cpu-default = "host-passthrough";
            };

            "com/github/huluti/Curtail" = {
              file-attributes = true;
              metadata = false;
              new-file = true;
              recursive = true;
            };

            "org/gnome/desktop/interface" = {
              gtk-theme = "Adwaita";
              icon-theme = "Flat-Remix-Red-Dark";
              document-font-name = "Noto Sans Medium 11";
              font-name = "Noto Sans Medium 11";
              monospace-font-name = "Noto Sans Mono Medium 11";
            };
          };
        }
      ];
    };
  };

  environment = {
    variables = pkgs.lib.mkForce {
      # LD_LIBRARY_PATH = "${pkgs.glib.out}/lib/:${pkgs.libGL}/lib/:${pkgs.stdenv.cc.cc.lib}/lib:${existingLibraryPaths}";
    };

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      CHROME_EXECUTABLE = "chromium";
    };

    systemPackages = with pkgs; [
      # gimp-with-plugins
      # gpredict
      # xoscope
      acl
      agi
      android-backup-extractor
      android-tools
      arduino-cli
      arduino-core
      arduino-ide
      arduino-language-server
      aribb24
      aribb25
      audacity
      avrdude
      bat
      bind
      bleachbit
      blender
      bluez
      bluez-tools
      bridge-utils
      brightnessctl
      btop
      btrfs-progs
      butt
      cargo
      clinfo
      cloudflare-warp
      cmake
      cockpit
      cryptsetup
      cups
      cups-filters
      cups-pdf-to-pdf
      cups-printers
      curl
      curtail
      d-spy
      dart
      dbeaver-bin
      dbus
      dconf-editor
      dive
      dmg2img
      dovecot
      esptool
      exfatprogs
      faac
      faad2
      fd
      fdk_aac
      ffmpeg-full
      fh
      file
      flutter
      fritzing
      fwupd
      fwupd-efi
      gcc
      gdb
      ghfetch
      git
      git-doc
      glib
      glibc
      gnumake
      gource
      gpsd
      gradle
      gradle-completion
      greetd.tuigreet
      guestfs-tools
      gzip
      hyprpaper
      hyprpicker
      hyprpolkitagent
      iconv
      iftop
      inotify-tools
      jdk
      jellyfin-media-player
      keepassxc
      kitty
      kompose
      kubectl
      kubernetes
      kubernetes-helm
      libGL
      libaom
      libappimage
      libde265
      libdvdcss
      libdvdnav
      libdvdread
      libgcc
      libgpg-error
      libguestfs
      libheif
      libiconvReal
      libnotify
      libopus
      libosinfo
      libreoffice-fresh
      libtinfo
      libusb1
      libuuid
      libva-utils
      libvirt
      libvpx
      libwebp
      logrotate
      lsof
      luksmeta
      lynis
      mattermost-desktop
      memcached
      mixxx
      nano
      neofetch
      ninja
      nix-bash-completions
      nix-diff
      nix-index
      nixos-icons
      nixpkgs-fmt
      nmap
      obs-studio
      onedrive
      onionshare-gui
      opendkim
      openssl
      patchelf
      pavucontrol
      pcre
      pgadmin4-desktopmode
      php84
      pipewire
      pkg-config
      platformio
      platformio-core
      playerctl
      podman
      podman-compose
      podman-tui
      postfix
      python313Full
      qbittorrent
      qpwgraph
      rar
      readline
      ripgrep
      rofi-wayland
      rpPPPoE
      rtl-sdr-librtlsdr
      sane-backends
      schroedinger
      screen
      sdrangel
      sdrpp
      smartmontools
      spice-gtk
      spice-protocol
      superfile
      swtpm
      telegram-desktop
      texliveFull
      thermald
      tk
      tor-browser
      tree
      tree-sitter
      undollar
      ungoogled-chromium
      unicode-emoji
      universal-android-debloater
      unrar
      unzip
      usbtop
      usbutils
      virtio-win
      virtiofsd
      vlc
      vlc-bittorrent
      vscode-js-debug
      waybar-mpris
      waydroid
      wayland
      wayland-protocols
      wayland-utils
      wev
      wget
      wireplumber
      wireshark
      wl-clipboard
      wordpress
      wpscan
      x264
      x265
      xdg-user-dirs
      xdg-utils
      xfsprogs
      xorg.xhost
      xvidcore
      yaml-language-server
      yt-dlp
      zip
      (vscode-with-extensions.override {
        # vscode = vscodium;
        vscodeExtensions = with vscode-extensions; [
          aaron-bond.better-comments
          adpyke.codesnap
          albymor.increment-selection
          alefragnani.bookmarks
          alexisvt.flutter-snippets
          bierner.github-markdown-preview
          bierner.markdown-mermaid
          christian-kohler.path-intellisense
          codezombiech.gitignore
          coolbear.systemd-unit-file
          dart-code.dart-code
          dart-code.flutter
          davidanson.vscode-markdownlint
          davidlday.languagetool-linter
          devsense.phptools-vscode
          devsense.profiler-php-vscode
          ecmel.vscode-html-css
          esbenp.prettier-vscode
          firefox-devtools.vscode-firefox-debug
          formulahendry.auto-close-tag
          formulahendry.auto-rename-tag
          foxundermoon.shell-format
          github.copilot
          github.copilot-chat
          github.vscode-github-actions
          github.vscode-pull-request-github
          grapecity.gc-excelviewer
          gruntfuggly.todo-tree
          ibm.output-colorizer
          irongeek.vscode-env
          james-yu.latex-workshop
          jnoortheen.nix-ide
          jock.svg
          kamikillerto.vscode-colorize
          mads-hartmann.bash-ide-vscode
          mechatroner.rainbow-csv
          mishkinf.goto-next-previous-member
          moshfeu.compare-folders
          ms-azuretools.vscode-docker
          ms-kubernetes-tools.vscode-kubernetes-tools
          ms-python.black-formatter
          ms-python.debugpy
          ms-python.python
          ms-toolsai.datawrangler
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          ms-vscode.cpptools
          ms-vscode.hexeditor
          ms-vscode.live-server
          ms-vscode.makefile-tools
          oderwat.indent-rainbow
          redhat.vscode-xml
          redhat.vscode-yaml
          ryu1kn.partial-diff
          shardulm94.trailing-spaces
          spywhere.guides
          tamasfe.even-better-toml
          timonwong.shellcheck
          tyriar.sort-lines
          vincaslt.highlight-matching-tag
          visualstudioexptteam.intellicode-api-usage-examples
          visualstudioexptteam.vscodeintellicode
          vscjava.vscode-gradle
          wmaurer.change-case
          xdebug.php-debug
          zainchen.json
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "vscode-sort-json";
            publisher = "richie5um2";
            version = "1.20.0";
            sha256 = "Jobx5Pf4SYQVR2I4207RSSP9I85qtVY6/2Nvs/Vvi/0=";
          }
          {
            name = "platformio-ide";
            publisher = "platformio";
            version = "3.3.3";
            sha256 = "pcWKBqtpU7DVpiT7UF6Zi+YUKknyjtXFEf5nL9+xuSo=";
          }
          {
            name = "vscode-serial-monitor";
            publisher = "ms-vscode";
            version = "0.13.1";
            sha256 = "qZKCNG5EdMwzE9y3WVxaPMdTP9Y0xbe8kozjU7v44OI=";
          }
        ];
      })
    ] ++
    (with gst_all_1; [
      gst-editing-services
      gst-libav
      gst-plugins-bad
      gst-plugins-base
      gst-plugins-good
      gst-plugins-ugly
      gst-rtsp-server
      gst-vaapi
      gstreamer
    ])
    ++
    # (with androidenv.androidPkgs; [
    #   # build-tools
    #   emulator
    #   platform-tools
    #   tools
    # ]) ++
    (with php84Extensions; [
      ast
      bz2
      calendar
      ctype
      curl
      dba
      dom
      ds
      enchant
      event
      exif
      ffi
      fileinfo
      filter
      ftp
      gd
      gettext
      gnupg
      grpc
      iconv
      imagick
      imap
      inotify
      intl
      ldap
      # mailparse
      mbstring
      memcached
      meminfo
      memprof
      mysqli
      mysqlnd
      opcache
      openssl
      pcntl
      pdo
      pdo_mysql
      pdo_pgsql
      pgsql
      posix
      pspell
      readline
      session
      simplexml
      smbclient
      sockets
      sodium
      tokenizer
      uuid
      vld
      xdebug
      xml
      xmlreader
      xmlwriter
      xsl
      # yaml
      zip
      zlib
    ]) ++
    (with php84Packages; [

    ]) ++
    (with python313Packages; [
      black
      matplotlib
      numpy
      pandas
      pillow
      pip
      pyserial
      seaborn
      tkinter
    ]) ++
    (with texlivePackages; [
      latex
      latex-fonts
      latex-git-log
      latex-papersize
      latexbangla
      latexbug
      latexcheat
      latexcolors
      latexconfig
      latexdemo
      latexdiff
      latexfileversion
      latexgit
      latexindent
      latexmk
      latexpand
    ]) ++
    (with lua54Packages; [
      lua
      luarocks
    ]) ++
    (with tree-sitter-grammars; [
      tree-sitter-bash
      tree-sitter-c
      tree-sitter-cmake
      tree-sitter-comment
      tree-sitter-cpp
      tree-sitter-css
      tree-sitter-dart
      tree-sitter-dockerfile
      tree-sitter-html
      tree-sitter-http
      tree-sitter-javascript
      tree-sitter-json
      tree-sitter-latex
      tree-sitter-lua
      tree-sitter-make
      tree-sitter-markdown
      tree-sitter-markdown-inline
      tree-sitter-nix
      tree-sitter-php
      tree-sitter-python
      tree-sitter-regex
      tree-sitter-sql
      tree-sitter-toml
      tree-sitter-yaml
    ]);
  };

  fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [
      corefonts
      nerd-fonts.noto
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      noto-fonts-lgc-plus
    ];
  };

  documentation = {
    enable = true;
    dev.enable = true;
    doc.enable = true;
    info.enable = true;

    man = {
      enable = true;
      generateCaches = true;
      man-db.enable = true;
    };

    nixos = {
      enable = true;
      includeAllModules = true;
      options.warningsAreErrors = false;
    };
  };

  home-manager.users.bitscoper = {
    wayland.windowManager.hyprland = {
      systemd.enable = false;

      plugins = [ ];

      settings = { };
    };

    programs = {
      git = {
        enable = true;
        userName = "Abdullah As-Sadeed";
        userEmail = "bitscoper@gmail.com";
      };
    };

    home.stateVersion = "24.11";
  };

  system.stateVersion = "24.11";
}
