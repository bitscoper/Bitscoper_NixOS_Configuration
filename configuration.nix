# By Abdullah As-Sadeed

{ config
, pkgs
, ...
}:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/refs/heads/master.tar.gz";

  secrets = import ./secrets.nix;

  existingLibraryPaths = builtins.getEnv "LD_LIBRARY_PATH";
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
      theme = "bgrt";
    };
  };

  time = {
    timeZone = "Asia/Dhaka";
    hardwareClockInLocalTime = true;
  };

  system = {
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

  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };

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

    tmpfiles.rules = [
      "d /var/spool/samba 1777 root root -"
    ];
  };

  services = {
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
      sddm = {
        enable = true;
        wayland.enable = true;
      };

      defaultSession = "plasma";
    };

    desktopManager.plasma6.enable = true;

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

      nssmdns4 = true;

      publish = {
        enable = true;
        userServices = true;
      };

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

    samba = {
      enable = true;
      package = pkgs.sambaFull;

      smbd.enable = true;
      nmbd.enable = true;
      winbindd.enable = true;
      nsswins = true;
      usershares.enable = true;

      settings = {
        global = {
          "server string" = "Bitscoper-WorkStation";
          "netbios name" = "Bitscoper-WorkStation";
          "hosts allow" = "0.0.0.0/0 ::/0";
          "hosts deny" = "";

          "load printers" = "yes";
          "printing" = "cups";
          "printcap name" = "cups";

          security = "user";

          workgroup = "BITSCOPER";
        };

        printers = {
          comment = "All Printers";
          path = "/var/spool/samba";
          public = "yes";
          browseable = "yes";
          "guest ok" = "yes";
          writable = "no";
          printable = "yes";
          "create mode" = 0700;
        };

        public = { };

        private = { };
      };

      openFirewall = true;
    };

    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

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

    tor = {
      enable = false;
      enableGeoIP = true;

      settings = {
        ContactInfo = "bitscoper@Bitscoper-WorkStation";
      };

      openFirewall = true;
    };

    nfs.server.enable = true;

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

    static-web-server = {
      enable = true;
      listen = "[::]:80";
      root = "/home/bitscoper/Public/";
      configuration = {
        general = {
          health = false;
          maintenance-mode = false;

          grace-period = 0;

          cache-control-headers = true;
          redirect-trailing-slash = true;

          directory-listing = true;
          directory-listing-format = "html";

          compression = true;
          compression-level = "default";
          compression-static = true;

          log-level = "warn";
        };
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
  };

  security = {
    rtkit.enable = true;
    wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
  };

  users.users.bitscoper = {
    isNormalUser = true;
    description = "Abdullah As-Sadeed";
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

  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [

      ];
    };

    appimage.enable = true;

    nix-index.enableBashIntegration = true;

    ssh = {
      startAgent = true;
      agentTimeout = null;
    };

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

    gnupg = {
      agent = {
        enable = true;
        enableBrowserSocket = true;
        enableExtraSocket = true;
        enableSSHSupport = false;
        pinentryPackage = pkgs.pinentry-qt;
      };

      dirmngr.enable = true;
    };

    adb.enable = true;

    system-config-printer.enable = true;

    virt-manager.enable = true;

    partition-manager.enable = true;

    kde-pim.enable = true;

    kdeconnect.enable = true;

    firefox = {
      enable = true;
      languagePacks = [
        "en-US"
      ];
    };

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
          };
        }
      ];
    };
  };

  environment = {
    variables = pkgs.lib.mkForce {
      LD_LIBRARY_PATH = "${pkgs.glib.out}/lib/:${pkgs.libGL}/lib/:${pkgs.stdenv.cc.cc.lib}/lib:${existingLibraryPaths}";
    };

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      CHROME_EXECUTABLE = "chromium";
    };

    systemPackages = with pkgs; [
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
      avahi
      bat
      bind
      bleachbit
      bluez
      bluez-tools
      bridge-utils
      btop
      btrfs-progs
      butt
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
      gimp-with-plugins
      git
      git-doc
      glib
      glibc
      gnumake
      gource
      gpredict
      gpsd
      gradle
      gradle-completion
      guestfs-tools
      gzip
      icecast
      iconv
      iftop
      inotify-tools
      jdk
      jellyfin
      jellyfin-ffmpeg
      jellyfin-media-player
      jellyfin-web
      keepassxc
      kicad
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
      networkmanager
      ninja
      nix-diff
      nix-index
      nixos-bgrt-plymouth
      nixos-icons
      nix-bash-completions
      nixpkgs-fmt
      nmap
      obs-studio
      ollama
      onedrive
      onionshare
      opendkim
      openssh
      openssl
      patchelf
      pcre
      php84
      pipewire
      pkg-config
      platformio
      platformio-core
      podman
      podman-compose
      podman-tui
      postfix
      power-profiles-daemon
      python312Full # python313Full
      qpwgraph
      rar
      readline
      ripgrep
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
      swtpm
      telegram-desktop
      texliveFull
      thermald
      tk
      tor
      tor-browser
      torsocks
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
      waydroid
      wayland
      wayland-protocols
      wayland-utils
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
      xoscope
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
    (with androidenv.androidPkgs; [
      # build-tools
      emulator
      platform-tools
      tools
    ]) ++
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
      mailparse
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
      yaml
      zip
      zlib
    ]) ++
    (with php84Packages; [

    ]) ++
    (with python312Packages; [
      # python313Packages
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
    ]) ++
    (with kdePackages; [
      accounts-qt
      akonadi
      akonadi-calendar
      akonadi-calendar-tools
      akonadi-contacts
      akonadi-import-wizard
      akonadi-mime
      akonadi-search
      akonadiconsole
      akregator
      analitza
      ark
      attica
      audiocd-kio
      baloo
      baloo-widgets
      bluedevil
      bluez-qt
      breeze
      breeze-grub
      breeze-gtk
      breeze-icons
      breeze-plymouth
      calendarsupport
      colord-kde
      dolphin
      dolphin-plugins
      drkonqi
      eventviews
      extra-cmake-modules
      ffmpegthumbs
      filelight
      frameworkintegration
      gwenview
      incidenceeditor
      isoimagewriter
      k3b
      kaccounts-integration
      kaccounts-providers
      kaddressbook
      kalarm
      kalgebra
      kalzium
      kamera
      karchive
      kauth
      kbackup
      kbookmarks
      kcalc
      kcalendarcore
      kcalutils
      kcharselect
      kcmutils
      kcodecs
      kcolorchooser
      kcolorpicker
      kcolorscheme
      kcompletion
      kconfig
      kconfigwidgets
      kcontacts
      kcoreaddons
      kcrash
      kcron
      kdav
      kdbusaddons
      kde-gtk-config
      kdebugsettings
      kdecoration
      kded
      kdeedu-data
      kdegraphics-thumbnailers
      kdenetwork-filesharing
      kdenlive
      kdepim-addons
      kdepim-runtime
      kdeplasma-addons
      kdesu
      kdf
      kdiagram
      kdialog
      kdnssd
      kfilemetadata
      kfind
      kget
      kguiaddons
      khealthcertificate
      khelpcenter
      ki18n
      kiconthemes
      kidentitymanagement
      kimageannotator
      kimageformats
      kimagemapeditor
      kimap
      kinfocenter
      kio
      kio-admin
      kio-extras
      kio-fuse
      kio-gdrive
      kio-zeroconf
      kjournald
      kldap
      kleopatra
      kmag
      kmail
      kmail-account-wizard
      kmailtransport
      kmbox
      kmenuedit
      kmime
      kmousetool
      kmouth
      knotifications
      knotifyconfig
      kompare
      konsole
      kontact
      kontactinterface
      kontrast
      konversation
      kopeninghours
      korganizer
      kparts
      kpeople
      kpimtextedit
      kpipewire
      kpkpass
      kplotting
      kpmcore
      kpublictransport
      krdc
      krdp
      krfb
      kruler
      ksanecore
      kscreen
      kscreenlocker
      kservice
      ksmtp
      ksshaskpass
      kstatusnotifieritem
      ksvg
      ksystemlog
      ksystemstats
      ktimer
      ktnef
      ktorrent
      kunitconversion
      kup
      kwallet
      kwallet-pam
      kwalletmanager
      kwayland
      kweather
      kweathercore
      kwidgetsaddons
      kwin
      kwindowsystem
      kxmlgui
      kzones
      layer-shell-qt
      libgravatar
      libkcddb
      libkcompactdisc
      libkdcraw
      libkdepim
      libkexiv2
      libkgapi
      libkleo
      libkomparediff2
      libksane
      libkscreen
      libksieve
      libksysguard
      libktorrent
      libplasma
      libqaccessibilityclient
      mailcommon
      mailimporter
      markdownpart
      mbox-importer
      messagelib
      mimetreeparser
      mlt
      networkmanager-qt
      okular
      phonon
      phonon-vlc
      pim-data-exporter
      pim-sieve-editor
      pimcommon
      plasma-activities
      plasma-activities-stats
      plasma-browser-integration
      plasma-desktop
      plasma-disks
      plasma-firewall
      plasma-integration
      plasma-nm
      plasma-systemmonitor
      plasma-vault
      plasma-wayland-protocols
      plasma-workspace
      plasma-workspace-wallpapers
      plymouth-kcm
      polkit-kde-agent-1
      polkit-qt-1
      poppler
      powerdevil
      print-manager
      prison
      qca
      qtcharts
      qtconnectivity
      qtgraphs
      qtgrpc
      qthttpserver
      qtimageformats
      qtkeychain
      qtlanguageserver
      qtlocation
      qtmqtt
      qtmultimedia
      qtnetworkauth
      qtpositioning
      qtremoteobjects
      qtsensors
      qtserialbus
      qtserialport
      qtshadertools
      qtspeech
      qtspell
      qtsvg
      qttools
      qttranslations
      qtutilities
      qtvirtualkeyboard
      qtwayland
      qtwebchannel
      qtwebengine
      qtwebsockets
      qtwebview
      quazip
      qxlsx
      sddm-kcm
      signon-kwallet-extension
      signond
      skanpage
      solid
      sonnet
      spectacle
      step
      svgpart
      sweeper
      syndication
      syntax-highlighting
      systemsettings
      taglib
      wayland
      wayland-protocols
      waylib
      wayqt
      xwaylandvideobridge
    ]);
    plasma6.excludePackages = (with pkgs.kdePackages; [
      elisa
      kate
    ]) ++ (with pkgs; [

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
