# By Abdullah As-Sadeed

{ config
, pkgs
, lib
, ...
}:
let
  android-nixpkgs = pkgs.callPackage
    (import (builtins.fetchGit {
      url = "https://github.com/tadfisher/android-nixpkgs.git";
    }))
    {
      channel = "stable";
    };
  android_sdk = android-nixpkgs.sdk (sdkPkgs: with sdkPkgs; [
    build-tools-35-0-0
    cmdline-tools-latest
    emulator
    extras-google-google-play-services
    platform-tools
    platforms-android-35
    system-images-android-35-google-apis-playstore-x86-64
  ]);
  android_sdk_path = "${android_sdk}/share/android-sdk";

  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/refs/heads/master.tar.gz";

  existing_library_paths = builtins.getEnv "LD_LIBRARY_PATH";

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

      kernelModules = [

      ];

      systemd = {
        enable = true;
      };

      network.ssh.enable = true;

      verbose = true;
    };

    kernelPackages = pkgs.linuxPackages_zen;

    kernelModules = [
      "kvm-intel"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      xpadneo
    ];

    extraModprobeConfig = "options kvm_intel nested=1";

    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "boot.shell_on_fail"
      "rd.systemd.show_status=true"
      # "rd.udev.log_level=3" # TODO
      # "udev.log_priority=3" # TODO
    ];

    consoleLogLevel = 5; # 5 = KERN_NOTICE

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
        "flakes"
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

    # overlays = [
    #
    # ];
  };

  appstream.enable = true;

  i18n = {
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
    supportedLocales = [
      "all"
    ];

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

      ];
      allowedUDPPorts = [

      ];
    };
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

      execWheelOnly = true;
      wheelNeedsPassword = true;
    };

    polkit = {
      enable = true;
    };
    soteria.enable = true;

    rtkit.enable = true;

    wrappers = {
      spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
    };

    audit = {
      enable = true;
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

    rtl-sdr.enable = true;

    sane = {
      enable = true;
      openFirewall = true;
    };

    steam-hardware.enable = true;
    xone.enable = true;
    xpadneo.enable = true;
  };

  virtualisation = {
    libvirtd = {
      enable = true;

      qemu = {
        package = pkgs.qemu_kvm;

        swtpm.enable = true;

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
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    oci-containers.backend = "podman";

    waydroid.enable = true;
  };

  systemd = {
    packages = with pkgs; [
      cloudflare-warp
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
      implementation = "broker";
    };

    btrfs.autoScrub = {
      enable = true;

      interval = "weekly";
      fileSystems = [
        "/"
      ];
    };

    flatpak.enable = true;

    fwupd.enable = true;

    acpid = {
      enable = true;

      powerEventCommands = '''';
      acEventCommands = '''';
      lidEventCommands = '''';

      logEvents = false;
    };

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

    fprintd = {
      enable = true;
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
        usb-blaster-udev-rules
      ];
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
      systemWide = false;
      socketActivation = true;
      audio.enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      wireplumber = {
        enable = true;

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
        local all all trust
        host all all 0.0.0.0/0 md5
        host all all ::/0 md5
        local replication all trust
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
      modules = with pkgs; [

      ];

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

    open-webui = {
      enable = true;

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

    wordpress = { };

    asterisk = {
      enable = true;

      extraConfig = '''';

      extraArguments = [

      ];
    };

    tailscale = {
      enable = true;
      disableTaildrop = false;

      port = 0; # Automatic Selection
      openFirewall = true;
    };

    tor = {
      enable = false;

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
      libraries = with pkgs; [

      ];
    };

    appimage = {
      enable = true;
      binfmt = true;
    };

    uwsm.enable = true;

    hyprland = {
      enable = true;
      withUWSM = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };

    xwayland.enable = true;

    bash = {
      completion.enable = true;
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

      interactiveShellInit = '''';
    };

    direnv = {
      enable = true;

      nix-direnv.enable = true;
      loadInNixShell = true;

      enableBashIntegration = true;
      enableFishIntegration = true;

      direnvrcExtra = '''';

      silent = false;
    };

    nix-index = {
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    java = {
      enable = true;
      package = pkgs.jdk23;
      binfmt = true;
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

        pinentryPackage = (pkgs.pinentry-rofi.override {
          rofi = pkgs.rofi-wayland;
        });
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

    virt-manager.enable = true;

    nano = {
      enable = true;
      nanorc = ''
        set linenumbers
        set softwrap
        set indicator
        set autoindent
      '';
    };

    neovim = {
      enable = true;

      viAlias = true;
      vimAlias = true;

      withPython3 = true;

      configure = {
        # customRC = '''';
      };

      defaultEditor = false;
    };

    firefox = {
      enable = true;
      package = pkgs.firefox-devedition;
      languagePacks = [
        "bn"
        "en-US"
      ];

      preferences = { };
    };

    thunderbird = {
      enable = true;
      package = pkgs.thunderbird-latest;

      preferences = { };
    };

    wireshark.enable = true;

    steam = {
      enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      protontricks.enable = true;

      localNetworkGameTransfers.openFirewall = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    localsend = {
      enable = true;
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

    variables = pkgs.lib.mkForce {
      ANDROID_SDK_ROOT = android_sdk_path;
      ANDROID_HOME = android_sdk_path;

      # LD_LIBRARY_PATH = "${pkgs.glib.out}/lib/:${pkgs.libGL}/lib/:${pkgs.stdenv.cc.cc.lib}/lib:${existing_library_paths}";
    };

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      CHROME_EXECUTABLE = "chromium";
    };

    shellAliases = {
      clean_build = "sudo nix-channel --update && sudo nix-env -u --always && sudo rm -rf /nix/var/nix/gcroots/auto/* && sudo nix-collect-garbage -d && nix-collect-garbage -d && sudo nix-store --gc && sudo nixos-rebuild switch --install-bootloader --upgrade-all";
    };

    extraInit = '''';

    loginShellInit = ''
      # rm -rf ~/.android/avd
      # ln -sf ~/.config/.android/avd ~/.android/avd
    '';

    shellInit = '''';

    interactiveShellInit = '''';

    systemPackages = with pkgs; [
      # appimagekit
      # cewl
      # dmitry
      # medusa
      # ncrack
      # reiser4progs
      # scrounge-ntfs
      # snort
      ## dart
      ## gradle
      ## gradle-completion
      ## hyprpolkitagent
      acl
      agi
      aircrack-ng
      amass
      android-backup-extractor
      android-tools
      android_sdk # Custom
      anydesk
      appimage-run
      aribb24
      aribb25
      armitage
      arping
      audacity
      audit
      autopsy
      avrdude
      awscli2
      bat
      bfcal
      binwalk
      bleachbit
      blender
      bluez-tools
      bottles
      brightnessctl
      btop
      btrfs-progs
      bulk_extractor
      bully
      burpsuite
      butt
      bzip2
      caprine
      certbot-full
      chntpw
      clang
      clang-analyzer
      clang-manpages
      clang-tools
      clinfo
      cliphist
      cloudflare-warp
      cmake
      commix
      coreutils-full
      crunch
      cryptsetup
      cups
      cups-filters
      cups-pdf-to-pdf
      cups-printers
      curlFull
      curtail
      d-spy
      davtest
      dbd
      dbeaver-bin
      dconf-editor
      dmg2img
      dmidecode
      dns2tcp
      dnschef
      dnsenum
      dnsmap
      dnsrecon
      dosfstools
      dsniff
      e2fsprogs
      efibootmgr
      enum4linux
      esptool
      ettercap
      evil-winrm
      exe2hex
      exfatprogs
      f2fs-tools
      faac
      faad2
      fastfetch
      fd
      fdk_aac
      ffmpeg-full
      ffmpegthumbnailer
      fh
      fierce
      file
      flutter327
      fping
      fritzing
      fwupd-efi
      gcal
      gcc
      gdb
      gh
      gimp-with-plugins
      git-doc
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
      gtk-vnc
      guestfs-tools
      guymager
      gzip
      hardinfo2
      hash-identifier
      hashcat
      hashdeep
      hashid
      hdparm
      hfsprogs
      hw-probe
      hwloc
      hydra-check
      hyprcursor
      hyprls
      hyprpicker
      i2c-tools
      iaito
      ideviceinstaller
      idevicerestore
      iftop
      image-roll
      inkscape
      inotify-tools
      jellyfin-media-player
      jfsutils
      john
      johnny
      jq
      keepassxc
      kernelshark
      kind
      kismet
      kubectl
      kubectl-graph
      kubectl-tree
      kubectl-view-allocations
      kubectl-view-secret
      kubernetes
      laudanum
      lbd
      lhasa
      libGL
      libaom
      libappimage
      libclang
      libde265
      libdvdcss
      libdvdnav
      libdvdread
      libfprint
      libfprint-tod
      libftdi1
      libgcc
      libgpg-error
      libguestfs
      libheif
      libideviceactivation
      libimobiledevice
      libnotify
      libopenraw
      libopus
      libosinfo
      libportal
      libreoffice-fresh
      libusb1
      libuuid
      libva-utils
      libvirt
      libvncserver
      libvpx
      libwebp
      libxfs
      lshw
      lsof
      lsscsi
      lua-language-server
      lvm2
      lynis
      macchanger
      magicrescue
      maltego
      masscan
      mattermost-desktop
      meld
      mesa-demos
      metasploit
      mimikatz
      minicom
      miredo
      mitmproxy
      mixxx
      msfpc
      mtools
      nbtscan
      neovim-remote
      netcat-gnu
      netdiscover
      netexec
      netmask
      netsniff-ng
      networkmanagerapplet
      nikto
      nilfs-utils
      ninja
      nix-bash-completions
      nix-diff
      nix-index
      nix-info
      nixos-icons
      nixpkgs-fmt
      nixpkgs-lint
      nixpkgs-review
      nmap
      ntfs3g
      obs-studio
      onedrive
      onesixtyone
      onionshare-gui
      openssl
      ophcrack
      ophcrack-cli
      p7zip
      patchelf
      pavucontrol
      pciutils
      pcmanfm
      pcre
      pdf-parser
      pdfid
      pgadmin4-desktopmode
      php84
      pixiewps
      pkg-config
      platformio
      platformio-core
      playerctl
      podman-compose
      podman-desktop
      powersploit
      proxychains
      ptunnel
      pwnat
      python313Full
      qbittorrent
      qemu-utils
      qpwgraph
      radare2
      rar
      readline
      reaverwps-t6x
      reiserfsprogs
      remmina
      responder
      ripgrep
      rpPPPoE
      rsmangler
      rtl-sdr-librtlsdr
      samdump2
      sane-backends
      scalpel
      schroedinger
      scrcpy
      screen
      sdrangel
      sdrpp
      sipvicious
      sleuthkit
      slurp
      smartmontools
      smbmap
      snmpcheck
      social-engineer-toolkit
      spice
      spice-gtk
      spice-protocol
      spooftooph
      sqlmap
      ssldump
      sslh
      sslscan
      sslsplit
      swaks
      tcpdump
      tcpreplay
      telegram-desktop
      texliveFull
      thc-hydra
      theharvester
      thermald
      tor-browser
      tree
      tree-sitter
      udftools
      udptunnel
      unar
      undollar
      ungoogled-chromium
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
      vscode-js-debug
      vulkan-tools
      wafw00f
      wapiti
      waybar-mpris
      waycheck
      wayland
      wayland-protocols
      wayland-utils
      waylevel
      weevely
      wev
      wget
      whatsie
      whatweb
      which
      whois
      wifite2
      win-spice
      wireshark
      wl-clipboard
      wordlists
      wordpress
      wpscan
      x264
      x265
      xarchiver
      xdg-user-dirs
      xdg-utils
      xfsdump
      xfsprogs
      xfstests
      xorg.xhost
      xoscope
      xvidcore
      yaml-language-server
      yt-dlp
      zip
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

          HeaderText = "Welcome";

          HourFormat = "\"hh:mm A\"";
          DateFormat = "\"MMMM dd, yyyy\"";

          PasswordFocus = true;
          AllowEmptyPassword = false;
        };
      })
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
          dracula-theme.theme-dracula
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
        ]
        ++
        pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "platformio-ide";
            publisher = "platformio";
            version = "3.3.4";
            sha256 = "qfNz4IYjCmCMFLtAkbGTW5xnsVT8iDnFWjrgkmr2Slk=";
          }
          {
            name = "vscode-serial-monitor";
            publisher = "ms-vscode";
            version = "0.13.250120001";
            sha256 = "sZ5ybbl1gxt41Eirp88JmS30WNHeM4SslhzBlLXyRsM=";
          }
          {
            name = "pubspec-assist";
            publisher = "jeroen-meijer";
            version = "2.3.2";
            sha256 = "+Mkcbeq7b+vkuf2/LYT10mj46sULixLNKGpCEk1Eu/0=";
          }
          {
            name = "vscode-sort-json";
            publisher = "richie5um2";
            version = "1.20.0";
            sha256 = "Jobx5Pf4SYQVR2I4207RSSP9I85qtVY6/2Nvs/Vvi/0=";
          }
        ];
      })
    ]
    ++
    (with unixtools; [
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
    ++
    (with fishPlugins; [
      async-prompt
      autopair
      done
      fish-you-should-use
    ])
    ++
    (with gst_all_1; [
      gst-libav
      gst-plugins-bad
      gst-plugins-base
      gst-plugins-good
      gst-plugins-ugly
      gst-vaapi
      gstreamer
    ])
    ++
    (with php84Extensions; [
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
      # mailparse
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
      xdebug
      xml
      xmlreader
      xmlwriter
      xsl
      zip
      zlib
    ])
    ++
    (with php84Packages; [

    ])
    ++
    (with python313Packages; [
      bangla
      black
      datetime
      matplotlib
      numpy
      pandas
      pillow
      pip
      pyserial
      requests
      seaborn
      tkinter
    ])
    ++
    (with texlivePackages; [
      bangla
      latexmk
      quran
      quran-bn
      quran-en
    ])
    ++
    (with lua51Packages; [
      # Old Version Pinned for Neovim
      lua
      luarocks
    ])
    ++
    (with tree-sitter-grammars; [
      tree-sitter-bash
      tree-sitter-c
      tree-sitter-cmake
      tree-sitter-comment
      tree-sitter-cpp
      tree-sitter-css
      tree-sitter-dart
      tree-sitter-devicetree
      tree-sitter-dockerfile
      tree-sitter-fish
      tree-sitter-html
      tree-sitter-http
      tree-sitter-hyprlang
      tree-sitter-javascript
      tree-sitter-jsdoc
      tree-sitter-json
      tree-sitter-json5
      tree-sitter-latex
      tree-sitter-lua
      tree-sitter-make
      tree-sitter-markdown
      tree-sitter-markdown-inline
      tree-sitter-nix
      tree-sitter-org-nvim
      tree-sitter-php
      tree-sitter-python
      tree-sitter-query
      tree-sitter-regex
      tree-sitter-scheme
      tree-sitter-sql
      tree-sitter-toml
      tree-sitter-vim
      tree-sitter-yaml
    ])
    ++
    (with inkscape-extensions; [
      applytransforms
      textext
    ])
    ++
    (with obs-studio-plugins; [
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
    ]);
  };

  xdg = {
    mime = {
      enable = true;

      addedAssociations = config.xdg.mime.defaultApplications;

      removedAssociations = { };

      # https://www.iana.org/assignments/media-types/media-types.xhtml # Excluding "application/x-*" and "x-scheme-handler/*"
      defaultApplications = {
        "inode/directory" = "pcmanfm.desktop";

        "text/1d-interleaved-parityfec" = "code.desktop";
        "text/RED" = "code.desktop";
        "text/SGML" = "code.desktop";
        "text/cache-manifest" = "code.desktop";
        "text/calendar" = "code.desktop";
        "text/cql" = "code.desktop";
        "text/cql-expression" = "code.desktop";
        "text/cql-identifier" = "code.desktop";
        "text/css" = "code.desktop";
        "text/csv" = "code.desktop";
        "text/csv-schema" = "code.desktop";
        "text/directory" = "code.desktop";
        "text/dns" = "code.desktop";
        "text/ecmascript" = "code.desktop";
        "text/encaprtp" = "code.desktop";
        "text/enriched" = "code.desktop";
        "text/fhirpath" = "code.desktop";
        "text/flexfec" = "code.desktop";
        "text/fwdred" = "code.desktop";
        "text/gff3" = "code.desktop";
        "text/grammar-ref-list" = "code.desktop";
        "text/hl7v2" = "code.desktop";
        "text/html" = "code.desktop";
        "text/javascript" = "code.desktop";
        "text/jcr-cnd" = "code.desktop";
        "text/markdown" = "code.desktop";
        "text/mizar" = "code.desktop";
        "text/n3" = "code.desktop";
        "text/parameters" = "code.desktop";
        "text/parityfec" = "code.desktop";
        "text/plain" = "code.desktop";
        "text/provenance-notation" = "code.desktop";
        "text/prs.fallenstein.rst" = "code.desktop";
        "text/prs.lines.tag" = "code.desktop";
        "text/prs.prop.logic" = "code.desktop";
        "text/prs.texi" = "code.desktop";
        "text/raptorfec" = "code.desktop";
        "text/rfc822-headers" = "code.desktop";
        "text/richtext" = "code.desktop";
        "text/rtf" = "code.desktop";
        "text/rtp-enc-aescm128" = "code.desktop";
        "text/rtploopback" = "code.desktop";
        "text/rtx" = "code.desktop";
        "text/shaclc" = "code.desktop";
        "text/shex" = "code.desktop";
        "text/spdx" = "code.desktop";
        "text/strings" = "code.desktop";
        "text/t140" = "code.desktop";
        "text/tab-separated-values" = "code.desktop";
        "text/troff" = "code.desktop";
        "text/turtle" = "code.desktop";
        "text/ulpfec" = "code.desktop";
        "text/uri-list" = "code.desktop";
        "text/vcard" = "code.desktop";
        "text/vnd.DMClientScript" = "code.desktop";
        "text/vnd.IPTC.NITF" = "code.desktop";
        "text/vnd.IPTC.NewsML" = "code.desktop";
        "text/vnd.a" = "code.desktop";
        "text/vnd.abc" = "code.desktop";
        "text/vnd.ascii-art" = "code.desktop";
        "text/vnd.curl" = "code.desktop";
        "text/vnd.debian.copyright" = "code.desktop";
        "text/vnd.dvb.subtitle" = "code.desktop";
        "text/vnd.esmertec.theme-descriptor" = "code.desktop";
        "text/vnd.exchangeable" = "code.desktop";
        "text/vnd.familysearch.gedcom" = "code.desktop";
        "text/vnd.ficlab.flt" = "code.desktop";
        "text/vnd.fly" = "code.desktop";
        "text/vnd.fmi.flexstor" = "code.desktop";
        "text/vnd.gml" = "code.desktop";
        "text/vnd.graphviz" = "code.desktop";
        "text/vnd.hans" = "code.desktop";
        "text/vnd.hgl" = "code.desktop";
        "text/vnd.in3d.3dml" = "code.desktop";
        "text/vnd.in3d.spot" = "code.desktop";
        "text/vnd.latex-z" = "code.desktop";
        "text/vnd.motorola.reflex" = "code.desktop";
        "text/vnd.ms-mediapackage" = "code.desktop";
        "text/vnd.net2phone.commcenter.command" = "code.desktop";
        "text/vnd.radisys.msml-basic-layout" = "code.desktop";
        "text/vnd.senx.warpscript" = "code.desktop";
        "text/vnd.si.uricatalogue" = "code.desktop";
        "text/vnd.sosi" = "code.desktop";
        "text/vnd.sun.j2me.app-descriptor" = "code.desktop";
        "text/vnd.trolltech.linguist" = "code.desktop";
        "text/vnd.vcf" = "code.desktop";
        "text/vnd.wap.si" = "code.desktop";
        "text/vnd.wap.sl" = "code.desktop";
        "text/vnd.wap.wml" = "code.desktop";
        "text/vnd.wap.wmlscript" = "code.desktop";
        "text/vnd.zoo.kcl" = "code.desktop";
        "text/vtt" = "code.desktop";
        "text/wgsl" = "code.desktop";
        "text/xml" = "code.desktop";
        "text/xml-external-parsed-entity" = "code.desktop";

        "image/aces" = "com.github.weclaw1.ImageRoll.desktop";
        "image/apng" = "com.github.weclaw1.ImageRoll.desktop";
        "image/avci" = "com.github.weclaw1.ImageRoll.desktop";
        "image/avcs" = "com.github.weclaw1.ImageRoll.desktop";
        "image/avif" = "com.github.weclaw1.ImageRoll.desktop";
        "image/bmp" = "com.github.weclaw1.ImageRoll.desktop";
        "image/cgm" = "com.github.weclaw1.ImageRoll.desktop";
        "image/dicom-rle" = "com.github.weclaw1.ImageRoll.desktop";
        "image/dpx" = "com.github.weclaw1.ImageRoll.desktop";
        "image/emf" = "com.github.weclaw1.ImageRoll.desktop";
        "image/fits" = "com.github.weclaw1.ImageRoll.desktop";
        "image/g3fax" = "com.github.weclaw1.ImageRoll.desktop";
        "image/gif" = "com.github.weclaw1.ImageRoll.desktop";
        "image/heic" = "com.github.weclaw1.ImageRoll.desktop";
        "image/heic-sequence" = "com.github.weclaw1.ImageRoll.desktop";
        "image/heif" = "com.github.weclaw1.ImageRoll.desktop";
        "image/heif-sequence" = "com.github.weclaw1.ImageRoll.desktop";
        "image/hej2k" = "com.github.weclaw1.ImageRoll.desktop";
        "image/hsj2" = "com.github.weclaw1.ImageRoll.desktop";
        "image/ief" = "com.github.weclaw1.ImageRoll.desktop";
        "image/j2c" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jaii" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jais" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jls" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jp2" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jpeg" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jph" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jphc" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jpm" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jpx" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jxl" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jxr" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jxrA" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jxrS" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jxs" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jxsc" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jxsi" = "com.github.weclaw1.ImageRoll.desktop";
        "image/jxss" = "com.github.weclaw1.ImageRoll.desktop";
        "image/ktx" = "com.github.weclaw1.ImageRoll.desktop";
        "image/ktx2" = "com.github.weclaw1.ImageRoll.desktop";
        "image/naplps" = "com.github.weclaw1.ImageRoll.desktop";
        "image/png" = "com.github.weclaw1.ImageRoll.desktop";
        "image/prs.btif" = "com.github.weclaw1.ImageRoll.desktop";
        "image/prs.pti" = "com.github.weclaw1.ImageRoll.desktop";
        "image/pwg-raster" = "com.github.weclaw1.ImageRoll.desktop";
        "image/svg+xml" = "com.github.weclaw1.ImageRoll.desktop";
        "image/t38" = "com.github.weclaw1.ImageRoll.desktop";
        "image/tiff" = "com.github.weclaw1.ImageRoll.desktop";
        "image/tiff-fx" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.adobe.photoshop" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.airzip.accelerator.azv" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.cns.inf2" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.dece.graphic" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.djvu" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.dvb.subtitle" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.dwg" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.dxf" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.fastbidsheet" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.fpx" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.fst" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.fujixerox.edmics-mmr" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.fujixerox.edmics-rlc" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.globalgraphics.pgb" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.microsoft.icon" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.mix" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.mozilla.apng" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.ms-modi" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.net-fpx" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.pco.b16" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.radiance" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.sealed.png" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.sealedmedia.softseal.gif" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.sealedmedia.softseal.jpg" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.svf" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.tencent.tap" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.valve.source.texture" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.wap.wbmp" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.xiff" = "com.github.weclaw1.ImageRoll.desktop";
        "image/vnd.zbrush.pcx" = "com.github.weclaw1.ImageRoll.desktop";
        "image/webp" = "com.github.weclaw1.ImageRoll.desktop";
        "image/wmf" = "com.github.weclaw1.ImageRoll.desktop";
        "image/x-emf" = "com.github.weclaw1.ImageRoll.desktop";
        "image/x-wmf" = "com.github.weclaw1.ImageRoll.desktop";

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

        "application/vnd.oasis.opendocument.text" = "writer.desktop"; # .odt
        "application/msword" = "writer.desktop"; # .doc
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop"; # .docx
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = "writer.desktop"; # .dotx

        "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop"; # .ods
        "application/vnd.ms-excel" = "calc.desktop"; # .xls
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop"; # .xlsx
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = "calc.desktop"; # .xltx

        "application/vnd.oasis.opendocument.presentation" = "impress.desktop"; # .odp
        "application/vnd.ms-powerpoint" = "impress.desktop"; # .ppt
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop"; # .pptx
        "application/vnd.openxmlformats-officedocument.presentationml.template" = "impress.desktop"; # .potx

        "application/pdf" = "firefox-devedition.desktop";

        "font/collection" = "org.gnome.font-viewer.desktop";
        "font/otf" = "org.gnome.font-viewer.desktop";
        "font/sfnt" = "org.gnome.font-viewer.desktop";
        "font/ttf" = "org.gnome.font-viewer.desktop";
        "font/woff" = "org.gnome.font-viewer.desktop";
        "font/woff2" = "org.gnome.font-viewer.desktop";

        "application/gzip" = "xarchiver.desktop";
        "application/vnd.rar" = "xarchiver.desktop";
        "application/x-7z-compressed" = "xarchiver.desktop";
        "application/x-arj" = "xarchiver.desktop";
        "application/x-bzip2" = "xarchiver.desktop";
        "application/x-gtar" = "xarchiver.desktop";
        "application/x-rar-compressed " = "xarchiver.desktop"; # More common than "application/vnd.rar"
        "application/x-tar" = "xarchiver.desktop";
        "application/zip" = "xarchiver.desktop";

        "x-scheme-handler/http" = "firefox-devedition.desktop";
        "x-scheme-handler/https" = "firefox-devedition.desktop";

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
      generateCaches = true;
      man-db.enable = true;
    };

    nixos = {
      enable = true;
      includeAllModules = true;
      options.warningsAreErrors = false;
    };
  };

  users = {
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

          stateVersion = "24.11";
        };

        wayland.windowManager.hyprland = {
          enable = true;

          systemd = {
            enable = false;
            enableXdgAutostart = true;

            # extraCommands = [

            # ];

            variables = [
              "--all"
            ];
          };

          plugins = [

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
              "sleep 2 && uwsm app -- keepassxc"

              "wl-paste --type text --watch cliphist store"
              "wl-paste --type image --watch cliphist store"

              "setfacl --modify user:jellyfin:--x ~ & adb start-server &"

              "systemctl --user start warp-taskbar"
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

              "SUPER SHIFT, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

              ", PRINT, exec, filename=\"$(xdg-user-dir DOWNLOAD)/Screenshot_$(date +'%Y-%B-%d_%I-%M-%S_%p').png\"; grim -g \"$(slurp -d)\" -t png -l 9 \"$filename\" && wl-copy < \"$filename\""

              "SUPER, A, exec, rofi -show drun -disable-history"
              "SUPER, R, exec, rofi -show run -disable-history"

              "SUPER, T, exec, kitty"
              "SUPER ALT, T, exec, kitty sh -c \"bash\""

              ", XF86Explorer, exec, pcmanfm"
              "SUPER, E, exec, pcmanfm"

              "SUPER, F, exec, kitty --hold sh -c \"fastfetch --thread true --detect-version true --logo-preserve-aspect-ratio true --temp-unit c --title-fqdn true --disk-show-regular true --disk-show-external true --disk-show-hidden true --disk-show-subvolumes true --disk-show-readonly true --disk-show-unknown true --physicaldisk-temp true --bluetooth-show-disconnected true --display-precise-refresh-rate true --cpu-temp true --cpu-show-pe-core-count true --cpuusage-separate true --gpu-temp true --gpu-driver-specific true --battery-temp true --localip-show-ipv4 true --localip-show-ipv6 true --localip-show-mac true --localip-show-loop true --localip-show-mtu true --localip-show-speed true --localip-show-prefix-len true --localip-show-all-ips true --localip-show-flags true --wm-detect-plugin true\""

              "SUPER, B, exec, kitty sh -c \"btop\""

              "SUPER, W, exec, firefox-devedition"
              "SUPER ALT, W, exec, firefox-devedition --private-window"

              ", XF86Mail, exec, thunderbird"
              "SUPER, M, exec, thunderbird"

              "SUPER, C, exec, code"
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

            windowrulev2 = [
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
              shadow .enabled = false;
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
            name = "Dracula";
            package = pkgs.dracula-icon-theme;
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

            settings = {
              ipc = "on";

              splash = false;

              preload =
                [
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
              plugins = with pkgs; [

              ];

              cycle = false;
              terminal = "${pkgs.kitty}/bin/kitty";

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

                  on-click = "pavucontrol";
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
                    firefox = "";
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

                  on-click = "kitty sh -c \"btop\"";
                };

                memory = {
                  interval = 1;

                  format = "{percentage}% ";

                  tooltip = true;
                  tooltip-format = "Used RAM: {used} GiB ({percentage}%)\nUsed Swap: {swapUsed} GiB ({swapPercentage}%)\nAvailable RAM: {avail} GiB\nAvailable Swap: {swapAvail} GiB";

                  on-click = "kitty sh -c \"btop\"";
                };

                cpu = {
                  interval = 1;

                  format = "{usage}% ";

                  tooltip = true;

                  on-click = "kitty sh -c \"btop\"";
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

                  on-click = "kitty sh -c \"btop\"";
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

          kitty = {
            enable = true;

            shellIntegration = {
              mode = "no-rc";
              enableBashIntegration = true;
            };

            font = {
              name = font_name.mono;
              package = pkgs.nerd-fonts.noto;
              size = 11;
            };

            keybindings = { };

            settings = {
              sync_to_monitor = "yes";

              window_padding_width = "0 4 0 4";
              confirm_os_window_close = 0;

              enable_audio_bell = "yes";
              detect_urls = "yes";
              scrollback_lines = -1;
              click_interval = -1;

              foreground = dracula_theme.hex.foreground;
              background = dracula_theme.hex.background;
              selection_foreground = "#ffffff";
              selection_background = dracula_theme.hex.current_line;
              url_color = dracula_theme.hex.cyan;
              title_fg = dracula_theme.hex.foreground;
              title_bg = dracula_theme.hex.background;
              margin_bg = dracula_theme.hex.comment;
              margin_fg = dracula_theme.hex.current_line;
              removed_bg = dracula_theme.hex.red;
              highlight_removed_bg = dracula_theme.hex.red;
              removed_margin_bg = dracula_theme.hex.red;
              added_bg = dracula_theme.hex.green;
              highlight_added_bg = dracula_theme.hex.green;
              added_margin_bg = dracula_theme.hex.green;
              filler_bg = dracula_theme.hex.current_line;
              hunk_margin_bg = dracula_theme.hex.current_line;
              hunk_bg = dracula_theme.hex.purple;
              search_bg = dracula_theme.hex.cyan;
              search_fg = dracula_theme.hex.background;
              select_bg = dracula_theme.hex.yellow;
              select_fg = dracula_theme.hex.background;

              # Splits / Windows
              active_border_color = dracula_theme.hex.foreground;
              inactive_border_color = dracula_theme.hex.comment;

              active_tab_foreground = dracula_theme.hex.background;
              active_tab_background = dracula_theme.hex.foreground;
              inactive_tab_foreground = dracula_theme.hex.background;
              inactive_tab_background = dracula_theme.hex.comment;

              mark1_foreground = dracula_theme.hex.background;
              mark1_background = dracula_theme.hex.red;

              cursor = dracula_theme.hex.foreground;
              cursor_text_color = dracula_theme.hex.background;

              # Black
              color0 = "#21222c";
              color8 = dracula_theme.hex.comment;

              # Red
              color1 = dracula_theme.hex.red;
              color9 = "#ff6e6e";

              # Green
              color2 = dracula_theme.hex.green;
              color10 = "#69ff94";

              # Yellow
              color3 = dracula_theme.hex.yellow;
              color11 = "#ffffa5";

              # Blue
              color4 = dracula_theme.hex.purple;
              color12 = "#d6acff";

              # Magenta
              color5 = dracula_theme.hex.pink;
              color13 = "#ff92df";

              # Cyan
              color6 = dracula_theme.hex.cyan;
              color14 = "#a4ffff";

              # White
              color7 = dracula_theme.hex.foreground;
              color15 = "#ffffff";
            };

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
# flutter doctor -v

# sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# sudo flatpak update
# sudo flatpak install flathub com.github.tchx84.Flatseal io.github.flattool.Warehouse io.github.giantpinkrobots.flatsweep
# sudo flatpak repair

# FIXME: Hyprpaper Delay
# FIXME: MariaDB > Login
# TODO: Asterisk
# TODO: Neovim
# TODO: PCManFM > Thumbnailers
# TODO: Tailscale
# TODO: Xarchiver > Backends
