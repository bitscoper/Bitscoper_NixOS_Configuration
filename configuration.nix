# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
let
  android_nixpkgs =
    pkgs.callPackage
      (import (
        builtins.fetchGit {
          url = "https://github.com/tadfisher/android-nixpkgs.git";
        }
      ))
      {
        channel = "stable";
      };
  android_sdk = android_nixpkgs.sdk (
    sdkPkgs: with sdkPkgs; [
      build-tools-36-0-0
      cmdline-tools-latest
      emulator
      platform-tools
      platforms-android-36
      system-images-android-36-google-apis-playstore-x86-64
      tools
    ]
  );
  android_sdk_path = "${android_sdk}/share/android-sdk";

  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/refs/heads/master.tar.gz";

  font_preferences = {
    package = pkgs.nerd-fonts.noto;

    name = {
      mono = "NotoMono Nerd Font";
      sans_serif = "NotoSans Nerd Font";
      serif = "NotoSerif Nerd Font";
      emoji = "Noto Color Emoji";
    };

    size = 12;
  };

  cursor = {
    theme = {
      package = pkgs.gnome-themes-extra;
      name = "Adwaita";
    };

    size = 24;
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
      android_sdk.accept_license = true;
    };

    overlays = [

    ];
  };

  appstream.enable = true;

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [
      "C.UTF-8"
      "ar_SA.UTF-8"
      "bn_BD"
    ];

    extraLocaleSettings = {
      LC_ADDRESS = config.i18n.defaultLocale;
      LC_COLLATE = config.i18n.defaultLocale;
      LC_CTYPE = config.i18n.defaultLocale;
      LC_IDENTIFICATION = config.i18n.defaultLocale;
      LC_MEASUREMENT = config.i18n.defaultLocale;
      LC_MESSAGES = config.i18n.defaultLocale;
      LC_MONETARY = config.i18n.defaultLocale;
      LC_NAME = config.i18n.defaultLocale;
      LC_NUMERIC = config.i18n.defaultLocale;
      LC_PAPER = config.i18n.defaultLocale;
      LC_TELEPHONE = config.i18n.defaultLocale;
      LC_TIME = config.i18n.defaultLocale;
      LC_ALL = config.i18n.defaultLocale;
    };

    inputMethod = {
      enable = true;
      type = "ibus";
      ibus.engines = with pkgs.ibus-engines; [
        openbangla-keyboard
      ];
    };
  };

  networking = {
    enableIPv6 = true;

    domain = "bitscoper";
    hostName = "Bitscoper-WorkStation";
    fqdn = "${config.networking.hostName}.${config.networking.domain}";

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

    timeServers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
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

          # fprintAuth = true;

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

    timesyncd = {
      enable = true;

      servers = config.networking.timeServers;
      fallbackServers = config.networking.timeServers;

      extraConfig = '''';
    };

    fwupd = {
      enable = true;
      package = pkgs.fwupd;
    };

    btrfs.autoScrub = {
      enable = true;

      interval = "weekly";
      fileSystems = [
        "/"
      ];
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

      defaultSession = "gnome";

      autoLogin = {
        enable = false;
        user = null;
      };

      logToJournal = true;
      logToFile = true;
    };

    xserver = {
      enable = true;

      displayManager = {
        gdm = {
          enable = true;
          wayland = true;

          banner = config.networking.hostName;
          autoSuspend = false;

          settings = { };

          debug = false;
        };
      };

      desktopManager = {
        gnome = {
          enable = true;

          extraGSettingsOverridePackages = with pkgs; [

          ];
          extraGSettingsOverrides = '''';

          debug = false;
        };

        xterm.enable = false;
      };

      excludePackages = with pkgs; [
        xterm
      ];
    };

    gnome = {
      core-os-services.enable = true;
      core-shell.enable = true;
      core-utilities.enable = true;
      glib-networking.enable = true;
      gnome-browser-connector.enable = true;
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true;
      gnome-remote-desktop.enable = true;
      gnome-settings-daemon.enable = true;
      gnome-user-share.enable = true;
    };

    gvfs = {
      enable = true;
      package = pkgs.gvfs;
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

    memcached = {
      enable = true;
      listen = "0.0.0.0";
      port = 11211;
      enableUnixSocket = false;
      maxMemory = 64; # Megabytes
      maxConnections = 256;
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
        glib.out
        libGL
        llvmPackages.stdenv.cc.cc.lib
        stdenv.cc.cc.lib
      ];
    };

    java = {
      enable = true;
      package = pkgs.jdk23;

      binfmt = true;
    };

    appimage = {
      enable = true;
      package = pkgs.appimage-run;

      binfmt = true;
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

    nix-index = {
      package = pkgs.nix-index;

      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    gnupg = {
      package = pkgs.gnupg;

      agent = {
        enable = true;

        enableBrowserSocket = true;
        enableExtraSocket = true;
        enableSSHSupport = false;

        pinentryPackage = pkgs.pinentry-gnome3;
      };

      dirmngr.enable = true;
    };

    ssh = {
      package = pkgs.openssh;

      startAgent = true;
      agentTimeout = null;
    };

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

    usbtop.enable = true;

    adb.enable = true;

    nano = {
      enable = true;
      package = pkgs.nano;

      syntaxHighlight = true;

      nanorc = ''
        set linenumbers
        set softwrap
        set indicator
        set autoindent
      '';
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

    virt-manager = {
      enable = true;
      package = pkgs.virt-manager;
    };

    system-config-printer.enable = true;

    calls.enable = true;
    file-roller.enable = true;
    gnome-disks.enable = true;
    seahorse.enable = true;

    firefox = {
      enable = true;
      package = pkgs.firefox-devedition;
      languagePacks = [
        "ar"
        "bn"
        "en-US"
      ];

      nativeMessagingHosts = {
        packages = with pkgs; [
          gnomeExtensions.gsconnect
          keepassxc
        ];
      };

      policies = { };

      autoConfig = '''';

      preferences = {
        "security.warn_submit_secure_to_insecure" = true;

      };
      preferencesStatus = "locked";
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

    localsend = {
      enable = true;
      package = pkgs.localsend;

      openFirewall = true;
    };

    steam = {
      enable = true;
      package = pkgs.steam;

      extraCompatPackages = with pkgs; [

      ];

      localNetworkGameTransfers.openFirewall = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
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
            "system/proxy" = {
              mode = "auto";
            };

            "org/gnome/system/location" = {
              enabled = true;
            };
            "org/gnome/settings-daemon/plugins/power" = {
              idle-dim = false;
              power-button-action = "interactive";
              power-saver-profile-on-low-battery = false;
              sleep-inactive-ac-type = "nothing";
              sleep-inactive-battery-type = "nothing";
            };
            "org/gnome/settings-daemon/plugins/color" = {
              night-light-enabled = false;
            };
            "org/gnome/desktop/peripherals/keyboard" = {
              numlock-state = true;
              repeat = true;
            };
            "org/gnome/desktop/peripherals/pointingstick" = {
              scroll-method = "default";
            };
            "org/gnome/desktop/peripherals/mouse" = {
              accel-profile = "default";
              left-handed = false;
              natural-scroll = false;
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
            "org/gnome/desktop/media-handling" = {
              autorun-never = false;
            };
            "org/gnome/desktop/input-sources" = {
              per-window = false;
              show-all-sources = true;
              sources = [
                (pkgs.lib.gvariant.mkTuple [
                  "xkb"
                  "us"
                ])
                (pkgs.lib.gvariant.mkTuple [
                  "ibus"
                  "OpenBangla"
                ])
                (pkgs.lib.gvariant.mkTuple [
                  "xkb"
                  "bd"
                ])
                (pkgs.lib.gvariant.mkTuple [
                  "xkb"
                  "ara"
                ])
              ];
            };
            "org/gnome/desktop/sound" = {
              allow-volume-above-100-percent = true;
              event-sounds = true;
            };
            "org/gnome/desktop/datetime" = {
              automatic-timezone = false;
            };
            "org/gnome/desktop/privacy" = {
              disable-camera = false;
              remember-app-usage = false;
              remember-recent-files = false;
              remove-old-temp-files = true;
              remove-old-trash-files = true;
              report-technical-problems = false;
              send-software-usage-stats = false;
              usb-protection = true;
            };
            "org/gnome/desktop/screensaver" = {
              lock-enabled = false;
            };
            "org/gnome/desktop/notifications" = {
              show-in-lock-screen = true;
            };
            "org/gnome/desktop/interface" = {
              # overlay-scrolling = true;
              clock-format = "12h";
              clock-show-date = true;
              clock-show-weekday = true;
              color-scheme = "prefer-dark";
              cursor-blink = true;
              document-font-name = "${font_preferences.name.sans_serif} ${toString font_preferences.size}";
              enable-animations = true;
              enable-hot-corners = true;
              gtk-enable-primary-paste = true;
              gtk-key-theme = "Default";
              locate-pointer = true;
              monospace-font-name = "${font_preferences.name.mono} ${toString font_preferences.size}";
              show-battery-percentage = true;
            };
            "org/gnome/desktop/calendar" = {
              show-weekdate = true;
            };
            "org/gnome/desktop/search-providers" = {
              disable-external = false;
            };
            "org/gnome/desktop/file-sharing" = {
              require-password = "always";
            };
            "org/gnome/desktop/a11y" = {
              always-show-universal-access-status = false;
            };
            "org/gnome/desktop/a11y/keyboard" = {
              enable = false;
              bouncekeys-enable = false;
              mousekeys-enable = false;
              slowkeys-enable = false;
              stickykeys-enable = false;
              togglekeys-enable = true;
            };
            "org/gnome/desktop/a11y/mouse" = {
              secondary-click-enabled = false;
              dwell-click-enabled = false;
            };
            "org/gnome/desktop/a11y/interface" = {
              high-contrast = false;
              show-status-shapes = true;
            };
            "org/gnome/desktop/a11y/magnifier" = {
              invert-lightness = false;
            };
            "org/gnome/shell" = {
              disable-user-extensions = false;
              enabled-extensions = [
                "appindicatorsupport@rgcjonas.gmail.com"
                "blur-my-shell@aunetx"
                "desktop-cube@schneegans.github.com"
                "drive-menu@gnome-shell-extensions.gcampax.github.com"
                "gsconnect@andyholmes.github.io"
                "pano@elhan.io"
                "places-menu@gnome-shell-extensions.gcampax.github.com"
                "system-monitor@gnome-shell-extensions.gcampax.github.com"
              ];
              last-selected-power-profile = "performance";
            };
            "org/gnome/shell/app-switcher" = {
              current-workspace-only = false;
            };
            "org/gnome/mutter" = {
              attach-modal-dialogs = false;
              center-new-windows = true;
              dynamic-workspaces = true;
              edge-tiling = true;
              workspaces-only-on-primary = false;
            };
            "org/gnome/desktop/wm/preferences" = {
              action-double-click-titlebar = "toggle-maximize";
              action-middle-click-titlebar = "toggle-maximize-vertically";
              action-right-click-titlebar = "menu";
              auto-raise = true;
              button-layout = "appmenu:minimize,maximize,close";
              focus-mode = "mouse";
              mouse-button-modifier = "<Super>";
              resize-with-right-button = false;
              visual-bell = false;
            };

            "org/gtk/settings/file-chooser" = {
              clock-format = "12h";
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

            "org/gnome/file-roller/ui" = {
              view-sidebar = true;
            };
            "org/gnome/file-roller/listing" = {
              list-mode = "as-folder";
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
          font_preferences.name.mono
        ];

        sansSerif = [
          font_preferences.name.sans_serif
        ];

        serif = [
          font_preferences.name.serif
        ];

        emoji = [
          font_preferences.name.emoji
        ];
      };

      includeUserConf = true;
    };
  };

  environment = {
    enableAllTerminfo = true;

    wordlist = {
      enable = true;
      # lists = ;
    };

    homeBinInPath = true;
    localBinInPath = true;

    stub-ld.enable = true;

    variables = {
      ANDROID_SDK_ROOT = android_sdk_path;
      ANDROID_HOME = android_sdk_path;
    };

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
        # appimagekit
        # gnss-sdr
        # reiser4progs
        above
        acl
        aircrack-ng
        alac
        amass
        android-tools
        android_sdk # Custom
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
        binary
        binwalk
        bleachbit
        blender
        bluez-tools
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
        cloc
        cloudflare-warp
        cmake
        code-nautilus
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
        eartag
        efibootmgr
        esptool
        evtest
        evtest-qt
        exfatprogs
        eyedropper
        f2fs-tools
        faac
        faad2
        fdk_aac
        ffmpeg-full
        ffmpegthumbnailer
        file
        flutter
        fritzing
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
        gnome-autoar
        gnome-backgrounds
        gnome-bluetooth
        gnome-calculator
        gnome-calendar
        gnome-characters
        gnome-clocks
        gnome-color-manager
        gnome-connections
        gnome-console
        gnome-contacts
        gnome-control-center
        gnome-decoder
        gnome-epub-thumbnailer
        gnome-extensions-cli
        gnome-firmware
        gnome-font-viewer
        gnome-frog
        gnome-graphs
        gnome-logs
        gnome-multi-writer
        gnome-music
        gnome-nettool
        gnome-power-manager
        gnome-system-monitor
        gnome-tweaks
        gnome-user-docs
        gnome-video-effects
        gnome-weather
        gnugrep
        gnulib
        gnumake
        gnused
        gnutar
        gnutls
        gource
        gpredict
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
        letterpress
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
        libusb1
        libuuid
        libva-utils
        libvpx
        libwebcam
        libwebp
        libxfs
        libzip
        linuxConsoleTools
        lorem
        loupe
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
        monkeysAudio
        mtools
        nautilus
        netdiscover
        netsniff-ng
        ngrok
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
        ntp
        nuclei
        onionshare-gui
        onlyoffice-desktopeditors
        opencore-amr
        openh264
        openjpeg
        openssl
        p7zip
        paper-clip
        parabolic
        patchelf
        pciutils
        pcre
        php84
        pjsip
        pkg-config
        platformio
        platformio-core
        podman-compose
        podman-desktop
        python313Full
        qbittorrent
        qemu-utils
        qpwgraph
        radare2
        rar
        readline
        reiserfsprogs
        rpPPPoE
        rpi-imager
        rpmextract
        rtl-sdr-librtlsdr
        rzip
        sane-backends
        sbc
        scalpel
        schroedinger
        scrcpy
        screen
        sdrangel
        sdrpp
        serial-studio
        share-preview
        shared-mime-info
        sherlock
        simple-scan
        sipvicious
        sleuthkit
        smartmontools
        smbmap
        snapshot
        songrec
        spice
        spice-gtk
        spice-protocol
        spooftooph
        sslscan
        subfinder
        subtitleedit
        swaks
        switcheroo
        sysprof
        telegram-desktop
        texliveFull
        theharvester
        thermald
        time
        tor-browser
        totem
        tree
        trufflehog
        udftools
        unar
        unicode-emoji
        universal-android-debloater
        unix-privesc-check
        unrar
        unzip
        usbutils
        util-linux
        valuta
        virt-viewer
        virtio-win
        virtiofsd
        vulkan-tools
        wafw00f
        wavpack
        waycheck
        wayland
        wayland-protocols
        wayland-utils
        waylevel
        webfontkitgenerator
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
      ++ (with pkgs.gnome; [
        nixos-gsettings-overrides
      ])
      ++ (with gnomeExtensions; [
        appindicator
        blur-my-shell
        desktop-cube
        gsconnect
        pano
        places-status-indicator
        removable-drive-menu
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

    gnome.excludePackages = with pkgs; [
      epiphany
      evince
      geary
      gnome-maps
      gnome-text-editor
      gnome-tour
      yelp
    ];

    enableDebugInfo = false;
  };

  xdg = {
    mime = {
      enable = true;

      addedAssociations = config.xdg.mime.defaultApplications;

      removedAssociations = { };

      # https://www.iana.org/assignments/media-types/media-types.xhtml # Excluding "application/x-*" and "x-scheme-handler/*"
      defaultApplications = {
        "inode/directory" = "nautilus.desktop";

        "application/pdf" = "firefox-devedition.desktop";
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
        xdg-desktop-portal-gnome
      ];

      xdgOpenUsePortal = false; # Opening Programs
    };
  };

  # qt = {
  #   enable = true;

  #   platformTheme = "gnome";
  #   style = "adwaita-dark";
  # };

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

            gtk.enable = true;
          };

          preferXdgDirectories = true;

          packages = with pkgs; [

          ];

          sessionVariables = { };

          sessionSearchVariables = { };

          shellAliases = { };

          enableDebugInfo = false;

          stateVersion = "24.11";
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
            package = pkgs.gnome-themes-extra;
            name = "Adwaita-dark";
          };

          iconTheme = {
            package = pkgs.adwaita-icon-theme;
            name = "Adwaita";
          };

          cursorTheme = {
            name = cursor.theme.name;
            package = cursor.theme.package;
            size = cursor.size;
          };

          font = {
            name = font_preferences.name.sans_serif;
            package = font_preferences.package;
            size = font_preferences.size;
          };
        };

        qt = {
          enable = true;

          platformTheme.name = "adwaita";

          style = {
            package = pkgs.adwaita-qt6;
            name = "adwaita-qt";
          };
        };

        services = { };

        programs = {
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

          vscode = {
            enable = true;
            package = pkgs.vscode;
            mutableExtensionsDir = false;

            profiles = {
              default = {
                extensions =
                  with pkgs.vscode-extensions;
                  [
                    aaron-bond.better-comments
                    adpyke.codesnap
                    albymor.increment-selection
                    alefragnani.bookmarks
                    alexisvt.flutter-snippets
                    anweber.vscode-httpyac
                    bierner.comment-tagged-templates
                    bierner.docs-view
                    bierner.emojisense
                    bierner.github-markdown-preview
                    bierner.markdown-checkbox
                    bierner.markdown-emoji
                    bierner.markdown-footnotes
                    bierner.markdown-mermaid
                    bierner.markdown-preview-github-styles
                    bradgashler.htmltagwrap
                    chanhx.crabviz
                    christian-kohler.path-intellisense
                    codezombiech.gitignore
                    coolbear.systemd-unit-file
                    dart-code.dart-code
                    dart-code.flutter
                    davidanson.vscode-markdownlint
                    dendron.adjust-heading-level
                    devsense.phptools-vscode
                    dotenv.dotenv-vscode
                    ecmel.vscode-html-css
                    edonet.vscode-command-runner
                    esbenp.prettier-vscode
                    ethansk.restore-terminals
                    fabiospampinato.vscode-open-in-github
                    firefox-devtools.vscode-firefox-debug
                    formulahendry.auto-close-tag
                    formulahendry.auto-rename-tag
                    formulahendry.code-runner
                    foxundermoon.shell-format
                    github.copilot
                    github.copilot-chat
                    github.vscode-github-actions
                    github.vscode-pull-request-github
                    gitlab.gitlab-workflow
                    grapecity.gc-excelviewer
                    gruntfuggly.todo-tree
                    hars.cppsnippets
                    hbenl.vscode-test-explorer
                    hediet.vscode-drawio
                    ibm.output-colorizer
                    iciclesoft.workspacesort
                    iliazeus.vscode-ansi
                    illixion.vscode-vibrancy-continued
                    james-yu.latex-workshop
                    jbockle.jbockle-format-files
                    jellyedwards.gitsweep
                    jkillian.custom-local-formatters
                    jnoortheen.nix-ide
                    jock.svg
                    kamikillerto.vscode-colorize
                    llvm-vs-code-extensions.vscode-clangd
                    mads-hartmann.bash-ide-vscode
                    mechatroner.rainbow-csv
                    meganrogge.template-string-converter
                    mishkinf.goto-next-previous-member
                    mkhl.direnv
                    moshfeu.compare-folders
                    sanaajani.taskrunnercode
                    ms-azuretools.vscode-docker
                    ms-python.black-formatter
                    ms-python.debugpy
                    ms-python.isort
                    slevesque.vscode-multiclip
                    ms-python.python
                    ms-toolsai.datawrangler
                    ms-toolsai.jupyter
                    ms-toolsai.jupyter-keymap
                    ms-toolsai.jupyter-renderers
                    rioj7.commandonallfiles
                    ms-toolsai.vscode-jupyter-cell-tags
                    ms-toolsai.vscode-jupyter-slideshow
                    ms-vscode-remote.remote-containers
                    ms-vscode-remote.remote-ssh
                    stylelint.vscode-stylelint
                    ms-vscode-remote.remote-ssh-edit
                    ms-vscode.cmake-tools
                    ms-vscode.cpptools
                    ms-vscode.hexeditor
                    ms-vscode.live-server
                    ms-vscode.makefile-tools
                    ms-vscode.test-adapter-converter
                    ms-vsliveshare.vsliveshare
                    ms-windows-ai-studio.windows-ai-studio
                    oderwat.indent-rainbow
                    platformio.platformio-vscode-ide
                    quicktype.quicktype
                    redhat.vscode-xml
                    redhat.vscode-yaml
                    rubymaniac.vscode-paste-and-indent
                    ryu1kn.partial-diff
                    shardulm94.trailing-spaces
                    skyapps.fish-vscode
                    spywhere.guides
                    tailscale.vscode-tailscale
                    tamasfe.even-better-toml
                    timonwong.shellcheck
                    vscode-icons-team.vscode-icons
                    tyriar.sort-lines
                    usernamehw.errorlens
                    vincaslt.highlight-matching-tag
                    visualstudioexptteam.intellicode-api-usage-examples
                    visualstudioexptteam.vscodeintellicode
                    vscjava.vscode-gradle
                    wmaurer.change-case
                    zainchen.json
                  ]
                  ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
                    {
                      name = "vscode-serial-monitor";
                      publisher = "ms-vscode";
                      version = "0.13.250503001";
                      sha256 = "iuni/DybnUxdbvggvlCidurW4GevVPvwYO7/5i+S1ok=";
                    }
                    {
                      name = "unique-lines";
                      publisher = "bibhasdn";
                      version = "1.0.0";
                      sha256 = "W0ZpZ6+vjkfNfOtekx5NWOFTyxfWAiB0XYcIwHabFPQ=";
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
                    {
                      name = "vscode-print";
                      publisher = "pdconsec";
                      version = "1.4.0";
                      sha256 = "jAZ1F5neIFSevy0bNuHabh8pUbm5vuuxjmot08GctPc=";
                    }
                  ];

                enableUpdateCheck = true;
                enableExtensionUpdateCheck = true;

                # userSettings = {
                # };
              };
            };
          };

          matplotlib = {
            enable = true;

            config = { };

            extraConfig = '''';
          };

          gh = {
            enable = true;
            package = pkgs.gh;
            extensions = with pkgs; [

            ];

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
            nativeMessagingHosts = with pkgs; [

            ];

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

    users.root = { };
    users.bitscoper = { };

    verbose = true;
  };
}

# flutter doctor --android-licenses

# FIXME: 05ac-033e-Gamepad > Rumble
# FIXME: ELAN7001 SPI Fingerprint Sensor
# FIXME: MariaDB > Login
# FIXME: hardinfo2
# FIXME: rpi-imager
