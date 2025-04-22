# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/refs/heads/master.tar.gz";

  font_name = {
    mono = "NotoMono Nerd Font";
    sans_serif = "NotoSans Nerd Font";
    serif = "NotoSerif Nerd Font";
    emoji = "Noto Color Emoji";
  };

  dracula_theme = {
    hex = {
      background = "#282A36";
      current_line = "#44475A";
      foreground = "#F8F8F2";
      comment = "#6272A4";
      cyan = "#8BE9FD";
      green = "#50FA7B";
      orange = "#FFB86C";
      pink = "#FF79C6";
      purple = "#BD93F9";
      red = "#FF5555";
      yellow = "#F1FA8C";
    };

    rgba = {
      background = "rgba(40, 42, 54, 1.0)";
      current_line = "rgba(68, 71, 90, 1.0)";
      foreground = "rgba(248, 248, 242, 1.0)";
      comment = "rgba(98, 114, 164, 1.0)";
      cyan = "rgba(139, 233, 253, 1.0)";
      green = "rgba(80, 250, 123, 1.0)";
      orange = "rgba(255, 184, 108, 1.0)";
      pink = "rgba(255, 121, 198, 1.0)";
      purple = "rgba(189, 147, 249, 1.0)";
      red = "rgba(255, 85, 85, 1.0)";
      yellow = "rgba(241, 250, 140, 1.0)";
    };
  };

  cursor = {
    theme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };

    size = 24;
  };

  wallpaper = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/JaKooLit/Wallpaper-Bank/refs/heads/main/wallpapers/Dark_Nature.png";
  };

  secrets = import ./secrets.nix;
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

      kernelModules = config.boot.kernelModules;

      systemd = {
        enable = true;
        package = config.systemd.package;
      };

      network.ssh.enable = true;

      verbose = true;
    };

    kernelPackages = pkgs.linuxPackages_zen;

    extraModulePackages = with config.boot.kernelPackages; [
      akvcam
    ];

    kernelModules = [
      "at24"
      "ee1004"
      "kvm-intel"
      "spd5118"
    ];

    extraModprobeConfig = "options kvm_intel nested=1";

    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "kvm.ignore_msrs=1"
      "boot.shell_on_fail"
      "rd.systemd.show_status=true"
      "rd.udev.log_level=err"
      "udev.log_level=err"
      "udev.log_priority=err"
    ];

    consoleLogLevel = 4; # 4 = KERN_WARNING

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
    copySystemConfiguration = true;

    switch.enable = true;
    tools = {
      nixos-build-vms.enable = true;
      nixos-enter.enable = true;
      nixos-generate-config.enable = true;
      nixos-install.enable = true;
      nixos-option.enable = true;
      nixos-rebuild.enable = true;
      nixos-version.enable = true;
    };

    autoUpgrade = {
      enable = false;
      channel = "https://nixos.org/channels/nixos-unstable";
      operation = "boot";
      allowReboot = false;
    };

    activationScripts = { };

    userActivationScripts = { };

    stateVersion = "24.11";
  };

  nix = {
    enable = true;
    channel.enable = true;

    settings = {
      experimental-features = [
        "nix-command"
      ];

      require-sigs = true;
      sandbox = true;
      auto-optimise-store = true;

      cores = 0; # 0 = All
      # max-jobs = 1;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
    };
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";

    config = {
      allowUnfree = true;
    };

    overlays = [
      (final: prev: {
        qt6Packages = prev.qt6Packages.overrideScope (
          _: kprev: {
            qt6gtk2 = kprev.qt6gtk2.overrideAttrs (_: {
              version = "0.5-unstable-2025-03-04";
              src = final.fetchFromGitLab {
                domain = "opencode.net";
                owner = "trialuser";
                repo = "qt6gtk2";
                rev = "d7c14bec2c7a3d2a37cde60ec059fc0ed4efee67";
                hash = "sha256-6xD0lBiGWC3PXFyM2JW16/sDwicw4kWSCnjnNwUT4PI=";
              };
            });
          }
        );
      })
    ];
  };

  appstream.enable = true;

  i18n = {
    supportedLocales = [
      "all"
    ];

    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = config.i18n.defaultLocale;
      LC_IDENTIFICATION = config.i18n.defaultLocale;
      LC_MEASUREMENT = config.i18n.defaultLocale;
      LC_MONETARY = config.i18n.defaultLocale;
      LC_NAME = config.i18n.defaultLocale;
      LC_NUMERIC = config.i18n.defaultLocale;
      LC_PAPER = config.i18n.defaultLocale;
      LC_TELEPHONE = config.i18n.defaultLocale;
      LC_TIME = config.i18n.defaultLocale;
    };

    inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        waylandFrontend = true;

        addons = with pkgs; [
          fcitx5-openbangla-keyboard
        ];
      };
    };
  };

  networking = {
    hostName = "Bitscoper-WorkStation";

    wireless = {
      dbusControlled = true;
      userControlled.enable = true;
    };

    networkmanager = {
      enable = true;
      package = pkgs.networkmanager;

      ethernet.macAddress = "permanent";

      wifi = {
        backend = "wpa_supplicant";

        powersave = false;

        scanRandMacAddress = true;
        macAddress = "permanent";
      };

      logLevel = "WARN";
    };

    firewall = {
      enable = false;

      allowPing = true;

      allowedTCPPorts = [
        5060
      ];
      allowedUDPPorts = [
        5060
      ];
    };

    nameservers = [
      "1.1.1.3#one.one.one.one"
      "1.0.0.3#one.one.one.one"
    ];
  };

  security = {
    allowSimultaneousMultithreading = true;

    tpm2.enable = true;

    lockKernelModules = false;

    pam = {
      mount = {
        enable = true;

        createMountPoints = true;
        removeCreatedMountPoints = true;

        logoutHup = true;
        logoutTerm = false;
        logoutKill = false;

        logoutWait = 0;
      };

      services = {
        login = {
          unixAuth = true;
          nodelay = false;

          fprintAuth = true;

          logFailures = true;

          enableGnomeKeyring = true;

          gnupg = {
            enable = true;
            storeOnly = false;
            noAutostart = false;
          };
        };

        sddm = {
          unixAuth = true;
          nodelay = false;

          fprintAuth = true;

          logFailures = true;

          enableGnomeKeyring = true;

          gnupg = {
            enable = true;
            storeOnly = false;
            noAutostart = false;
          };
        };

        hyprlock = {
          unixAuth = true;
          nodelay = false;

          fprintAuth = true;

          logFailures = true;

          enableGnomeKeyring = true;

          gnupg = {
            enable = true;
            storeOnly = false;
            noAutostart = false;
          };
        };

        sudo = {
          unixAuth = true;
          nodelay = false;

          fprintAuth = true;

          logFailures = true;
        };

        polkit-1 = {
          unixAuth = true;
          nodelay = false;

          fprintAuth = true;

          logFailures = true;
        };
      };
    };

    sudo = {
      enable = true;
      package = pkgs.sudo;

      execWheelOnly = true;
      wheelNeedsPassword = true;
    };

    polkit = {
      enable = true;
      package = pkgs.polkit;
    };

    rtkit.enable = true;

    wrappers = {
      spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
    };

    audit = {
      enable = false;
    };
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    cpu = {
      intel = {
        updateMicrocode = true;
      };
    };

    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
      ];
    };

    sensor = {
      hddtemp = {
        enable = true;
        unit = "C";
        drives = [
          "/dev/disk/by-path/*"
        ];
      };
    };

    bluetooth = {
      enable = true;
      package = pkgs.bluez;

      hsphfpd.enable = false; # Conflicts wwth WirePlumber

      powerOnBoot = true;

      input.General = {
        IdleTimeout = 0; # 0 = Disabled
        LEAutoSecurity = true;
        ClassicBondedOnly = true;
        UserspaceHID = true;
      };

      network.General = {
        DisableSecurity = false;
      };

      settings = {
        General = {
          MaxControllers = 0; # 0 = Unlimited
          ControllerMode = "dual";

          Name = config.networking.hostName;

          DiscoverableTimeout = 0; # 0 = Disabled
          PairableTimeout = 0; # 0 = Disabled
          AlwaysPairable = true;
          FastConnectable = true;

          ReverseServiceDiscovery = true;
          NameResolving = true;
          RemoteNameRequestRetryDelay = 60; # Seconds
          RefreshDiscovery = true;
          TemporaryTimeout = 0; # 0 = Disabled

          SecureConnections = "on";
          Privacy = "off";

          Experimental = true;
          KernelExperimental = true;
        };

        Policy = {
          AutoEnable = true;

          ResumeDelay = 2; # Seconds
          ReconnectAttempts = 7;
          ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
        };

        GATT = {
          Cache = "always";
        };

        CSIS = {
          Encryption = true;
        };

        AVRCP = {
          VolumeCategory = true;
          VolumeWithoutTarget = false;
        };

        AVDTP = {
          SessionMode = "ertm";
        };

        AdvMon = {
          RSSISamplingPeriod = "0x00";
        };
      };
    };

    rtl-sdr = {
      enable = true;
      package = pkgs.rtl-sdr;
    };

    sane = {
      enable = true;
      openFirewall = true;
    };

    steam-hardware.enable = true;
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      package = pkgs.libvirt;

      qemu = {
        package = pkgs.qemu_kvm;

        swtpm = {
          enable = true;
          package = pkgs.swtpm;
        };

        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMFFull.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };

        runAsRoot = true;
      };
    };
    spiceUSBRedirection.enable = true;

    containers.enable = true;

    podman = {
      enable = true;
      package = pkgs.podman;
      dockerCompat = true;

      defaultNetwork.settings.dns_enabled = true;
    };

    oci-containers.backend = "podman";

    waydroid.enable = true;
  };

  systemd = {
    package = pkgs.systemd;

    packages = with pkgs; [
      cloudflare-warp
      hardinfo2
    ];

    globalEnvironment = { };

    targets = {
      multi-user.wants = [
        "warp-svc.service"
      ];
    };
  };

  services = {
    dbus = {
      enable = true;
      dbusPackage = pkgs.dbus;

      implementation = "broker";
    };

    btrfs.autoScrub = {
      enable = true;

      interval = "weekly";
      fileSystems = [
        "/"
      ];
    };

    fwupd = {
      enable = true;
      package = pkgs.fwupd;
    };

    acpid = {
      enable = true;

      powerEventCommands = '''';
      acEventCommands = '''';
      lidEventCommands = '''';

      logEvents = false;
    };

    power-profiles-daemon = {
      enable = true;
      package = pkgs.power-profiles-daemon;
    };

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

    fprintd = {
      enable = true;
      package = if config.services.fprintd.tod.enable then pkgs.fprintd-tod else pkgs.fprintd;
      # tod = {
      #   enable = true;
      #   driver = ;
      # };
    };

    displayManager = {
      enable = true;
      preStart = '''';

      sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm; # Qt 6

        extraPackages = with pkgs; [
          kdePackages.qtmultimedia
        ];

        wayland = {
          enable = true;
          compositor = "weston";
        };

        enableHidpi = true;
        theme = "sddm-astronaut-theme";

        autoNumlock = true;

        autoLogin.relogin = false;

        settings = {
          Theme = {
            CursorTheme = cursor.theme.name;
            CursorSize = cursor.size;

            Font = font_name.sans_serif;
          };
        };

        stopScript = '''';
      };

      defaultSession = "hyprland-uwsm";

      autoLogin = {
        enable = false;
        user = null;
      };

      logToJournal = true;
      logToFile = true;
    };

    gnome.gnome-keyring.enable = true;

    udev = {
      enable = true;
      packages = with pkgs; [
        android-udev-rules
        game-devices-udev-rules
        libmtp.out
        rtl-sdr
        steam-devices-udev-rules
        usb-blaster-udev-rules
      ];
    };

    gvfs = {
      enable = true;
      package = pkgs.gvfs;
    };

    udisks2 = {
      enable = true;
      package = pkgs.udisks2;

      mountOnMedia = false;
    };

    libinput = {
      enable = true;

      mouse = {
        leftHanded = false;
        disableWhileTyping = false;
        tapping = true;
        middleEmulation = true;
        clickMethod = "buttonareas";
        scrollMethod = "twofinger";
        naturalScrolling = true;
        horizontalScrolling = true;
        tappingDragLock = true;
        sendEventsMode = "enabled";
      };

      touchpad = {
        leftHanded = false;
        disableWhileTyping = false;
        tapping = true;
        middleEmulation = true;
        clickMethod = "buttonareas";
        scrollMethod = "twofinger";
        naturalScrolling = true;
        horizontalScrolling = true;
        tappingDragLock = true;
        sendEventsMode = "enabled";
      };
    };

    pipewire = {
      enable = true;
      package = pkgs.pipewire;
      systemWide = false;

      audio.enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      socketActivation = true;

      wireplumber = {
        enable = true;
        package = pkgs.wireplumber;

        extraConfig.bluetoothEnhancements = {
          "monitor.bluez.properties" = {
            "bluez5.enable-hw-volume" = true;

            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;

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

      raopOpenFirewall = true;
    };

    pulseaudio.enable = false;

    blueman.enable = true;

    printing = {
      enable = true;
      package = pkgs.cups;

      drivers = with pkgs; [
        gutenprint
        gutenprintBin
      ];

      cups-pdf.enable = true;

      listenAddresses = [
        "*:631"
      ];

      allowFrom = [
        "all"
      ];

      browsing = true;
      webInterface = true;

      defaultShared = true;
      startWhenNeeded = true;

      extraConf = ''
        DefaultLanguage en
        ServerName ${config.networking.hostName}
        ServerAlias *
        ServerTokens Full
        ServerAdmin bitscoper@${config.networking.hostName}
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

    avahi = {
      enable = true;
      package = pkgs.avahi;

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

      domainName = config.networking.hostName;
      hostName = config.networking.hostName;

      openFirewall = true;
    };

    bind = {
      enable = false;
      package = pkgs.bind;

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

    openssh = {
      enable = true;
      package = pkgs.openssh;

      listenAddresses = [
        {
          addr = "0.0.0.0";
        }
      ];
      ports = [
        22
      ];
      allowSFTP = true;

      banner = config.networking.hostName;

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

    cockpit = {
      enable = true;
      package = pkgs.cockpit;

      port = 9090;
      openFirewall = true;
    };

    phpfpm = {
      settings = { };

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
      enable = true;
      package = pkgs.postgresql;

      enableTCPIP = true;

      settings = pkgs.lib.mkForce {
        listen_addresses = "*";
        port = 5432;
        jit = true;
      };

      authentication = pkgs.lib.mkOverride 10 ''
        local all all md5
        host all all 0.0.0.0/0 md5
        host all all ::/0 md5
        local replication all md5
        host replication all 0.0.0.0/0 md5
        host replication all ::/0 md5
      '';

      checkConfig = true;

      initialScript = pkgs.writeText "initScript" ''
        ALTER USER postgres WITH PASSWORD '${secrets.password_1_of_bitscoper}';
      '';
    };

    mysql = {
      enable = true;
      package = pkgs.mariadb;

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

    postfix = {
      enable = true;

      enableSmtp = true;
      enableSubmission = true;
      enableSubmissions = true;

      domain = config.networking.hostName;
      hostname = config.networking.hostName;
      origin = config.networking.hostName;

      virtualMapType = "pcre";
      aliasMapType = "pcre";
      enableHeaderChecks = true;

      setSendmail = true;

      config = { };
    };

    opendkim = {
      enable = true;

      domains = "csl:${config.networking.hostName}";
      selector = "default";

      settings = { };
    };

    dovecot2 = {
      enable = true;

      enableImap = true;
      enablePop3 = true;
      enableLmtp = true;
      protocols = [
        "imap"
        "pop3"
        "lmtp"
      ];

      enableQuota = true;
      quotaPort = "12340";

      enableDHE = true;

      createMailUser = true;

      enablePAM = true;
      showPAMFailure = true;

      pluginSettings = { };

      extraConfig = '''';
    };

    icecast = {
      enable = true;

      hostname = config.networking.hostName;
      listen = {
        address = "0.0.0.0";
        port = 17101;
      };

      admin = {
        user = "bitscoper";
        password = secrets.password_1_of_bitscoper;
      };

      extraConf = ''
        <location>${config.networking.hostName}</location>
        <admin>bitscoper@${config.networking.hostName}</admin>
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
        <server-id>${config.networking.hostName}</server-id>
      ''; # <loglevel>2</loglevel> = Warn
    };

    jellyfin = {
      enable = true;
      package = pkgs.jellyfin;

      openFirewall = true;
    };

    ollama = {
      enable = true;
      package = pkgs.ollama;

      host = "0.0.0.0";
      port = 11434;
      openFirewall = true;
    };

    open-webui = {
      enable = true;
      package = pkgs.open-webui;

      host = "0.0.0.0";
      port = 11111;

      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";

        DEFAULT_LOCALE = "en";

        ENABLE_ADMIN_CHAT_ACCESS = "True";
        ENABLE_ADMIN_EXPORT = "True";
        SHOW_ADMIN_DETAILS = "True";
        ADMIN_EMAIL = "bitscoper@${config.networking.hostName}";

        USER_PERMISSIONS_WORKSPACE_MODELS_ACCESS = "True";
        USER_PERMISSIONS_WORKSPACE_KNOWLEDGE_ACCESS = "True";
        USER_PERMISSIONS_WORKSPACE_PROMPTS_ACCESS = "True";
        USER_PERMISSIONS_WORKSPACE_TOOLS_ACCESS = "True";

        USER_PERMISSIONS_CHAT_TEMPORARY = "True";
        USER_PERMISSIONS_CHAT_FILE_UPLOAD = "True";
        USER_PERMISSIONS_CHAT_EDIT = "True";
        USER_PERMISSIONS_CHAT_DELETE = "True";

        ENABLE_CHANNELS = "True";

        ENABLE_REALTIME_CHAT_SAVE = "True";

        ENABLE_AUTOCOMPLETE_GENERATION = "True";
        AUTOCOMPLETE_GENERATION_INPUT_MAX_LENGTH = "-1";

        ENABLE_RAG_WEB_SEARCH = "True";
        ENABLE_SEARCH_QUERY_GENERATION = "True";

        ENABLE_TAGS_GENERATION = "True";

        ENABLE_IMAGE_GENERATION = "True";

        YOUTUBE_LOADER_LANGUAGE = "en";

        ENABLE_MESSAGE_RATING = "True";

        ENABLE_COMMUNITY_SHARING = "True";

        ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION = "True";
        WEBUI_SESSION_COOKIE_SAME_SITE = "strict";
        WEBUI_SESSION_COOKIE_SECURE = "True";
        WEBUI_AUTH = "False";

        ENABLE_OLLAMA_API = "True";
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      };

      openFirewall = true;
    };

    wordpress = {
      sites = { };
    };

    asterisk = {
      enable = true;
      package = pkgs.asterisk;

      confFiles = {
        "pjsip.conf" = ''
          [transport-tcp]
          type = transport
          protocol = tcp
          bind = 0.0.0.0

          [transport-udp]
          type = transport
          protocol = udp
          bind = 0.0.0.0

          [transport-tcp6]
          type = transport
          protocol = tcp
          bind = ::

          [transport-udp6]
          type = transport
          protocol = udp
          bind = ::

          [endpoint_internal](!)
          type = endpoint
          context = from-internal
          disallow = all
          allow = ulaw

          [auth_userpass](!)
          type = auth
          auth_type = userpass

          [aor_dynamic](!)
          type = aor
          max_contacts = 1

          ; Account 1
          [bitscoper_1](endpoint_internal)
          auth = bitscoper_1
          aors = bitscoper_1
          [bitscoper_1](auth_userpass)
          password = ${secrets.password_2_of_bitscoper}
          username = bitscoper_1
          [bitscoper_1](aor_dynamic)

          ; Account 2
          [bitscoper_2](endpoint_internal)
          auth = bitscoper_2
          aors = bitscoper_2
          [bitscoper_2](auth_userpass)
          password = ${secrets.password_2_of_bitscoper}
          username = bitscoper_2
          [bitscoper_2](aor_dynamic)

          ; Account 3
          [bitscoper_3](endpoint_internal)
          auth = bitscoper_3
          aors = bitscoper_3
          [bitscoper_3](auth_userpass)
          password = ${secrets.password_2_of_bitscoper}
          username = bitscoper_3
          [bitscoper_3](aor_dynamic)

          ; Account 4
          [bitscoper_4](endpoint_internal)
          auth = bitscoper_4
          aors = bitscoper_4
          [bitscoper_4](auth_userpass)
          password = ${secrets.password_2_of_bitscoper}
          username = bitscoper_4
          [bitscoper_4](aor_dynamic)
        '';

        "extensions.conf" = ''
          [from-internal]
            exten => 1, 1, Dial(PJSIP/bitscoper_1, 60)
            exten => 2, 1, Dial(PJSIP/bitscoper_2, 60)
            exten => 3, 1, Dial(PJSIP/bitscoper_3, 60)
            exten => 4, 1, Dial(PJSIP/bitscoper_4, 60)

            exten => 17, 1, Answer()
            same  =>     n, Wait(1)
            same  =>     n, Playback(hello-world)
            same  =>     n, Hangup()
        '';
      };

      extraConfig = '''';

      extraArguments = [

      ];
    };

    tailscale = {
      enable = true;
      package = pkgs.tailscale;

      disableTaildrop = false;

      port = 0; # 0 = Automatic
      openFirewall = true;
    };

    tor = {
      enable = false;
      package = pkgs.tor;

      relay = {
        enable = false;

        # role = ;
      };

      client = {
        enable = false;

        dns.enable = true;

        onionServices = { };
      };

      torsocks = {
        enable = config.services.tor.client.enable;
        allowInbound = true;
      };

      controlSocket.enable = false;

      enableGeoIP = true;

      settings = {
        Nickname = config.networking.hostName;
        ContactInfo = "bitscoper@${config.networking.hostName}";

        IPv6Exit = true;
        ClientUseIPv4 = true;
        ClientUseIPv6 = true;

        ExtendAllowPrivateAddresses = false;
        RefuseUnknownExits = true;
        ServerDNSDetectHijacking = true;
        ServerDNSRandomizeCase = true;

        FetchServerDescriptors = true;
        FetchHidServDescriptors = true;
        FetchUselessDescriptors = false;
        DownloadExtraInfo = false;

        CellStatistics = false;
        ConnDirectionStatistics = false;
        DirReqStatistics = false;
        EntryStatistics = false;
        ExitPortStatistics = false;
        ExtraInfoStatistics = false;
        HiddenServiceStatistics = false;
        MainloopStats = false;
        PaddingStatistics = false;

        LogMessageDomains = false;
      };

      openFirewall = true;
    };

    logrotate = {
      enable = true;

      checkConfig = true;
      allowNetworking = true;
    };
  };

  programs = {
    command-not-found.enable = true;

    nix-ld = {
      enable = true;
      package = pkgs.nix-ld;

      libraries = with pkgs; [
        # libepoxy
        glib.out
        libGL
        llvmPackages.stdenv.cc.cc.lib
        stdenv.cc.cc.lib
      ];
    };

    appimage = {
      enable = true;
      package = pkgs.appimage-run;

      binfmt = true;
    };

    uwsm = {
      enable = true;
      package = pkgs.uwsm;
    };

    hyprland = {
      enable = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;

      withUWSM = true;
      xwayland.enable = true;
    };

    xwayland.enable = true;

    bash = {
      completion = {
        enable = true;
        package = pkgs.bash-completion;
      };

      enableLsColors = true;

      shellAliases = { };

      loginShellInit = '''';

      shellInit = '''';

      interactiveShellInit = ''
        PROMPT_COMMAND="history -a"
      '';
    };

    fish = {
      enable = true;
      package = pkgs.fish;

      vendor = {
        config.enable = true;
        functions.enable = true;
        completions.enable = true;
      };

      shellAbbrs = { };
      shellAliases = { };

      promptInit = '''';

      loginShellInit = '''';

      shellInit = '''';

      interactiveShellInit = ''
        if command -q nix-your-shell
         nix-your-shell fish | source
        end
      '';
    };

    direnv = {
      enable = true;
      package = pkgs.direnv;

      nix-direnv.enable = true;
      loadInNixShell = true;

      enableBashIntegration = true;
      enableFishIntegration = true;

      direnvrcExtra = '''';

      silent = false;
    };

    nautilus-open-any-terminal = {
      enable = true;
      terminal = "blackbox";
    };

    nix-index = {
      package = pkgs.nix-index;

      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    java = {
      enable = true;
      package = pkgs.jdk23;

      binfmt = true;
    };

    ssh = {
      package = pkgs.openssh;

      startAgent = true;
      agentTimeout = null;
    };

    gnupg = {
      package = pkgs.gnupg;

      agent = {
        enable = true;

        enableBrowserSocket = true;
        enableExtraSocket = true;
        enableSSHSupport = false;

        pinentryPackage = (
          pkgs.pinentry-rofi.override {
            rofi = pkgs.rofi-wayland;
          }
        );
      };

      dirmngr.enable = true;
    };

    nm-applet = {
      enable = true;
      indicator = true;
    };

    seahorse.enable = true;

    git = {
      enable = true;
      package = pkgs.gitFull;

      lfs = {
        enable = true;
        package = pkgs.git-lfs;

        enablePureSSHTransfer = true;
      };

      prompt.enable = true;

      config = {
        init.defaultBranch = "main";

        credential.helper = "${pkgs.gitFull}/bin/git-credential-libsecret";

        user = {
          name = "Abdullah As-Sadeed";
          email = "bitscoper@gmail.com";
        };
      };
    };

    adb.enable = true;

    usbtop.enable = true;

    system-config-printer.enable = true;

    virt-manager = {
      enable = true;
      package = pkgs.virt-manager;
    };

    bat = {
      enable = true;
      package = pkgs.bat;
      extraPackages = with pkgs.bat-extras; [
        batdiff
        batgrep
        batman
        batpipe
        batwatch
        prettybat
      ];

      settings = { };
    };

    nano = {
      enable = true;
      nanorc = ''
        set linenumbers
        set softwrap
        set indicator
        set autoindent
      '';
    };

    thunderbird = {
      enable = true;
      package = pkgs.thunderbird-latest;

      preferences = { };
    };

    wireshark = {
      enable = true;
      package = pkgs.wireshark;

      dumpcap.enable = true;
      usbmon.enable = true;
    };

    steam = {
      enable = true;
      package = pkgs.steam;

      # extraCompatPackages = with pkgs; [

      # ];

      localNetworkGameTransfers.openFirewall = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    localsend = {
      enable = true;
      package = pkgs.localsend;

      openFirewall = true;
    };

    dconf = {
      enable = true;
      profiles.user.databases = [
        {
          lockAll = true;

          settings = {
            "system/locale" = {
              region = config.i18n.defaultLocale;
            };

            "com/raggesilver/BlackBox" = {
              context-aware-header-bar = true;
              easy-copy-paste = false;
              fill-tabs = true;
              font = "${font_name.mono} 12";
              headerbar-drag-area = true;
              notify-process-completion = true;
              pretty = true;
              remember-window-size = false;
              show-headerbar = true;
              show-menu-button = true;
              show-scrollbars = true;
              terminal-bell = true;
              theme-bold-is-bright = false;
              theme-dark = "Dracula";
              theme-light = "Dracula Light";
              use-overlay-scrolling = true;
            };

            "org/gnome/desktop/privacy" = {
              remember-app-usage = false;
              remember-recent-files = false;
              remove-old-temp-files = true;
              remove-old-trash-files = true;
              report-technical-problems = false;
              send-software-usage-stats = false;
              usb-protection = true;
            };
            "org/gtk/gtk4/settings/file-chooser" = {
              sort-directories-first = true;
            };
            "org/gnome/nautilus/preferences" = {
              click-policy = "double";
              recursive-search = "always";
              show-create-link = true;
              show-delete-permanently = true;
              show-directory-item-counts = "always";
              show-image-thumbnails = "always";
              date-time-format = "simple";
            };
            "org/gnome/nautilus/icon-view" = {
              captions = [
                "size"
                "date_modified"
                "none"
              ];
            };

            "io/missioncenter/MissionCenter" = {
              apps-page-core-count-affects-percentages = true;
              apps-page-merged-process-stats = false;
              apps-page-remember-sorting = false;
              performance-page-network-dynamic-scaling = true;
              performance-smooth-graphs = false;
              window-interface-style = "dark";
            };

            "org/virt-manager/virt-manager" = {
              xmleditor-enabled = true;
            };
            "org/virt-manager/virt-manager/connections" = {
              autoconnect = [
                "qemu:///system"
              ];
              uris = [
                "qemu:///system"
              ];
            };
            "org/virt-manager/virt-manager/new-vm" = {
              cpu-default = "host-passthrough";
            };
            "org/virt-manager/virt-manager/console" = {
              auto-redirect = false;
              autoconnect = true;
            };
            "org/virt-manager/virt-manager/stats" = {
              enable-cpu-poll = true;
              enable-disk-poll = true;
              enable-memory-poll = true;
              enable-net-poll = true;
            };
            "org/virt-manager/virt-manager/vmlist-fields" = {
              cpu-usage = true;
              disk-usage = true;
              host-cpu-usage = true;
              memory-usage = true;
              network-traffic = true;
            };
            "org/virt-manager/virt-manager/confirm" = {
              delete-storage = true;
              forcepoweroff = true;
              pause = true;
              poweroff = true;
              removedev = true;
              unapplied-dev = true;
            };

            "org/gnome/file-roller/ui" = {
              view-sidebar = true;
            };
            "org/gnome/file-roller/listing" = {
              list-mode = "as-folder";
            };

            "org/gnome/eog/plugins" = {
              active-plugins = [
                "fullscreen"
                "reload"
                "statusbar-date"
              ];
            };
            "org/gnome/eog/ui" = {
              image-gallery = false;
              sidebar = true;
              statusbar = true;
            };
            "org/gnome/eog/view" = {
              autorotate = true;
              extrapolate = true;
              interpolate = true;
              transparency = "checked";
              use-background-color = false;
            };
            "org/gnome/eog/fullscreen" = {
              loop = false;
              upscale = false;
            };

            "com/github/huluti/Curtail" = {
              file-attributes = true;
              metadata = false;
              new-file = true;
              recursive = true;
            };

            "org/gnome/meld" = {
              enable-space-drawer = true;
              highlight-current-line = true;
              highlight-syntax = true;
              prefer-dark-theme = true;
              show-line-numbers = true;
              show-overview-map = true;
              wrap-mode = "word";
            };
          };
        }
      ];
    };
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

    fontconfig = {
      enable = true;

      allowBitmaps = true;
      allowType1 = false;
      cache32Bit = true;

      defaultFonts = {
        monospace = [
          font_name.mono
        ];

        sansSerif = [
          font_name.sans_serif
        ];

        serif = [
          font_name.serif
        ];

        emoji = [
          font_name.emoji
        ];
      };

      includeUserConf = true;
    };
  };

  environment = {
    enableDebugInfo = false;

    enableAllTerminfo = true;

    wordlist = {
      enable = true;
      # lists = ;
    };

    homeBinInPath = true;
    localBinInPath = true;

    stub-ld.enable = true;

    variables = { };

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      CHROME_EXECUTABLE = "chromium";
    };

    shellAliases = {
      clean_build = "sudo nix-channel --update && sudo nix-env -u --always && sudo rm -rf /nix/var/nix/gcroots/auto/* && sudo nix-collect-garbage -d && nix-collect-garbage -d && sudo nix-store --gc && sudo nixos-rebuild switch --install-bootloader --upgrade-all";
    };

    extraInit = '''';

    loginShellInit = '''';

    shellInit = '''';

    interactiveShellInit = '''';

    systemPackages =
      with pkgs;
      [
        # amrnb
        # amrwb
        # appimagekitk
        # fritzing
        # gnss-sdr
        # reiser4progs
        # scrounge-ntfs
        # sdrangel
        above
        acl
        aircrack-ng
        alac
        amass
        android-studio
        android-studio-tools
        android-tools
        anydesk
        apkeep
        apkleaks
        apksigner
        arduino-cli
        arduino-ide
        arduinoOTA
        aribb24
        aribb25
        arj
        audacity
        autopsy
        avrdude
        baobab
        bfcal
        binwalk
        blackbox-terminal
        bleachbit
        blender
        bluez-tools
        brightnessctl
        btrfs-progs
        bulk_extractor
        burpsuite
        bustle
        butt
        bzip2
        bzip3
        cabextract
        celestia
        celt
        certbot-full
        chmlib
        clang
        clang-analyzer
        clang-manpages
        clang-tools
        clinfo
        cliphist
        cloc
        cloudflare-warp
        cmake
        codec2
        collision
        coreutils-full
        cpio
        cryptsetup
        cups-filters
        cups-pdf-to-pdf
        cups-printers
        curlFull
        curtail
        d-spy
        darktable
        dart
        dbeaver-bin
        dconf-editor
        debase
        dirb
        dmg2img
        dmidecode
        dnsrecon
        dosfstools
        e2fsprogs
        efibootmgr
        eog
        esptool
        evtest
        evtest-qt
        exfatprogs
        f2fs-tools
        faac
        faad2
        fdk_aac
        ffmpeg-full
        ffmpegthumbnailer
        file
        file-roller
        flightgear
        flutter
        fwupd-efi
        gcc
        gdb
        gdk-pixbuf
        ghidra
        gimp-with-plugins
        git-doc
        git-filter-repo
        glib
        glibc
        gnome-font-viewer
        gnugrep
        gnulib
        gnumake
        gnused
        gnutar
        gnutls
        gource
        gparted
        gpredict
        grim
        gsm
        gtk-vnc
        guestfs-tools
        gzip
        hardinfo2
        hashcat
        hdparm
        hfsprogs
        hieroglyphic
        hw-probe
        hwloc
        hydra-check
        hyprpicker
        hyprpolkitagent
        i2c-tools
        iaito
        iftop
        inkscape
        inotify-tools
        jfsutils
        jmol
        john
        johnny
        jxrlib
        keepassxc
        kernelshark
        lha
        lhasa
        libGL
        libGLU
        libaom
        libappimage
        libass
        libcamera
        libde265
        libdvdcss
        libdvdnav
        libdvdread
        libepoxy
        libfreeaptx
        libfreefare
        libftdi1
        libgcc
        libgpg-error
        libguestfs
        libheif
        libilbc
        liblc3
        libnotify
        libogg
        libopenraw
        libopus
        libosinfo
        libqalculate
        libusb1
        libuuid
        libva-utils
        libvpx
        libwebcam
        libwebp
        libxfs
        libzip
        linuxConsoleTools
        lrzip
        lshw
        lsof
        lsscsi
        lvm2
        lynis
        lz4
        lzham
        lzip
        lzlib
        lzop
        macchanger
        masscan
        massdns
        media-player-info
        meld
        mesa-demos
        mfcuk
        mfoc
        mission-center
        monkeysAudio
        mtools
        nautilus
        netdiscover
        netsniff-ng
        networkmanagerapplet
        nikto
        nilfs-utils
        ninja
        nix-bash-completions
        nix-diff
        nix-index
        nix-info
        nixd
        nixdoc
        nixfmt-rfc-style
        nixos-icons
        nixpkgs-lint
        nixpkgs-review
        nmap
        ntfs3g
        nuclei
        onionshare-gui
        onlyoffice-desktopeditors
        opencore-amr
        openh264
        openjpeg
        openssl
        p7zip
        papirus-folders
        parabolic
        patchelf
        pciutils
        pcre
        php84
        pjsip
        pkg-config
        platformio
        platformio-core
        playerctl
        podman-compose
        podman-desktop
        pwvucontrol
        python313Full
        qalculate-gtk
        qbittorrent
        qemu-utils
        qpwgraph
        radare2
        rar
        readline
        reiserfsprogs
        remmina
        rpPPPoE
        rpmextract
        rtl-sdr-librtlsdr
        rzip
        sane-backends
        sbc
        scalpel
        schroedinger
        scrcpy
        screen
        sdrpp
        serial-studio
        shared-mime-info
        sherlock
        sipvicious
        sleuthkit
        slurp
        smartmontools
        smbmap
        songrec
        spice
        spice-gtk
        spice-protocol
        spooftooph
        sslscan
        subfinder
        subtitleedit
        swaks
        telegram-desktop
        texliveFull
        theharvester
        thermald
        tor-browser
        tree
        trufflehog
        udftools
        udiskie
        unar
        unicode-emoji
        universal-android-debloater
        unix-privesc-check
        unrar
        unzip
        usbutils
        util-linux
        virt-viewer
        virtio-win
        virtiofsd
        vlc
        vlc-bittorrent
        vulkan-tools
        wafw00f
        wavpack
        waybar-mpris
        waycheck
        wayland
        wayland-protocols
        wayland-utils
        waylevel
        webcamoid
        wev
        wget
        which
        whois
        wifite2
        win-spice
        wl-clipboard
        woff2
        wpscan
        x264
        x265
        xdg-user-dirs
        xdg-utils
        xfsdump
        xfsprogs
        xfstests
        xorg.xhost
        xoscope
        xvidcore
        xz
        yara
        zip
        zlib
        zpaq
        zstd
        (sddm-astronaut.override {
          embeddedTheme = "astronaut";

          themeConfig = {
            # ScreenWidth = 1920;
            # ScreenHeight = 1080;
            ScreenPadding = 0;

            BackgroundColor = dracula_theme.hex.background;
            BackgroundHorizontalAlignment = "center";
            BackgroundVerticalAlignment = "center";
            Background = wallpaper;
            CropBackground = false;
            DimBackgroundImage = "0.0";

            FullBlur = false;
            PartialBlur = false;

            HaveFormBackground = false;
            FormPosition = "center";

            HideLoginButton = false;
            HideSystemButtons = false;
            HideVirtualKeyboard = false;
            VirtualKeyboardPosition = "center";

            # MainColor = ; # TODO
            # AccentColor = ; # TODO

            # HighlightBorderColor= ; # TODO
            # HighlightBackgroundColor= ; # TODO
            # HighlightTextColor= ; # TODO

            HeaderTextColor = dracula_theme.hex.foreground;
            TimeTextColor = dracula_theme.hex.foreground;
            DateTextColor = dracula_theme.hex.foreground;

            IconColor = dracula_theme.hex.foreground;
            PlaceholderTextColor = dracula_theme.hex.foreground;
            WarningColor = dracula_theme.hex.red;

            # LoginFieldBackgroundColor = ; # TODO
            # LoginFieldTextColor = ; # TODO
            # UserIconColor = ; # TODO
            # HoverUserIconColor = ; # TODO

            # PasswordFieldBackgroundColor = ; # TODO
            # PasswordFieldTextColor = ; # TODO
            # PasswordIconColor = ; # TODO
            # HoverPasswordIconColor = ; # TODO

            # LoginButtonBackgroundColor = ; # TODO
            LoginButtonTextColor = dracula_theme.hex.foreground;

            SystemButtonsIconsColor = dracula_theme.hex.foreground;
            # HoverSystemButtonsIconsColor = ; # TODO

            SessionButtonTextColor = dracula_theme.hex.foreground;
            # HoverSessionButtonTextColor = ; # TODO

            VirtualKeyboardButtonTextColor = dracula_theme.hex.foreground;
            # HoverVirtualKeyboardButtonTextColor = ; # TODO

            DropdownBackgroundColor = dracula_theme.hex.background;
            DropdownSelectedBackgroundColor = dracula_theme.hex.current_line;
            DropdownTextColor = dracula_theme.hex.foreground;

            HeaderText = "";

            HourFormat = "\"hh:mm A\"";
            DateFormat = "\"MMMM dd, yyyy\"";

            PasswordFocus = true;
            AllowEmptyPassword = false;
          };
        })
      ]
      ++ (with unixtools; [
        arp
        fdisk
        ifconfig
        netstat
        nettools
        ping
        route
        util-linux
        whereis
      ])
      ++ (with fishPlugins; [
        async-prompt
        autopair
        done
        fish-you-should-use
      ])
      ++ (with gst_all_1; [
        gst-libav
        gst-plugins-bad
        gst-plugins-base
        gst-plugins-good
        gst-plugins-ugly
        gst-vaapi
        gstreamer
      ])
      ++ (with php84Extensions; [
        bz2
        calendar
        ctype
        curl
        dba
        dom
        exif
        ffi
        fileinfo
        filter
        ftp
        gd
        iconv
        imagick
        imap
        mailparse
        memcached
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
        readline
        session
        sockets
        sodium
        xml
        xmlreader
        xmlwriter
        xsl
        zip
        zlib
      ])
      # ++ (with php84Packages; [

      # ])
      ++ (with python313Packages; [
        black
        numpy
        pandas
        pillow
        pip
        pyserial
        seaborn
      ])
      ++ (with texlivePackages; [
        latexmk
      ])
      ++ (with ghidra-extensions; [
        findcrypt
        ghidra-delinker-extension
        ghidra-golanganalyzerextension
        ghidraninja-ghidra-scripts
        gnudisassembler
        lightkeeper
        machinelearning
        ret-sync
        sleighdevtools
        wasm
      ])
      ++ (with inkscape-extensions; [
        applytransforms
        textext
      ]);
  };

  xdg = {
    mime = {
      enable = true;

      addedAssociations = config.xdg.mime.defaultApplications;

      removedAssociations = { };

      # https://www.iana.org/assignments/media-types/media-types.xhtml # Excluding "application/x-*" and "x-scheme-handler/*"
      defaultApplications = {
        "inode/directory" = "nautilus.desktop";

        "image/aces" = "org.gnome.eog.desktop";
        "image/apng" = "org.gnome.eog.desktop";
        "image/avci" = "org.gnome.eog.desktop";
        "image/avcs" = "org.gnome.eog.desktop";
        "image/avif" = "org.gnome.eog.desktop";
        "image/bmp" = "org.gnome.eog.desktop";
        "image/cgm" = "org.gnome.eog.desktop";
        "image/dicom-rle" = "org.gnome.eog.desktop";
        "image/dpx" = "org.gnome.eog.desktop";
        "image/emf" = "org.gnome.eog.desktop";
        "image/fits" = "org.gnome.eog.desktop";
        "image/g3fax" = "org.gnome.eog.desktop";
        "image/gif" = "org.gnome.eog.desktop";
        "image/heic" = "org.gnome.eog.desktop";
        "image/heic-sequence" = "org.gnome.eog.desktop";
        "image/heif" = "org.gnome.eog.desktop";
        "image/heif-sequence" = "org.gnome.eog.desktop";
        "image/hej2k" = "org.gnome.eog.desktop";
        "image/hsj2" = "org.gnome.eog.desktop";
        "image/ief" = "org.gnome.eog.desktop";
        "image/j2c" = "org.gnome.eog.desktop";
        "image/jaii" = "org.gnome.eog.desktop";
        "image/jais" = "org.gnome.eog.desktop";
        "image/jls" = "org.gnome.eog.desktop";
        "image/jp2" = "org.gnome.eog.desktop";
        "image/jpeg" = "org.gnome.eog.desktop";
        "image/jph" = "org.gnome.eog.desktop";
        "image/jphc" = "org.gnome.eog.desktop";
        "image/jpm" = "org.gnome.eog.desktop";
        "image/jpx" = "org.gnome.eog.desktop";
        "image/jxl" = "org.gnome.eog.desktop";
        "image/jxr" = "org.gnome.eog.desktop";
        "image/jxrA" = "org.gnome.eog.desktop";
        "image/jxrS" = "org.gnome.eog.desktop";
        "image/jxs" = "org.gnome.eog.desktop";
        "image/jxsc" = "org.gnome.eog.desktop";
        "image/jxsi" = "org.gnome.eog.desktop";
        "image/jxss" = "org.gnome.eog.desktop";
        "image/ktx" = "org.gnome.eog.desktop";
        "image/ktx2" = "org.gnome.eog.desktop";
        "image/naplps" = "org.gnome.eog.desktop";
        "image/png" = "org.gnome.eog.desktop";
        "image/prs.btif" = "org.gnome.eog.desktop";
        "image/prs.pti" = "org.gnome.eog.desktop";
        "image/pwg-raster" = "org.gnome.eog.desktop";
        "image/svg+xml" = "org.gnome.eog.desktop";
        "image/t38" = "org.gnome.eog.desktop";
        "image/tiff" = "org.gnome.eog.desktop";
        "image/tiff-fx" = "org.gnome.eog.desktop";
        "image/vnd.adobe.photoshop" = "org.gnome.eog.desktop";
        "image/vnd.airzip.accelerator.azv" = "org.gnome.eog.desktop";
        "image/vnd.cns.inf2" = "org.gnome.eog.desktop";
        "image/vnd.dece.graphic" = "org.gnome.eog.desktop";
        "image/vnd.djvu" = "org.gnome.eog.desktop";
        "image/vnd.dvb.subtitle" = "org.gnome.eog.desktop";
        "image/vnd.dwg" = "org.gnome.eog.desktop";
        "image/vnd.dxf" = "org.gnome.eog.desktop";
        "image/vnd.fastbidsheet" = "org.gnome.eog.desktop";
        "image/vnd.fpx" = "org.gnome.eog.desktop";
        "image/vnd.fst" = "org.gnome.eog.desktop";
        "image/vnd.fujixerox.edmics-mmr" = "org.gnome.eog.desktop";
        "image/vnd.fujixerox.edmics-rlc" = "org.gnome.eog.desktop";
        "image/vnd.globalgraphics.pgb" = "org.gnome.eog.desktop";
        "image/vnd.microsoft.icon" = "org.gnome.eog.desktop";
        "image/vnd.mix" = "org.gnome.eog.desktop";
        "image/vnd.mozilla.apng" = "org.gnome.eog.desktop";
        "image/vnd.ms-modi" = "org.gnome.eog.desktop";
        "image/vnd.net-fpx" = "org.gnome.eog.desktop";
        "image/vnd.pco.b16" = "org.gnome.eog.desktop";
        "image/vnd.radiance" = "org.gnome.eog.desktop";
        "image/vnd.sealed.png" = "org.gnome.eog.desktop";
        "image/vnd.sealedmedia.softseal.gif" = "org.gnome.eog.desktop";
        "image/vnd.sealedmedia.softseal.jpg" = "org.gnome.eog.desktop";
        "image/vnd.svf" = "org.gnome.eog.desktop";
        "image/vnd.tencent.tap" = "org.gnome.eog.desktop";
        "image/vnd.valve.source.texture" = "org.gnome.eog.desktop";
        "image/vnd.wap.wbmp" = "org.gnome.eog.desktop";
        "image/vnd.xiff" = "org.gnome.eog.desktop";
        "image/vnd.zbrush.pcx" = "org.gnome.eog.desktop";
        "image/webp" = "org.gnome.eog.desktop";
        "image/wmf" = "org.gnome.eog.desktop";
        "image/x-emf" = "org.gnome.eog.desktop";
        "image/x-wmf" = "org.gnome.eog.desktop";

        "audio/1d-interleaved-parityfec" = "vlc.desktop";
        "audio/32kadpcm" = "vlc.desktop";
        "audio/3gpp" = "vlc.desktop";
        "audio/3gpp2" = "vlc.desktop";
        "audio/AMR" = "vlc.desktop";
        "audio/AMR-WB" = "vlc.desktop";
        "audio/ATRAC-ADVANCED-LOSSLESS" = "vlc.desktop";
        "audio/ATRAC-X" = "vlc.desktop";
        "audio/ATRAC3" = "vlc.desktop";
        "audio/BV16" = "vlc.desktop";
        "audio/BV32" = "vlc.desktop";
        "audio/CN" = "vlc.desktop";
        "audio/DAT12" = "vlc.desktop";
        "audio/DV" = "vlc.desktop";
        "audio/DVI4" = "vlc.desktop";
        "audio/EVRC" = "vlc.desktop";
        "audio/EVRC-QCP" = "vlc.desktop";
        "audio/EVRC0" = "vlc.desktop";
        "audio/EVRC1" = "vlc.desktop";
        "audio/EVRCB" = "vlc.desktop";
        "audio/EVRCB0" = "vlc.desktop";
        "audio/EVRCB1" = "vlc.desktop";
        "audio/EVRCNW" = "vlc.desktop";
        "audio/EVRCNW0" = "vlc.desktop";
        "audio/EVRCNW1" = "vlc.desktop";
        "audio/EVRCWB" = "vlc.desktop";
        "audio/EVRCWB0" = "vlc.desktop";
        "audio/EVRCWB1" = "vlc.desktop";
        "audio/EVS" = "vlc.desktop";
        "audio/G711-0" = "vlc.desktop";
        "audio/G719" = "vlc.desktop";
        "audio/G722" = "vlc.desktop";
        "audio/G7221" = "vlc.desktop";
        "audio/G723" = "vlc.desktop";
        "audio/G726-16" = "vlc.desktop";
        "audio/G726-24" = "vlc.desktop";
        "audio/G726-32" = "vlc.desktop";
        "audio/G726-40" = "vlc.desktop";
        "audio/G728" = "vlc.desktop";
        "audio/G729" = "vlc.desktop";
        "audio/G7291" = "vlc.desktop";
        "audio/G729D" = "vlc.desktop";
        "audio/G729E" = "vlc.desktop";
        "audio/GSM" = "vlc.desktop";
        "audio/GSM-EFR" = "vlc.desktop";
        "audio/GSM-HR-08" = "vlc.desktop";
        "audio/L16" = "vlc.desktop";
        "audio/L20" = "vlc.desktop";
        "audio/L24" = "vlc.desktop";
        "audio/L8" = "vlc.desktop";
        "audio/LPC" = "vlc.desktop";
        "audio/MELP" = "vlc.desktop";
        "audio/MELP1200" = "vlc.desktop";
        "audio/MELP2400" = "vlc.desktop";
        "audio/MELP600" = "vlc.desktop";
        "audio/MP4A-LATM" = "vlc.desktop";
        "audio/MPA" = "vlc.desktop";
        "audio/PCMA" = "vlc.desktop";
        "audio/PCMA-WB" = "vlc.desktop";
        "audio/PCMU" = "vlc.desktop";
        "audio/PCMU-WB" = "vlc.desktop";
        "audio/QCELP" = "vlc.desktop";
        "audio/RED" = "vlc.desktop";
        "audio/SMV" = "vlc.desktop";
        "audio/SMV-QCP" = "vlc.desktop";
        "audio/SMV0" = "vlc.desktop";
        "audio/TETRA_ACELP" = "vlc.desktop";
        "audio/TETRA_ACELP_BB" = "vlc.desktop";
        "audio/TSVCIS" = "vlc.desktop";
        "audio/UEMCLIP" = "vlc.desktop";
        "audio/VDVI" = "vlc.desktop";
        "audio/VMR-WB" = "vlc.desktop";
        "audio/aac" = "vlc.desktop";
        "audio/ac3" = "vlc.desktop";
        "audio/amr-wb+" = "vlc.desktop";
        "audio/aptx" = "vlc.desktop";
        "audio/asc" = "vlc.desktop";
        "audio/basic" = "vlc.desktop";
        "audio/clearmode" = "vlc.desktop";
        "audio/dls" = "vlc.desktop";
        "audio/dsr-es201108" = "vlc.desktop";
        "audio/dsr-es202050" = "vlc.desktop";
        "audio/dsr-es202211" = "vlc.desktop";
        "audio/dsr-es202212" = "vlc.desktop";
        "audio/eac3" = "vlc.desktop";
        "audio/encaprtp" = "vlc.desktop";
        "audio/flac" = "vlc.desktop";
        "audio/flexfec" = "vlc.desktop";
        "audio/fwdred" = "vlc.desktop";
        "audio/iLBC" = "vlc.desktop";
        "audio/ip-mr_v2.5" = "vlc.desktop";
        "audio/matroska" = "vlc.desktop";
        "audio/mhas" = "vlc.desktop";
        "audio/midi-clip" = "vlc.desktop";
        "audio/mobile-xmf" = "vlc.desktop";
        "audio/mp4" = "vlc.desktop";
        "audio/mpa-robust" = "vlc.desktop";
        "audio/mpeg" = "vlc.desktop";
        "audio/mpeg4-generic" = "vlc.desktop";
        "audio/ogg" = "vlc.desktop";
        "audio/opus" = "vlc.desktop";
        "audio/parityfec" = "vlc.desktop";
        "audio/prs.sid" = "vlc.desktop";
        "audio/raptorfec" = "vlc.desktop";
        "audio/rtp-enc-aescm128" = "vlc.desktop";
        "audio/rtp-midi" = "vlc.desktop";
        "audio/rtploopback" = "vlc.desktop";
        "audio/rtx" = "vlc.desktop";
        "audio/scip" = "vlc.desktop";
        "audio/sofa" = "vlc.desktop";
        "audio/sp-midi" = "vlc.desktop";
        "audio/speex" = "vlc.desktop";
        "audio/t140c" = "vlc.desktop";
        "audio/t38" = "vlc.desktop";
        "audio/telephone-event" = "vlc.desktop";
        "audio/tone" = "vlc.desktop";
        "audio/ulpfec" = "vlc.desktop";
        "audio/usac" = "vlc.desktop";
        "audio/vnd.3gpp.iufp" = "vlc.desktop";
        "audio/vnd.4SB" = "vlc.desktop";
        "audio/vnd.CELP" = "vlc.desktop";
        "audio/vnd.audiokoz" = "vlc.desktop";
        "audio/vnd.cisco.nse" = "vlc.desktop";
        "audio/vnd.cmles.radio-events" = "vlc.desktop";
        "audio/vnd.cns.anp1" = "vlc.desktop";
        "audio/vnd.cns.inf1" = "vlc.desktop";
        "audio/vnd.dece.audio" = "vlc.desktop";
        "audio/vnd.digital-winds" = "vlc.desktop";
        "audio/vnd.dlna.adts" = "vlc.desktop";
        "audio/vnd.dolby.heaac.1" = "vlc.desktop";
        "audio/vnd.dolby.heaac.2" = "vlc.desktop";
        "audio/vnd.dolby.mlp" = "vlc.desktop";
        "audio/vnd.dolby.mps" = "vlc.desktop";
        "audio/vnd.dolby.pl2" = "vlc.desktop";
        "audio/vnd.dolby.pl2x" = "vlc.desktop";
        "audio/vnd.dolby.pl2z" = "vlc.desktop";
        "audio/vnd.dolby.pulse.1" = "vlc.desktop";
        "audio/vnd.dra" = "vlc.desktop";
        "audio/vnd.dts" = "vlc.desktop";
        "audio/vnd.dts.hd" = "vlc.desktop";
        "audio/vnd.dts.uhd" = "vlc.desktop";
        "audio/vnd.dvb.file" = "vlc.desktop";
        "audio/vnd.everad.plj" = "vlc.desktop";
        "audio/vnd.hns.audio" = "vlc.desktop";
        "audio/vnd.lucent.voice" = "vlc.desktop";
        "audio/vnd.ms-playready.media.pya" = "vlc.desktop";
        "audio/vnd.nokia.mobile-xmf" = "vlc.desktop";
        "audio/vnd.nortel.vbk" = "vlc.desktop";
        "audio/vnd.nuera.ecelp4800" = "vlc.desktop";
        "audio/vnd.nuera.ecelp7470" = "vlc.desktop";
        "audio/vnd.nuera.ecelp9600" = "vlc.desktop";
        "audio/vnd.octel.sbc" = "vlc.desktop";
        "audio/vnd.presonus.multitrack" = "vlc.desktop";
        "audio/vnd.qcelp" = "vlc.desktop";
        "audio/vnd.rhetorex.32kadpcm" = "vlc.desktop";
        "audio/vnd.rip" = "vlc.desktop";
        "audio/vnd.sealedmedia.softseal.mpeg" = "vlc.desktop";
        "audio/vnd.vmx.cvsd" = "vlc.desktop";
        "audio/vorbis" = "vlc.desktop";
        "audio/vorbis-config" = "vlc.desktop";

        "video/1d-interleaved-parityfec" = "vlc.desktop";
        "video/3gpp" = "vlc.desktop";
        "video/3gpp-tt" = "vlc.desktop";
        "video/3gpp2" = "vlc.desktop";
        "video/AV1" = "vlc.desktop";
        "video/BMPEG" = "vlc.desktop";
        "video/BT656" = "vlc.desktop";
        "video/CelB" = "vlc.desktop";
        "video/DV" = "vlc.desktop";
        "video/FFV1" = "vlc.desktop";
        "video/H261" = "vlc.desktop";
        "video/H263" = "vlc.desktop";
        "video/H263-1998" = "vlc.desktop";
        "video/H263-2000" = "vlc.desktop";
        "video/H264" = "vlc.desktop";
        "video/H264-RCDO" = "vlc.desktop";
        "video/H264-SVC" = "vlc.desktop";
        "video/H265" = "vlc.desktop";
        "video/H266" = "vlc.desktop";
        "video/JPEG" = "vlc.desktop";
        "video/MP1S" = "vlc.desktop";
        "video/MP2P" = "vlc.desktop";
        "video/MP2T" = "vlc.desktop";
        "video/MP4V-ES" = "vlc.desktop";
        "video/MPV" = "vlc.desktop";
        "video/SMPTE292M" = "vlc.desktop";
        "video/VP8" = "vlc.desktop";
        "video/VP9" = "vlc.desktop";
        "video/encaprtp" = "vlc.desktop";
        "video/evc" = "vlc.desktop";
        "video/flexfec" = "vlc.desktop";
        "video/iso.segment" = "vlc.desktop";
        "video/jpeg2000" = "vlc.desktop";
        "video/jxsv" = "vlc.desktop";
        "video/matroska" = "vlc.desktop";
        "video/matroska-3d" = "vlc.desktop";
        "video/mj2" = "vlc.desktop";
        "video/mp4" = "vlc.desktop";
        "video/mpeg" = "vlc.desktop";
        "video/mpeg4-generic" = "vlc.desktop";
        "video/nv" = "vlc.desktop";
        "video/ogg" = "vlc.desktop";
        "video/parityfec" = "vlc.desktop";
        "video/pointer" = "vlc.desktop";
        "video/quicktime" = "vlc.desktop";
        "video/raptorfec" = "vlc.desktop";
        "video/raw" = "vlc.desktop";
        "video/rtp-enc-aescm128" = "vlc.desktop";
        "video/rtploopback" = "vlc.desktop";
        "video/rtx" = "vlc.desktop";
        "video/scip" = "vlc.desktop";
        "video/smpte291" = "vlc.desktop";
        "video/ulpfec" = "vlc.desktop";
        "video/vc1" = "vlc.desktop";
        "video/vc2" = "vlc.desktop";
        "video/vnd.CCTV" = "vlc.desktop";
        "video/vnd.dece.hd" = "vlc.desktop";
        "video/vnd.dece.mobile" = "vlc.desktop";
        "video/vnd.dece.mp4" = "vlc.desktop";
        "video/vnd.dece.pd" = "vlc.desktop";
        "video/vnd.dece.sd" = "vlc.desktop";
        "video/vnd.dece.video" = "vlc.desktop";
        "video/vnd.directv.mpeg" = "vlc.desktop";
        "video/vnd.directv.mpeg-tts" = "vlc.desktop";
        "video/vnd.dlna.mpeg-tts" = "vlc.desktop";
        "video/vnd.dvb.file" = "vlc.desktop";
        "video/vnd.fvt" = "vlc.desktop";
        "video/vnd.hns.video" = "vlc.desktop";
        "video/vnd.iptvforum.1dparityfec-1010" = "vlc.desktop";
        "video/vnd.iptvforum.1dparityfec-2005" = "vlc.desktop";
        "video/vnd.iptvforum.2dparityfec-1010" = "vlc.desktop";
        "video/vnd.iptvforum.2dparityfec-2005" = "vlc.desktop";
        "video/vnd.iptvforum.ttsavc" = "vlc.desktop";
        "video/vnd.iptvforum.ttsmpeg2" = "vlc.desktop";
        "video/vnd.motorola.video" = "vlc.desktop";
        "video/vnd.motorola.videop" = "vlc.desktop";
        "video/vnd.mpegurl" = "vlc.desktop";
        "video/vnd.ms-playready.media.pyv" = "vlc.desktop";
        "video/vnd.nokia.interleaved-multimedia" = "vlc.desktop";
        "video/vnd.nokia.mp4vr" = "vlc.desktop";
        "video/vnd.nokia.videovoip" = "vlc.desktop";
        "video/vnd.objectvideo" = "vlc.desktop";
        "video/vnd.radgamettools.bink" = "vlc.desktop";
        "video/vnd.radgamettools.smacker" = "vlc.desktop";
        "video/vnd.sealed.mpeg1" = "vlc.desktop";
        "video/vnd.sealed.mpeg4" = "vlc.desktop";
        "video/vnd.sealed.swf" = "vlc.desktop";
        "video/vnd.sealedmedia.softseal.mov" = "vlc.desktop";
        "video/vnd.uvvu.mp4" = "vlc.desktop";
        "video/vnd.vivo" = "vlc.desktop";
        "video/vnd.youtube.yt" = "vlc.desktop";

        "application/vnd.oasis.opendocument.text" = "onlyoffice-desktopeditors.desktop"; # .odt
        "application/msword" = "onlyoffice-desktopeditors.desktop"; # .doc
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
          "onlyoffice-desktopeditors.desktop"; # .docx
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template" =
          "onlyoffice-desktopeditors.desktop"; # .dotx

        "application/vnd.oasis.opendocument.spreadsheet" = "onlyoffice-desktopeditors.desktop"; # .ods
        "application/vnd.ms-excel" = "onlyoffice-desktopeditors.desktop"; # .xls
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" =
          "onlyoffice-desktopeditors.desktop"; # .xlsx
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template" =
          "onlyoffice-desktopeditors.desktop"; # .xltx

        "application/vnd.oasis.opendocument.presentation" = "onlyoffice-desktopeditors.desktop"; # .odp
        "application/vnd.ms-powerpoint" = "onlyoffice-desktopeditors.desktop"; # .ppt
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
          "onlyoffice-desktopeditors.desktop"; # .pptx
        "application/vnd.openxmlformats-officedocument.presentationml.template" =
          "onlyoffice-desktopeditors.desktop"; # .potx

        "application/pdf" = "librewolf.desktop";

        "font/collection" = "org.gnome.font-viewer.desktop";
        "font/otf" = "org.gnome.font-viewer.desktop";
        "font/sfnt" = "org.gnome.font-viewer.desktop";
        "font/ttf" = "org.gnome.font-viewer.desktop";
        "font/woff" = "org.gnome.font-viewer.desktop";
        "font/woff2" = "org.gnome.font-viewer.desktop";

        "application/gzip" = "org.gnome.FileRoller.desktop";
        "application/vnd.rar" = "org.gnome.FileRoller.desktop";
        "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
        "application/x-arj" = "org.gnome.FileRoller.desktop";
        "application/x-bzip2" = "org.gnome.FileRoller.desktop";
        "application/x-gtar" = "org.gnome.FileRoller.desktop";
        "application/x-rar-compressed " = "org.gnome.FileRoller.desktop"; # More common than "application/vnd.rar"
        "application/x-tar" = "org.gnome.FileRoller.desktop";
        "application/zip" = "org.gnome.FileRoller.desktop";

        "x-scheme-handler/http" = "librewolf.desktop";
        "x-scheme-handler/https" = "librewolf.desktop";

        "x-scheme-handler/mailto" = "thunderbird.desktop";
      };
    };

    icons.enable = true;
    sounds.enable = true;

    menus.enable = true;
    autostart.enable = true;

    terminal-exec.enable = true;

    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
      ];

      xdgOpenUsePortal = false; # Opening Programs
    };
  };

  qt = {
    enable = true;

    platformTheme = "gtk2";
    style = "gtk2";
  };

  documentation = {
    enable = true;
    dev.enable = true;
    doc.enable = true;
    info.enable = true;

    man = {
      enable = true;

      man-db = {
        enable = true;
        package = pkgs.man-db;
      };

      generateCaches = true;
    };

    nixos = {
      enable = true;
      includeAllModules = true;
      options.warningsAreErrors = false;
    };
  };

  users = {
    groups = {
      hardinfo2 = { }; # Creation
    };

    enforceIdUniqueness = true;
    mutableUsers = true;

    defaultUserShell = pkgs.fish;

    motd = "Welcome";

    users.bitscoper = {
      isNormalUser = true;

      name = "bitscoper";
      description = "Abdullah As-Sadeed"; # Full Name

      extraGroups = [
        "adbusers"
        "audio"
        "dialout"
        "hardinfo2"
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

      useDefaultShell = true;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    backupFileExtension = "old";

    sharedModules = [
      {
        home = {
          enableNixpkgsReleaseCheck = true;

          shell = {
            enableShellIntegration = true;
            enableBashIntegration = true;
            enableFishIntegration = true;
          };

          language = { };

          keyboard = { };

          pointerCursor = {
            name = cursor.theme.name;
            package = cursor.theme.package;
            size = cursor.size;

            hyprcursor = {
              enable = true;
              size = cursor.size;
            };

            gtk.enable = true;
          };

          preferXdgDirectories = true;

          # packages = with pkgs; [

          # ];

          sessionVariables = { };

          sessionSearchVariables = { };

          shellAliases = { };

          enableDebugInfo = false;

          stateVersion = "24.11";
        };

        wayland.windowManager.hyprland = {
          enable = true;
          package = pkgs.hyprland;

          systemd = {
            enable = false;
            enableXdgAutostart = true;

            # extraCommands = [

            # ];

            variables = [
              "--all"
            ];
          };

          plugins = with pkgs.hyprlandPlugins; [
            hypr-dynamic-cursors
          ];

          xwayland.enable = true;

          sourceFirst = true;

          settings = {
            monitor = [
              ", highres, auto, 1" # Name, Resolution, Position, Scale
            ];

            env = [
              "XCURSOR_SIZE, ${toString cursor.size}"
            ];

            exec-once = [
              "uwsm app -- ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"

              "uwsm app -- udiskie --tray --appindicator --automount --notify --file-manager nautilus"

              "sleep 2 && uwsm app -- keepassxc"

              "uwsm app -- wl-paste --type text --watch cliphist store"
              "uwsm app -- wl-paste --type image --watch cliphist store"

              "setfacl --modify user:jellyfin:--x ~ & adb start-server &"

              "systemctl --user start warp-taskbar"

              "rm -rf ~/.local/share/applications/waydroid.*"
            ];

            bind = [
              "SUPER, L, exec, hyprlock --immediate"
              "SUPER CTRL, L, exec, uwsm stop"
              "SUPER CTRL, P, exec, systemctl poweroff"
              "SUPER CTRL, R, exec, systemctl reboot"

              "SUPER, 1, workspace, 1"
              "SUPER, 2, workspace, 2"
              "SUPER, 3, workspace, 3"
              "SUPER, 4, workspace, 4"
              "SUPER, 5, workspace, 5"
              "SUPER, 6, workspace, 6"
              "SUPER, 7, workspace, 7"
              "SUPER, 8, workspace, 8"
              "SUPER, 9, workspace, 9"
              "SUPER, 0, workspace, 10"
              "SUPER, mouse_down, workspace, e+1"
              "SUPER, mouse_up, workspace, e-1"
              "SUPER, S, togglespecialworkspace, magic"

              "SUPER, left, movefocus, l"
              "SUPER, right, movefocus, r"
              "SUPER, up, movefocus, u"
              "SUPER, down, movefocus, d"

              "SUPER SHIFT, T, togglesplit,"
              "SUPER SHIFT, F, togglefloating,"
              ", F11, fullscreen, 0"
              "SUPER, Q, killactive,"

              "SUPER SHIFT, 1, movetoworkspace, 1"
              "SUPER SHIFT, 2, movetoworkspace, 2"
              "SUPER SHIFT, 3, movetoworkspace, 3"
              "SUPER SHIFT, 4, movetoworkspace, 4"
              "SUPER SHIFT, 5, movetoworkspace, 5"
              "SUPER SHIFT, 6, movetoworkspace, 6"
              "SUPER SHIFT, 7, movetoworkspace, 7"
              "SUPER SHIFT, 8, movetoworkspace, 8"
              "SUPER SHIFT, 9, movetoworkspace, 9"
              "SUPER SHIFT, 0, movetoworkspace, 10"
              "SUPER SHIFT, S, movetoworkspace, special:magic"

              "SUPER SHIFT ALT, 1, movetoworkspacesilent, 1"
              "SUPER SHIFT ALT, 2, movetoworkspacesilent, 2"
              "SUPER SHIFT ALT, 3, movetoworkspacesilent, 3"
              "SUPER SHIFT ALT, 4, movetoworkspacesilent, 4"
              "SUPER SHIFT ALT, 5, movetoworkspacesilent, 5"
              "SUPER SHIFT ALT, 6, movetoworkspacesilent, 6"
              "SUPER SHIFT ALT, 7, movetoworkspacesilent, 7"
              "SUPER SHIFT ALT, 8, movetoworkspacesilent, 8"
              "SUPER SHIFT ALT, 9, movetoworkspacesilent, 9"
              "SUPER SHIFT ALT, 0, movetoworkspacesilent, 10"
              "SUPER SHIFT ALT, S, movetoworkspacesilent, special:magic"

              "SUPER, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

              ", PRINT, exec, filename=\"$(xdg-user-dir DOWNLOAD)/Screenshot_$(date +'%Y-%B-%d_%I-%M-%S_%p').png\"; grim -g \"$(slurp -d)\" -t png -l 9 \"$filename\" && wl-copy < \"$filename\""

              "SUPER, A, exec, rofi -show drun -disable-history"
              "SUPER, R, exec, rofi -show run -disable-history"

              "SUPER, T, exec, blackbox"
              "SUPER ALT, T, exec, blackbox sh -c \"bash\""

              ", XF86Explorer, exec, nautilus"
              "SUPER, F, exec, nautilus"

              "SUPER, U, exec, missioncenter"

              "SUPER, W, exec, librewolf"
              "SUPER ALT, W, exec, librewolf --private-window"

              ", XF86Mail, exec, thunderbird"
              "SUPER, M, exec, thunderbird"

              "SUPER, E, exec, zeditor"
              "SUPER, D, exec, dbeaver"

              "SUPER, V, exec, vlc"
            ];

            bindm = [
              "SUPER, mouse:272, movewindow"
              "SUPER, mouse:273, resizewindow"
            ];

            bindl = [
              ", XF86AudioPlay, exec, playerctl play-pause"
              ", XF86AudioPause, exec, playerctl play-pause"
              ", XF86AudioStop, exec, playerctl stop"

              ", XF86AudioPrev, exec, playerctl previous"
              ", XF86AudioNext, exec, playerctl next"
            ];

            bindel = [
              ", XF86MonBrightnessUp, exec, brightnessctl s 1%+"
              ", XF86MonBrightnessDown, exec, brightnessctl s 1%-"

              ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+"
              ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"
              ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
              ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
            ];

            general = {
              allow_tearing = false;

              gaps_workspaces = 0;

              layout = "dwindle";

              gaps_in = 2;
              gaps_out = 4;

              no_border_on_floating = false;

              border_size = 1;
              "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg"; # TODO
              "col.inactive_border" = "rgba(595959aa)"; # TODO

              no_focus_fallback = false;

              resize_on_border = true;
              hover_icon_on_border = true;

              snap = {
                enabled = true;
                border_overlap = false;
              };
            };

            ecosystem = {
              no_update_news = false;
            };

            misc = {
              disable_autoreload = false;

              allow_session_lock_restore = true;

              key_press_enables_dpms = true;
              mouse_move_enables_dpms = true;

              vfr = true;
              vrr = 1;

              render_ahead_of_time = false;

              mouse_move_focuses_monitor = true;

              disable_hyprland_logo = false;
              force_default_wallpaper = 1;
              disable_splash_rendering = true;

              font_family = font_name.sans_serif;

              close_special_on_empty = true;

              animate_mouse_windowdragging = false;
              animate_manual_resizes = false;

              exit_window_retains_fullscreen = false;

              layers_hog_keyboard_focus = true;

              focus_on_activate = false;

              middle_click_paste = true;
            };

            dwindle = {
              pseudotile = false;

              use_active_for_splits = true;
              force_split = 0; # Follows Mouse
              smart_split = false;
              preserve_split = true;

              smart_resizing = true;
            };

            xwayland = {
              enabled = true;
              force_zero_scaling = true;
              use_nearest_neighbor = true;
            };

            windowrule = [
              "suppressevent maximize, class:.*"
              "nofocus, class:^$, title:^$, xwayland:1, floating:1, fullscreen:0, pinned:0"
            ];

            input = {
              kb_layout = "us";

              numlock_by_default = true;

              follow_mouse = 1;
              focus_on_close = 1;

              left_handed = false;
              sensitivity = 1; # Mouse
              natural_scroll = false;

              touchpad = {
                natural_scroll = true;

                tap-to-click = true;
                tap-and-drag = true;
                drag_lock = true;

                disable_while_typing = true;
              };

              touchdevice = {
                enabled = true;
              };

              tablet = {
                left_handed = false;
              };
            };

            cursor = {
              no_hardware_cursors = false;

              enable_hyprcursor = true;
              sync_gsettings_theme = true;

              persistent_warps = true;

              no_warps = false;

              hide_on_key_press = false;
              hide_on_touch = true;
            };

            "plugin:dynamic-cursors" = {
              enabled = true;
              hyprcursor = {
                enabled = true;
                nearest = true;
                resolution = -1;
              };

              threshold = 1;
              mode = "rotate";
              rotate = {
                length = cursor.size;
              };

              shake = {
                enabled = true;
                effects = false;
                nearest = true;
                ipc = true;
              };
            };

            binds = {
              disable_keybind_grabbing = true;
              pass_mouse_when_bound = false;

              window_direction_monitor_fallback = true;
            };

            gestures = {
              # Touchpad
              workspace_swipe = true;
              workspace_swipe_invert = true;

              # Touchscreen
              workspace_swipe_touch = false;
              workspace_swipe_touch_invert = false;

              workspace_swipe_create_new = true;
              workspace_swipe_forever = true;
            };

            decoration = {
              dim_special = 0.25;

              rounding = 8;

              active_opacity = 1.0;
              fullscreen_opacity = 1.0;
              inactive_opacity = 1.0;

              dim_inactive = false;
              dim_strength = 0.0;

              blur.enabled = false;
              shadow.enabled = false;
            };

            animations = {
              enabled = true;
              first_launch_animation = true;

              bezier = [
                "easeOutQuint, 0.23, 1, 0.32, 1"
                "easeInOutCubic, 0.65, 0.05, 0.36, 1"
                "linear, 0, 0, 1, 1"
                "almostLinear, 0.5, 0.5, 0.75, 1.0"
                "quick, 0.15, 0, 0.1, 1"
              ];

              animation = [
                "global, 1, 10, default"
                "border, 1, 5.39, easeOutQuint"
                "windows, 1, 4.79, easeOutQuint"
                "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
                "windowsOut, 1, 1.49, linear, popin 87%"
                "fadeIn, 1, 1.73, almostLinear"
                "fadeOut, 1, 1.46, almostLinear"
                "fade, 1, 3.03, quick"
                "layers, 1, 3.81, easeOutQuint"
                "layersIn, 1, 4, easeOutQuint, fade"
                "layersOut, 1, 1.5, linear, fade"
                "fadeLayersIn, 1, 1.79, almostLinear"
                "fadeLayersOut, 1, 1.39, almostLinear"
                "workspaces, 1, 1.94, almostLinear, fade"
                "workspacesIn, 1, 1.21, almostLinear, fade"
                "workspacesOut, 1, 1.94, almostLinear, fade"
              ];
              # Name, On/Off, Speed, Curve [, Style]
            };
          };

          extraConfig = '''';
        };

        xdg = {
          mime.enable = true;

          mimeApps = {
            enable = true;

            associations = {
              added = config.xdg.mime.addedAssociations;

              removed = config.xdg.mime.removedAssociations;
            };

            defaultApplications = config.xdg.mime.defaultApplications;
          };

          configFile = {
            "mimeapps.list".force = true;
          };
        };

        gtk = {
          enable = true;

          theme = {
            name = "Dracula";
            package = pkgs.dracula-theme;
          };

          iconTheme = {
            name = "Papirus-Dark";
            package = (
              pkgs.papirus-icon-theme.override {
                color = "black";
              }
            );
          };

          cursorTheme = {
            name = cursor.theme.name;
            package = cursor.theme.package;
            size = cursor.size;
          };

          font = {
            name = font_name.sans_serif;
            package = pkgs.nerd-fonts.noto;
            size = 11;
          };
        };

        qt = {
          enable = true;

          platformTheme.name = "gtk2";

          style = {
            name = "gtk2";
            # package = pkgs. ;
          };
        };

        services = {
          mako = {
            enable = true;
            package = pkgs.mako;

            actions = true;

            anchor = "top-right";
            layer = "top";
            margin = "10";
            sort = "-time";
            maxVisible = 5; # -1 = Disabled
            ignoreTimeout = false;
            defaultTimeout = 0; # 0 = Disabled

            borderRadius = 8;
            borderSize = 1;
            borderColor = dracula_theme.hex.comment;
            backgroundColor = dracula_theme.hex.background;
            padding = "4";
            icons = true;
            maxIconSize = 16;
            markup = true;
            font = "${font_name.sans_serif} 11";
            textColor = dracula_theme.hex.foreground;
            format = "<b>%s</b>\\n%b";

            extraConfig = ''
              history=1

              on-notify=none
              on-button-left=dismiss
              on-button-right=exec makoctl menu rofi -dmenu -p 'Choose Action'
              on-button-middle=none
              on-touch=exec  makoctl menu rofi -dmenu -p 'Choose Action'

              [urgency=low]
              border-color=${dracula_theme.hex.current_line}

              [urgency=normal]
              border-color=${dracula_theme.hex.comment}

              [urgency=high]
              border-color=${dracula_theme.hex.red}
            '';
          };

          hyprpaper = {
            enable = true;
            package = pkgs.hyprpaper;

            settings = {
              ipc = "on";

              splash = false;

              preload = [
                wallpaper
              ];

              wallpaper = [
                ", ${wallpaper}"
              ];
            };
          };
        };

        programs = {
          hyprlock = {
            enable = true;
            package = pkgs.hyprlock;

            sourceFirst = true;

            settings = {
              general = {
                disable_loading_bar = true;
                immediate_render = true;
                fractional_scaling = 2; # 2 = Automatic

                no_fade_in = false;
                no_fade_out = false;

                hide_cursor = false;
                text_trim = false;

                grace = 0;
                ignore_empty_input = true;
              };

              auth = {
                pam = {
                  enabled = true;
                };
              };

              background = [
                {
                  monitor = "";
                  path = wallpaper;
                }
              ];

              label = [
                {
                  monitor = "";
                  halign = "center";
                  valign = "top";
                  position = "0, -128";

                  text_align = "center";
                  font_family = font_name.sans_serif;
                  color = dracula_theme.rgba.foreground;
                  font_size = 64;
                  text = "$TIME12";
                }

                {
                  monitor = "";
                  halign = "center";
                  valign = "center";
                  position = "0, 0";

                  text_align = "center";
                  font_family = font_name.sans_serif;
                  color = dracula_theme.rgba.foreground;
                  font_size = 16;
                  text = "$DESC"; # Full Name
                }
              ];

              input-field = [
                {
                  monitor = "";
                  halign = "center";
                  valign = "bottom";
                  position = "0, 128";

                  size = "256, 48";
                  rounding = 16;
                  outline_thickness = 1;
                  # outer_color = ""; # TODO
                  shadow_passes = 0;
                  hide_input = false;
                  inner_color = dracula_theme.rgba.current_line;
                  font_family = font_name.sans_serif;
                  font_color = dracula_theme.rgba.foreground;
                  placeholder_text = "Password";
                  dots_center = true;
                  dots_rounding = -1;

                  fade_on_empty = true;

                  invert_numlock = false;
                  # capslock_color = ""; # TODO
                  # numlock_color = ""; # TODO
                  # bothlock_color = ""; # TODO

                  # check_color = ""; # TODO
                  # fail_color = ""; # TODO
                  fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
                  fail_timeout = 2000;
                }
              ];
            };

            extraConfig = '''';
          };

          rofi =
            let
              rofi_theme = pkgs.writeTextFile {
                name = "Rofi_Theme.rasi";
                text = ''
                  * {
                    margin: 0;
                    background-color: transparent;
                    padding: 0;
                    spacing: 0;
                    text-color: ${dracula_theme.hex.foreground};
                  }

                  window {
                    width: 768px;
                    border: 1px;
                    border-radius: 16px;
                    border-color: ${dracula_theme.hex.purple};
                    background-color: ${dracula_theme.hex.background};
                  }

                  mainbox {
                    padding: 16px;
                  }

                  inputbar {
                    border: 1px;
                    border-radius: 8px;
                    border-color: ${dracula_theme.hex.comment};
                    background-color: ${dracula_theme.hex.current_line};
                    padding: 8px;
                    spacing: 8px;
                    children: [ "prompt", "entry" ];
                  }

                  prompt {
                    text-color: ${dracula_theme.hex.foreground};
                  }

                  entry {
                    placeholder-color: ${dracula_theme.hex.comment};
                    placeholder: "Search";
                  }

                  listview {
                    margin: 16px 0px 0px 0px;
                    fixed-height: false;
                    lines: 8;
                    columns: 2;
                  }

                  element {
                    border-radius: 8px;
                    padding: 8px;
                    spacing: 8px;
                    children: [ "element-icon", "element-text" ];
                  }

                  element-icon {
                    vertical-align: 0.5;
                    size: 1em;
                  }

                  element-text {
                    text-color: inherit;
                  }

                  element.selected {
                    background-color: ${dracula_theme.hex.current_line};
                  }
                '';
              };
            in
            {
              enable = true;
              package = pkgs.rofi-wayland;
              # plugins = with pkgs; [

              # ];

              cycle = false;
              terminal = "${pkgs.blackbox-terminal}/bin/blackbox";

              location = "center";

              font = "${font_name.sans_serif} 11";

              extraConfig = {
                show-icons = true;
                display-drun = "Applications";

                disable-history = false;
              };

              theme = "${rofi_theme}";
            };

          waybar = {
            enable = true;
            package = pkgs.waybar;

            systemd = {
              enable = true;
              # target = ;
            };

            settings = {
              top_bar = {
                start_hidden = false;
                reload_style_on_change = true;
                position = "top";
                exclusive = true;
                layer = "top";
                passthrough = false;
                fixed-center = true;
                spacing = 4;

                modules-left = [
                  "power-profiles-daemon"
                  "idle_inhibitor"
                  "backlight"
                  "pulseaudio"
                  "bluetooth"
                  "network"
                ];

                modules-center = [
                  "clock"
                ];

                modules-right = [
                  "privacy"
                  "mpris"
                  "keyboard-state"
                  "systemd-failed-units"
                  "disk"
                  "memory"
                  "cpu"
                  "battery"
                ];

                power-profiles-daemon = {
                  format = "{icon}";
                  format-icons = {
                    performance = "";
                    balanced = "";
                    power-saver = "";
                  };

                  tooltip = true;
                  tooltip-format = "Driver: {driver}\nProfile: {profile}";
                };

                idle_inhibitor = {
                  start-activated = false;

                  format = "{icon}";
                  format-icons = {
                    activated = "";
                    deactivated = "";
                  };

                  tooltip = true;
                  tooltip-format-activated = "{status}";
                  tooltip-format-deactivated = "{status}";
                };

                backlight = {
                  device = "intel_backlight";
                  interval = 1;

                  format = "{percent}% {icon}";
                  format-icons = [
                    ""
                    ""
                    ""
                    ""
                    ""
                    ""
                    ""
                    ""
                    ""
                  ];

                  tooltip = true;
                  tooltip-format = "{percent}% {icon}";

                  on-scroll-up = "brightnessctl s +1%";
                  on-scroll-down = "brightnessctl s 1%-";
                  reverse-scrolling = false;
                  reverse-mouse-scrolling = false;
                  scroll-step = 1.0;
                };

                pulseaudio = {
                  format = "{volume}% {icon} {format_source}";
                  format-muted = "{icon} {format_source}";

                  format-bluetooth = "{volume}% {icon} 󰂱 {format_source}";
                  format-bluetooth-muted = "{icon} 󰂱 {format_source}";

                  format-source = " {volume}% ";
                  format-source-muted = "";

                  format-icons = {
                    default = [
                      ""
                      ""
                      ""
                    ];
                    default-muted = "";

                    speaker = "󰓃";
                    speaker-muted = "󰓄";

                    headphone = "󰋋";
                    headphone-muted = "󰟎";

                    headset = "󰋎";
                    headset-muted = "󰋐";

                    hands-free = "󰏳";
                    hands-free-muted = "󰗿";

                    phone = "";
                    phone-muted = "";

                    portable = "";
                    portable-muted = "";

                    hdmi = "󰽟";
                    hdmi-muted = "󰽠";

                    hifi = "󰴸";
                    hifi-muted = "󰓄";

                    car = "󰄋";
                    car-muted = "󰸜";
                  };

                  tooltip = true;
                  tooltip-format = "{desc}";

                  scroll-step = 1.0;
                  reverse-scrolling = false;
                  reverse-mouse-scrolling = false;
                  max-volume = 100;
                  on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+";
                  on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-";

                  on-click = "pwvucontrol";
                };

                bluetooth = {
                  format = "{status} {icon}";
                  format-disabled = "Disabled {icon}";
                  format-off = "Off {icon}";
                  format-on = "On {icon}";
                  format-connected = "{device_alias} {icon}";
                  format-connected-battery = "{device_alias} 󰂱 ({device_battery_percentage}%)";
                  format-icons = {
                    no-controller = "󰂲";
                    disabled = "󰂲";
                    off = "󰂲";
                    on = "󰂯";
                    connected = "󰂱";
                  };

                  tooltip = true;
                  tooltip-format = "Status: {status}\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}";
                  tooltip-format-disabled = "Status: Disabled";
                  tooltip-format-off = "Status: Off";
                  tooltip-format-on = "Status: On\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}";
                  tooltip-format-connected = "Status: Connected\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}\nConnected Devices ({num_connections}): {device_enumerate}";
                  tooltip-format-connected-battery = "Status: Connected\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}\nConnected Devices ({num_connections}): {device_enumerate}";
                  tooltip-format-enumerate-connected = "\n\tAddress: {device_address} ({device_address_type})\n\tAlias: {device_alias}";
                  tooltip-format-enumerate-connected-battery = "\n\tAddress: {device_address} ({device_address_type})\n\tAlias: {device_alias}\n\tBattery: {device_battery_percentage}%";

                  on-click = "blueman-manager";
                };

                network = {
                  interval = 1;

                  format = "{bandwidthUpBytes} {bandwidthDownBytes}";
                  format-disconnected = "Disconnected 󱘖";
                  format-linked = "No IP 󰀦";
                  format-ethernet = "{bandwidthUpBytes}   {bandwidthDownBytes}";
                  format-wifi = "{bandwidthUpBytes}   {bandwidthDownBytes}";

                  tooltip = true;
                  tooltip-format = "Interface: {ifname}\nGateway: {gwaddr}\nSubnet Mask: {netmask}\nCIDR Notation: {cidr}\nIP Address: {ipaddr}\nUp Speed: {bandwidthUpBytes}\nDown Speed: {bandwidthDownBytes}\nTotal Speed: {bandwidthTotalBytes}";
                  tooltip-format-disconnected = "Disconnected";
                  tooltip-format-ethernet = "Interface: {ifname}\nGateway: {gwaddr}\nSubnet Mask: {netmask}\nCIDR Notation= {cidr}\nIP Address: {ipaddr}\nUp Speed: {bandwidthUpBytes}\nDown Speed: {bandwidthDownBytes}\nTotal Speed: {bandwidthTotalBytes}";
                  tooltip-format-wifi = "Interface: {ifname}\nESSID: {essid}\nFrequency: {frequency} GHz\nStrength: {signaldBm} dBm ({signalStrength}%)\nGateway: {gwaddr}\nSubnet Mask: {netmask}\nCIDR Notation: {cidr}\nIP Address: {ipaddr}\nUp Speed: {bandwidthUpBytes}\nDown Speed: {bandwidthDownBytes}\nTotal Speed: {bandwidthTotalBytes}";

                  on-click = "nm-connection-editor";
                };

                clock = {
                  timezone = config.time.timeZone;
                  locale = "en_US";
                  interval = 1;

                  format = "{:%I:%M:%S %p}";
                  format-alt = "{:%A, %B %d, %Y}";

                  tooltip = true;
                  tooltip-format = "<tt><small>{calendar}</small></tt>";

                  calendar = {
                    mode = "year";
                    mode-mon-col = 3;
                    weeks-pos = "right";

                    format = {
                      months = "<b>{}</b>";
                      days = "{}";
                      weekdays = "<b>{}</b>";
                      weeks = "<i>{:%U}</i>";
                      today = "<u>{}</u>";
                    };
                  };
                };

                mpris = {
                  interval = 1;

                  format = "{player_icon}";

                  tooltip-format = "Title: {title}\nArtist: {artist}\nAlbum: {album}\n{status}: {position}/{length}\nPlayer: {player}";

                  player-icons = {
                    default = "";

                    vlc = "󰕼";
                    chromium = "";
                  };
                };

                privacy = {
                  icon-size = 14;
                  icon-spacing = 8;
                  transition-duration = 200;

                  modules = [
                    {
                      type = "screenshare";
                      tooltip = true;
                      tooltip-icon-size = 16;
                    }
                    {
                      type = "audio-in";
                      tooltip = true;
                      tooltip-icon-size = 16;
                    }
                  ];
                };

                keyboard-state = {
                  capslock = true;
                  numlock = true;

                  format = {
                    capslock = "󰪛";
                    numlock = "󰎦";
                  };
                };

                systemd-failed-units = {
                  system = true;
                  user = true;

                  hide-on-ok = false;

                  format = "{nr_failed_system}, {nr_failed_user} ";
                  format-ok = "";
                };

                disk = {
                  path = "/";
                  unit = "GB";
                  interval = 1;

                  format = "{percentage_used}% 󰋊";

                  tooltip = true;
                  tooltip-format = "Total: {specific_total} GB\nUsed: {specific_used} GB ({percentage_used}%)\nFree: {specific_free} GB ({percentage_free}%)";

                  on-click = "missioncenter";
                };

                memory = {
                  interval = 1;

                  format = "{percentage}% ";

                  tooltip = true;
                  tooltip-format = "Used RAM: {used} GiB ({percentage}%)\nUsed Swap: {swapUsed} GiB ({swapPercentage}%)\nAvailable RAM: {avail} GiB\nAvailable Swap: {swapAvail} GiB";

                  on-click = "missioncenter";
                };

                cpu = {
                  interval = 1;

                  format = "{usage}% ";

                  tooltip = true;

                  on-click = "missioncenter";
                };

                battery = {
                  bat = "BAT0";
                  adapter = "AC0";
                  design-capacity = false;
                  weighted-average = true;
                  interval = 1;

                  full-at = 100;
                  states = {
                    warning = 25;
                    critical = 10;
                  };

                  format = "{capacity}% {icon}";
                  format-plugged = "{capacity}% ";
                  format-charging = "{capacity}% ";
                  format-full = "{capacity}% {icon}";
                  format-alt = "{time} {icon}";
                  format-time = "{H} h {m} min";
                  format-icons = [
                    ""
                    ""
                    ""
                    ""
                    ""
                  ];

                  tooltip = true;
                  tooltip-format = "Capacity: {capacity}%\nPower: {power} W\n{timeTo}\nCycles: {cycles}\nHealth: {health}%";
                };
              };

              bottom_bar = {
                start_hidden = false;
                reload_style_on_change = true;
                position = "bottom";
                exclusive = true;
                layer = "top";
                passthrough = false;
                fixed-center = true;
                spacing = 0;

                modules-left = [
                  "hyprland/workspaces"
                  "wlr/taskbar"
                ];

                modules-center = [
                  "hyprland/window"
                ];

                modules-right = [
                  "tray"
                ];

                "hyprland/workspaces" = {
                  all-outputs = false;
                  show-special = true;
                  special-visible-only = false;
                  active-only = false;
                  format = "{name}";
                  move-to-monitor = false;
                };

                "wlr/taskbar" = {
                  all-outputs = false;
                  active-first = false;
                  sort-by-app-id = false;
                  format = "{icon}";
                  icon-theme = "Dracula";
                  icon-size = 14;
                  markup = true;

                  tooltip = true;
                  tooltip-format = "Title: {title}\nName: {name}\nID: {app_id}\nState: {state}";

                  on-click = "activate";
                };

                "hyprland/window" = {
                  separate-outputs = true;
                  icon = false;

                  format = "{title}";
                };

                tray = {
                  show-passive-items = true;
                  reverse-direction = false;
                  icon-size = 14;
                  spacing = 4;
                };
              };
            };

            style = ''
              * {
                font-family: ${font_name.sans_serif};
                font-size: 14px;
              }

              window#waybar {
                border: none;
                background-color: transparent;
              }

              .modules-right > widget:last-child > #workspaces {
                margin-right: 0;
              }

              .modules-left > widget:first-child > #workspaces {
                margin-left: 0;
              }

              #power-profiles-daemon,
              #idle_inhibitor,
              #backlight,
              #pulseaudio,
              #bluetooth,
              #network,
              #keyboard-state,
              #clock,
              #mpris,
              #privacy,
              #systemd-failed-units,
              #disk,
              #memory,
              #cpu,
              #battery,
              #window {
                border-radius: 16px;
                background-color: ${dracula_theme.hex.background};
                padding: 2px 8px;
                color: ${dracula_theme.hex.foreground};
              }

              #power-profiles-daemon.power-saver {
                color: ${dracula_theme.hex.green};
              }

              #power-profiles-daemon.balanced {
                color: ${dracula_theme.hex.cyan};
              }

              #power-profiles-daemon.performance {
                color: ${dracula_theme.hex.foreground};
              }

              #idle_inhibitor.deactivated {
                color: ${dracula_theme.hex.foreground};
              }

              #idle_inhibitor.activated {
                color: ${dracula_theme.hex.cyan};
              }

              #pulseaudio.muted,
              #pulseaudio.source-muted {
                color: ${dracula_theme.hex.red};
              }

              #pulseaudio.bluetooth {
                color: ${dracula_theme.hex.foreground};
              }

              #bluetooth.no-controller,
              #bluetooth.disabled,
              #bluetooth.off {
                color: ${dracula_theme.hex.red};
              }

              #bluetooth.on,
              #bluetooth.discoverable,
              #bluetooth.pairable {
                color: ${dracula_theme.hex.foreground};
              }

              #bluetooth.discovering,
              #bluetooth.connected {
                color: ${dracula_theme.hex.cyan};
              }

              #network.disabled,
              #network.disconnected,
              #network.linked {
                color: ${dracula_theme.hex.red};
              }

              #network.etherenet,
              #network.wifi {
                color: ${dracula_theme.hex.foreground};
              }

              #mpris.playing {
                color: ${dracula_theme.hex.cyan};
              }

              #privacy-item.audio-in,
              #privacy-item.screenshare {
                color: ${dracula_theme.hex.cyan};
              }

              #keyboard-state label {
                margin: 0px 4px;
              }

              #keyboard-state label.locked {
                color: ${dracula_theme.hex.cyan};
              }

              #systemd-failed-units.ok {
                color: ${dracula_theme.hex.foreground};
              }

              #systemd-failed-units.degraded {
                color: ${dracula_theme.hex.red};
              }

              #battery.plugged,
              #battery.full {
                color: ${dracula_theme.hex.foreground};
              }

              #battery.charging {
                color: ${dracula_theme.hex.cyan};
              }

              #battery.warning {
                color: ${dracula_theme.hex.yellow};
              }

              #battery.critical {
                color: ${dracula_theme.hex.red};
              }

              #workspaces,
              #taskbar,
              #tray {
                background-color: transparent;
              }

              button {
                margin: 0px 2px;
                border-radius: 16px;
                background-color: ${dracula_theme.hex.background};
                padding: 0px;
                color: ${dracula_theme.hex.foreground};
              }

              button * {
                padding: 0px 4px;
              }

              button.active {
                background-color: ${dracula_theme.hex.current_line};
              }

              #window label {
                padding: 0px 4px;
                font-size: 11px;
              }

              #tray > widget {
                border-radius: 16px;
                background-color: ${dracula_theme.hex.background};
                color: ${dracula_theme.hex.foreground};
              }

              #tray image {
                padding: 0px 8px;
              }

              #tray > .passive {
                -gtk-icon-effect: dim;
              }

              #tray > .active {
                background-color: ${dracula_theme.hex.current_line};
              }

              #tray > .needs-attention {
                background-color: ${dracula_theme.hex.comment};
                -gtk-icon-effect: highlight;
              }

              #tray > widget:hover {
                background-color: ${dracula_theme.hex.current_line};
              }
            '';
          };

          dircolors = {
            enable = true;
            package = pkgs.coreutils;

            enableBashIntegration = true;
            enableFishIntegration = true;

            settings = { };

            extraConfig = '''';
          };

          nix-your-shell = {
            enable = true;
            package = pkgs.nix-your-shell;

            enableFishIntegration = true;
          };

          librewolf = {
            enable = true;
            languagePacks = [

            ];

            settings = {
              "privacy.resistFingerprinting" = false;
            };
          };

          zed-editor = {
            enable = true;
            package = pkgs.zed-editor;
            installRemoteServer = false;

            # extraPackages = with pkgs; [

            # ];

            extensions = [
              "basher"
              "csv"
              "dart"
              "docker-compose"
              "dockerfile"
              "dracula"
              "env"
              "fish"
              "flutter-snippets"
              "http"
              "hyprlang"
              "ini"
              "latex"
              "live-server"
              "log"
              "make"
              "mermaid"
              "nix"
              "php"
              "postgres-language-server"
              "pylsp"
              "python-refactoring"
              "python-requirements"
              "rainbow-csv"
              "rpmspec"
              "scheme"
              "sql"
              "ssh-config"
              "ultralytics-snippets"
              "unicode"
              "xml"
            ];

            userSettings = {
              features = {
                copilot = true;
              };

              load_direnv = "shell_hook";

              enable_language_server = true;

              languages = {
                Nix = {
                  language_servers = [
                    "nixd"
                  ];

                  formatter = {
                    external = {
                      command = "nixfmt";
                    };
                  };
                };
              };

              lsp = {
                nixd = {
                  initialization_options = {
                    formatting = {
                      command = [
                        "nixfmt"
                      ];
                    };
                  };
                };
              };

              diagnostics = {
                include_warnings = true;

                inline = {
                  enabled = true;
                };
              };

              git = { };

              telemetry = {
                diagnostics = false;
                metrics = false;
              };

              theme = {
                mode = "dark";
                dark = "One Dark";
                light = "One Light";
              };

              icon_theme = {
                mode = "dark";
                dark = "Zed (Default)";
                light = "Zed (Default)";
              };

              ui_font_family = font_name.sans_serif;

              project_panel = {
                auto_fold_dirs = false;
                auto_reveal_entries = true;
                button = true;
                dock = "left";
                file_icons = true;
                folder_icons = true;
                git_status = true;
                show_diagnostics = "all";

                indent_guides = {
                  show = "always";
                };

                scrollbar = {
                  show = "always";
                };
              };

              outline_panel = {
                auto_fold_dirs = false;
                auto_reveal_entries = true;
                button = true;
                dock = "left";
                file_icons = true;
                folder_icons = true;
                git_status = true;

                indent_guides = {
                  show = "always";
                };

                scrollbar = {
                  show = "always";
                };
              };

              tab_bar = {
                show = true;
                show_nav_history_buttons = true;
                show_tab_bar_buttons = true;
              };

              preview_tabs = {
                enabled = true;
                enable_preview_from_code_navigation = true;
                enable_preview_from_file_finder = true;
              };

              tabs = {
                activate_on_close = "history";
                close_position = "right";
                file_icons = true;
                git_status = true;
                show_close_button = "hover";
                show_diagnostic = "all";
              };

              toolbar = {
                breadcrumbs = true;
                quick_actions = true;
                selections_menu = true;
              };

              scrollbar = {
                cursors = true;
                diagnostics = "all";
                git_diff = true;
                search_results = true;
                selected_symbol = true;
                selected_text = true;
                show = "always";

                axes = {
                  horizontal = true;
                  vertical = true;
                };
              };

              indent_guides = {
                enabled = true;
                coloring = "indent_aware";
                # background_coloring = "indent_aware";
              };

              assistant = {
                button = true;
                dock = "right";
                enabled = true;
              };

              terminal = {
                blinking = "terminal_controlled";
                button = true;
                copy_on_select = false;
                dock = "bottom";
                font_family = font_name.mono;
                line_height = "standard";
                shell = "system";
                working_directory = "current_project_directory";

                toolbar = {
                  breadcrumbs = true;
                };

                scrollbar = {
                  show = "always";
                };

                detect_venv = {
                  on = {
                    directories = [
                      ".env"
                      ".venv"
                      "env"
                      "venv"
                    ];
                    activate_script = "default";
                  };
                };
              };

              show_call_status_icon = true;

              buffer_font_family = font_name.mono;
              soft_wrap = "editor_width";
              show_whitespaces = "all";
              cursor_blink = true;
              cursor_shape = "bar";

              hover_popover_enabled = true;
              current_line_highlight = "all";
              selection_highlight = true;

              seed_search_query_from_cursor = "selection";
              use_smartcase_search = false;

              show_completions_on_input = true;
              show_completion_documentation = true;
              show_edit_predictions = true;

              hard_tabs = false;

              use_autoclose = true;
              always_treat_brackets_as_autoclosed = false;

              format_on_save = "on";
              remove_trailing_whitespace_on_save = false;
              ensure_final_newline_on_save = true;

              calls = {
                mute_on_join = true;
                share_on_join = false;
              };

              confirm_quit = false;
            };

            userKeymaps = { };
          };

          matplotlib = {
            enable = true;

            config = { };

            extraConfig = '''';
          };

          gh = {
            enable = true;
            package = pkgs.gh;
            # extensions = with pkgs; [

            # ];

            gitCredentialHelper = {
              enable = true;

              hosts = [
                "https://github.com"
                "https://gist.github.com"
              ];
            };

            settings = {
              git_protocol = "https";

              editor = "nano";

              aliases = { };
            };
          };

          awscli = {
            enable = true;
            package = pkgs.awscli2;

            settings = {
              "default" = {
                output = "json";
              };
            };

            credentials = { };
          };

          chromium = {
            enable = true;
            package = pkgs.ungoogled-chromium;
            dictionaries = with pkgs.hunspellDictsChromium; [
              en_US
              en-us
            ];
            # nativeMessagingHosts = with pkgs; [

            # ];

            commandLineArgs = [

            ];
          };

          obs-studio = {
            enable = true;
            package = pkgs.obs-studio;
            plugins = with pkgs.obs-studio-plugins; [
              droidcam-obs
              input-overlay
              obs-3d-effect
              obs-backgroundremoval
              obs-color-monitor
              obs-composite-blur
              obs-freeze-filter
              obs-gradient-source
              obs-gstreamer
              obs-move-transition
              obs-multi-rtmp
              obs-mute-filter
              obs-pipewire-audio-capture
              obs-replay-source
              obs-rgb-levels-filter
              obs-scale-to-sound
              obs-shaderfilter
              obs-source-clone
              obs-source-record
              obs-source-switcher
              obs-text-pthread
              obs-transition-table
              obs-tuna
              obs-vaapi
              obs-vertical-canvas
              obs-vintage-filter
              obs-vkcapture
              waveform
            ];
          };

          yt-dlp = {
            enable = true;
            package = pkgs.yt-dlp;

            settings = { };

            extraConfig = '''';
          };
        };
      }
    ];

    users.bitscoper = { };

    verbose = true;
  };
}

# sdkmanager --licenses
# flutter doctor --android-licenses

# FIXME: 05ac-033e-Gamepad > Rumble
# FIXME: ELAN7001 SPI Fingerprint Sensor
# FIXME: Hyprpaper Delay
# FIXME: MariaDB > Login
# FIXME: hardinfo2
