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
    tmp.cleanOnBoot = true;
    plymouth = {
      enable = true;
      theme = "bgrt";
    };
    consoleLogLevel = 5; # KERN_NOTICE
  };

  time = {
    timeZone = "Asia/Dhaka";
    hardwareClockInLocalTime = true;
  };

  system = {
    activationScripts = { };
    userActivationScripts = {
      stdio = {
        text = ''
          rm -f ~/Android/Sdk/platform-tools/adb
          ln -s /run/current-system/sw/bin/adb ~/Android/Sdk/platform-tools/adb
        '';
        deps = [
        ];
      };
    };
  };

  nix = {
    enable = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  nixpkgs.config.allowUnfree = true;

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
      type = "ibus";
      ibus.engines = with pkgs.ibus-engines; [
        openbangla-keyboard
      ];
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

    dbus.enable = true;

    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
      excludePackages = with pkgs; [
        xterm
      ];
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
      gnome-settings-daemon
      rtl-sdr
    ];

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

    power-profiles-daemon.enable = true;

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

    system-config-printer.enable = true;

    # services.samba = {
    #   package = pkgs.sambaFull;
    #   enable = true;
    #   settings = ''
    #     load printers = yes
    #     printing = cups
    #     printcap name = cups
    #   '';
    #   shares = {
    #     printers = {
    #       comment = "All Printers";
    #       path = "/var/spool/samba";
    #       public = "yes";
    #       browseable = "yes";
    #       "guest ok" = "yes";
    #       writable = "no";
    #       printable = "yes";
    #       "create mode" = 0700;
    #     };
    #   };
    #   openFirewall = true;
    # };

    samba-wsdd = {
      enable = true;
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

    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    gnome.gnome-browser-connector.enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
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
    ];
  };

  programs = {
    nix-index.enableBashIntegration = true;

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
      ];
    };

    appimage.enable = true;

    ssh = {
      startAgent = true;
      agentTimeout = null;
    };

    bash = {
      completion.enable = true;
      enableLsColors = true;
      shellAliases = {
        one_drive = "onedrive --sync";
        clean_build = "sudo nix-channel --update && sudo nix-env -u --always && sudo rm -rf /nix/var/nix/gcroots/auto/* && sudo nix-collect-garbage -d && nix-collect-garbage -d && sudo nix-store --gc && sudo nixos-rebuild switch --upgrade-all";
      };
      loginShellInit = ''
        setfacl --modify user:jellyfin:--x ~
        gsettings set org.gnome.shell app-picker-layout "[]"
      '';
      shellInit = ''
    '';
      interactiveShellInit = ''
        PROMPT_COMMAND="history -a"
      '';
    };

    adb.enable = true;

    system-config-printer.enable = true;

    virt-manager.enable = true;

    firefox = {
      enable = true;
      languagePacks = [
        "en-US"
      ];
    };

    thunderbird = {
      enable = true;
      package = pkgs.thunderbird;
    };

    steam = {
      enable = true;
      dedicatedServer.openFirewall = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
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
            "org/gnome/system/location" = {
              enabled = true;
            };
            "org/gnome/shell" = {
              disable-user-extensions = false;
              last-selected-power-profile = "performance";
              remember-mount-password = true;
              enabled-extensions = [
                "Vitals@CoreCoding.com"
                "appindicatorsupport@rgcjonas.gmail.com"
                "blur-my-shell@aunetx"
                "clipboard-indicator@tudmotu.com"
                "desktop-cube@schneegans.github.com"
                "gsconnect@andyholmes.github.io"
                "osd-volume-number@deminder"
                "places-menu@gnome-shell-extensions.gcampax.github.com"
              ];
              favorite-apps = [
                "org.gnome.Console.desktop"
                "org.gnome.Nautilus.desktop"
                "thunderbird.desktop"
                "dbeaver.desktop"
                "arduino-ide.desktop"
                "code.desktop"
                "org.fritzing.Fritzing.desktop"
                "firefox.desktop"
                "sdrangel.desktop"
                "sdrpp.desktop"
                "vlc.desktop"
                "virt-manager.desktop"
              ];
            };
            "org/gnome/shell/app-switcher" = {
              current-workspace-only = false;
            };
            "org/gnome/shell/extensions/appindicator" = {
              legacy-tray-enabled = true;
              tray-pos = "right";
            };
            "org/gnome/shell/extensions/osd-volume-number" = {
              adapt-panel-menu = true;
              icon-position = "left";
              number-position = "right";
            };
            "org/gnome/shell/extensions/vitals" = {
              alphabetize = true;
              fixed-widths = false;
              hide-icons = false;
              hide-zeros = false;
              include-public-ip = true;
              include-static-gpu-info = true;
              include-static-info = true;
              menu-centered = true;
              show-battery = true;
              show-fan = true;
              show-memory = true;
              show-network = true;
              show-processor = true;
              show-storage = true;
              show-system = true;
              show-temperature = true;
              show-voltage = true;
              storage-path = "/";
              use-higher-precision = true;
              hot-sensors = [
                "_processor_usage_"
                "_memory_usage_"
                "__network-rx_max__"
                "__network-tx_max__"
              ];
            };
            "org/gnome/shell/extensions/clipboard-indicator" = {
              cache-only-favorites = true;
              clear-on-boot = true;
              confirm-clear = false;
              disable-down-arrow = true;
              keep-selected-on-clear = false;
              paste-button = true;
              strip-text = false;
            };
            "org/gnome/shell/extensions/gsconnect" = {
              name = "Bitscoper-WorkStation";
            };
            "org/gnome/settings-daemon/plugins/power" = {
              idle-dim = false;
              power-button-action = "interactive";
              power-saver-profile-on-low-battery = false;
              sleep-inactive-ac-type = "nothing";
              sleep-inactive-battery-type = "nothing";
            };
            "org/gnome/desktop/peripherals/keyboard" = {
              repeat = true;
            };
            "org/gnome/desktop/peripherals/touchpad" = {
              click-method = "areas";
              disable-while-typing = true;
              edge-scrolling-enabled = false;
              natural-scroll = true;
              send-events = "enabled";
              tap-to-click = true;
              two-finger-scrolling-enabled = true;
            };
            "org/gnome/desktop/peripherals/mouse" = {
              accel-profile = "default";
              left-handed = false;
              natural-scroll = false;
            };
            "org/gnome/desktop/a11y/keyboard" = {
              bouncekeys-enable = false;
              enable = false;
              slowkeys-enable = false;
              stickykeys-enable = false;
              togglekeys-enable = true;
            };
            "org/gnome/desktop/a11y/mouse" = {
              dwell-click-enabled = false;
              secondary-click-enabled = false;
            };
            "org/gnome/desktop/a11y/interface" = {
              high-contrast = false;
              show-status-shapes = false;
            };
            "org/gnome/desktop/input-sources" = {
              per-window = false;
              show-all-sources = true;
              xkb-options = [
                "terminate:ctrl_alt_bksp"
                "lv3:ralt_switch"
                "compose:rctrl"
              ];
              sources = [
                (pkgs.lib.gvariant.mkTuple [ "xkb" "us" ])
                (pkgs.lib.gvariant.mkTuple [ "ibus" "OpenBangla" ])
                (pkgs.lib.gvariant.mkTuple [ "xkb" "bd" ])
                (pkgs.lib.gvariant.mkTuple [ "xkb" "ara" ])
                (pkgs.lib.gvariant.mkTuple [ "xkb" "ru" ])
              ];
            };
            "org/gnome/desktop/sound" = {
              allow-volume-above-100-percent = true;
              event-sounds = true;
            };
            "org/gnome/desktop/session" = {
              idle-delay = pkgs.lib.gvariant.mkUint32 0;
            };
            "org/gnome/desktop/privacy" = {
              disable-camera = false;
              old-files-age = pkgs.lib.gvariant.mkUint32 1;
              recent-files-max-age = pkgs.lib.gvariant.mkUint32 1;
              remember-recent-files = false;
              remove-old-temp-files = true;
              remove-old-trash-files = true;
            };
            "org/gnome/desktop/remote-desktop/rdp" = {
              enable = true;
              view-only = false;
            };
            "org/gnome/desktop/datetime" = {
              automatic-timezone = false;
            };
            "org/gnome/desktop/interface" = {
              clock-format = "12h";
              clock-show-date = true;
              clock-show-seconds = false;
              clock-show-weekday = true;
              color-scheme = "prefer-dark";
              cursor-blink = true;
              enable-animations = true;
              enable-hot-corners = true;
              gtk-enable-primary-paste = true;
              gtk-theme = "Adwaita-dark";
              icon-theme = "Adwaita";
              locate-pointer = true;
              show-battery-percentage = true;
            };
            "org/gnome/desktop/wm/preferences" = {
              action-double-click-titlebar = "toggle-maximize";
              action-right-click-titlebar = "menu";
              auto-raise = false;
              button-layout = "appmenu:minimize,maximize,close";
              ction-middle-click-titlebar = "lower";
              focus-mode = "sloppy";
              mouse-button-modifier = "<Super>";
              resize-with-right-button = true;
            };
            "org/gnome/mutter" = {
              attach-modal-dialogs = false;
              center-new-windows = false;
              dynamic-workspaces = true;
              edge-tiling = true;
              workspaces-only-on-primary = false;
            };
            "org/gnome/desktop/screensaver" = {
              lock-delay = pkgs.lib.gvariant.mkUint32 0;
              lock-enabled = true;
            };
            "org/gnome/desktop/notifications" = {
              show-in-lock-screen = true;
            };
            "org/gnome/desktop/search-providers" = {
              disable-external = false;
            };
            "org/gnome/desktop/media-handling" = {
              autorun-never = false;
            };
            "org/gnome/desktop/file-sharing" = {
              require-password = "always";
            };
            "org/gtk/settings/file-chooser" = {
              clock-format = "12h";
              show-hidden = true;
              sort-directories-first = true;
            };
            "org/gtk/gtk4/settings/file-chooser" = {
              show-hidden = true;
              sort-directories-first = true;
            };
            "org/gnome/Console" = {
              audible-bell = true;
              custom-font = "NotoMono Nerd Font 10";
              theme = "night";
              use-system-font = false;
              visual-bell = true;
            };
            "org/gnome/nautilus/preferences" = {
              click-policy = "double";
              date-time-format = "simple";
              default-folder-viewer = "icon-view";
              recursive-search = "always";
              show-create-link = true;
              show-delete-permanently = true;
              show-directory-item-counts = "always";
              show-image-thumbnails = "always";
            };
            "org/gnome/nautilus/icon-view" = {
              captions = [
                "size"
                "date_modified"
                "none"
              ];
            };
            "org/gnome/nautilus/list-view" = {
              use-tree-view = true;
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
            "org/gnome/Snapshot" = {
              play-shutter-sound = true;
              show-composition-guidelines = true;
            };
            "org/gnome/evince/default" = {
              continuous = true;
              enable-spellchecking = true;
            };
            "apps/seahorse" = {
              server-auto-publish = true;
              server-auto-retrieve = true;
            };
            "org/gnome/GWeather4" = {
              temperature-unit = "centigrade";
            };
            "com/github/huluti/Curtail" = {
              file-attributes = true;
              metadata = false;
              new-file = true;
              recursive = true;
            };
            "org/gnome/calculator" = {
              show-thousands = true;
              show-zeroes = true;
            };
            "app/drey/Dialect" = {
              color-scheme = "dark";
              show-pronunciation = true;
            };
            "org/gnome/simple-scan" = {
              postproc-enabled = true;
            };
            "org/gnome/maps" = {
              show-scale = true;
            };
            "org/gnome/meld" =
              {
                enable-space-drawer = true;
                highlight-current-line = true;
                highlight-syntax = true;
                prefer-dark-theme = true;
                show-line-numbers = true;
                show-overview-map = true;
                style-scheme = "meld-dark";
                wrap-mode = "word";
              };
            "org/gnome/gnome-system-monitor" = {
              cpu-smooth-graph = true;
              kill-dialog = true;
              process-memory-in-iec = true;
              resources-memory-in-iec = true;
              show-all-fs = true;
              show-whose-processes = "all";
              smooth-refresh = true;
            };
            "org/gnome/gnome-system-monitor/disktreenew" = {
              col-0-visible = true;
              col-1-visible = true;
              col-2-visible = true;
              col-3-visible = true;
              col-4-visible = true;
              col-5-visible = true;
              col-6-visible = true;
            };
            "org/gnome/gnome-system-monitor/proctree" = {
              col-0-visible = true;
              col-1-visible = true;
              col-2-visible = true;
              col-3-visible = true;
              col-4-visible = true;
              col-5-visible = true;
              col-6-visible = true;
              col-7-visible = true;
              col-8-visible = true;
              col-9-visible = true;
              col-10-visible = true;
              col-11-visible = true;
              col-12-visible = true;
              col-13-visible = true;
              col-14-visible = true;
              col-15-visible = true;
              col-16-visible = true;
              col-17-visible = true;
              col-18-visible = true;
              col-19-visible = true;
              col-20-visible = true;
              col-21-visible = true;
              col-22-visible = true;
              col-23-visible = true;
              col-24-visible = true;
              col-25-visible = true;
              col-26-visible = true;
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
      adwaita-icon-theme
      adwaita-qt
      adwaita-qt6
      android-studio
      android-tools
      arduino-cli
      arduino-core
      arduino-ide
      arduino-language-server
      aribb24
      aribb25
      audacity
      avahi
      baobab
      bat
      binary
      bind
      bleachbit
      blender
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
      collision
      cryptsetup
      cups
      cups-filters
      cups-pdf-to-pdf
      cups-printers
      curl
      curtail
      d-spy
      dbeaver-bin
      dbus
      dconf-editor
      dialect
      dive
      dmg2img
      dovecot
      esptool
      evince
      exfatprogs
      extra-cmake-modules
      eyedropper
      faac
      faad2
      fd
      fdk_aac
      ffmpeg-full
      fh
      file
      file-roller
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
      gnome-autoar
      gnome-backgrounds
      gnome-browser-connector
      gnome-calculator
      gnome-characters
      gnome-clocks
      gnome-color-manager
      gnome-console
      gnome-control-center
      gnome-decoder
      gnome-desktop
      gnome-disk-utility
      gnome-epub-thumbnailer
      gnome-extensions-cli
      gnome-firmware
      gnome-font-viewer
      gnome-frog
      gnome-graphs
      gnome-keyring
      gnome-logs
      gnome-maps
      gnome-monitor-config
      gnome-multi-writer
      gnome-nettool
      gnome-network-displays
      gnome-obfuscate
      gnome-online-accounts
      gnome-remote-desktop
      gnome-session
      gnome-shell
      gnome-shell-extensions
      gnome-system-monitor
      gnome-tecla
      gnome-themes-extra
      gnome-tweaks
      gnome-user-docs
      gnome-user-share
      gnome-video-effects
      gnome-weather
      gnumake
      gource
      gpredict
      gpsd
      gtk3
      guestfs-tools
      gvfs
      gzip
      hieroglyphic
      icecast
      iftop
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
      letterpress
      libGL
      libaom
      libappimage
      libde265
      libdvdcss
      libdvdnav
      libdvdread
      libgcc
      libguestfs
      libheif
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
      lorem
      loupe
      lsof
      luksmeta
      lynis
      mattermost-desktop
      meld
      memcached
      meson
      metadata-cleaner
      # mixxx
      mousai
      nano
      neofetch
      networkmanager
      networkmanagerapplet
      ninja
      nix-diff
      nix-index
      nixpkgs-fmt
      nmap
      obs-studio
      ollama
      onedrive
      onionshare
      opendkim
      openssh
      openssl
      paper-clip
      pcre
      php83
      pipewire
      pkg-config
      platformio
      platformio-core
      podman
      podman-compose
      podman-tui
      postfix
      power-profiles-daemon
      python312Full
      qpwgraph
      raider
      rar
      remmina
      ripgrep
      rpPPPoE
      rtl-sdr
      rtl-sdr-librtlsdr
      sane-backends
      schroedinger
      screen
      sdrangel
      sdrpp
      seahorse
      share-preview
      simple-scan
      smartmontools
      spice-gtk
      switcheroo
      swtpm
      sysprof
      telegram-desktop
      texliveFull
      thermald
      tk
      tor
      tor-browser
      torsocks
      transmission_4-gtk
      tree
      tree-sitter
      undollar
      ungoogled-chromium
      unicode-emoji
      unrar
      unzip
      usbtop
      usbutils
      virtio-win
      virtiofsd
      vlc
      vlc-bittorrent
      vscode-js-debug
      warp
      waydroid
      wayland
      wayland-protocols
      wayland-utils
      wget
      wireplumber
      wireshark
      wl-clipboard
      wlroots
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
      yelp
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
          arrterian.nix-env-selector
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
            name = "vscode-serial-monitor";
            publisher = "ms-vscode";
            version = "0.13.241018001";
            sha256 = "K8d2e+7TThXReArKm6rf/AkPqRs5F8faWY47I0ScqIc=";
          }
          {
            name = "vscode-arduino-community";
            publisher = "vscode-arduino";
            version = "0.7.2";
            sha256 = "/HdPJ6LBnyPhz7jeJ0MLRXO2L3bcAzM7J65nKsXsacY=";
          }
          {
            name = "platformio-ide";
            publisher = "platformio";
            version = "3.3.3";
            sha256 = "pcWKBqtpU7DVpiT7UF6Zi+YUKknyjtXFEf5nL9+xuSo=";
          }
        ];
      })
    ] ++
    (with gnome; [
      gvfs
      nixos-gsettings-overrides
    ]) ++
    (with gnomeExtensions; [
      appindicator
      blur-my-shell
      clipboard-indicator
      desktop-cube
      gsconnect
      vitals
    ]) ++
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
    ]) ++
    (with php83Extensions; [
      calendar
      curl
      dom
      exif
      fileinfo
      filter
      ftp
      gd
      imap
      mbstring
      memcached
      mysqli
      opcache
      openssl
      pgsql
      session
      sockets
      sodium
      xml
      xsl
      yaml
      zip
    ]) ++
    (with python312Packages; [
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
    ]);
    gnome.excludePackages = (with pkgs; [
      geary
      gnome-calendar
      gnome-connections
      gnome-contacts
      gnome-music
      gnome-text-editor
      gnome-tour
      epiphany
      totem
    ]) ++ (with pkgs.gnome; [

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

  home-manager.users.bitscoper = {
    programs.git = {
      enable = true;
      userName = "Abdullah As-Sadeed";
      userEmail = "bitscoper@gmail.com";
    };

    home.stateVersion = "24.11";
  };

  system.stateVersion = "24.11";
}

# BUTT: libfdk-aac-2.dll not loaded
# KiCad: Saving Library Tables - Permission Denied
