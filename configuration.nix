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
      package = pkgs.gnome.gvfs;
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
      enableLmtp = true;
      enablePop3 = false;
      protocols = [
        "imap"
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
            "org/gnome/desktop/peripherals/pointingstick" = {
              scroll-method = "default";
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
            "org/gnome/desktop/session" = {
              idle-delay = pkgs.lib.gvariant.mkUint32 0; # 0 = Disabled
            };
            "org/gnome/desktop/privacy" = {
              disable-camera = false;
              old-files-age = pkgs.lib.gvariant.mkUint32 1; # 1 = 1 day
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
              # app-picker-layout = pkgs.lib.gvariant.mkEmptyArray (pkgs.lib.gvariant.type.string); # Alphabetical Sort
              always-show-log-out = true;
              disable-extension-version-validation = false;
              disable-user-extensions = false;
              enabled-extensions = [
                "Vitals@CoreCoding.com"
                "appindicatorsupport@rgcjonas.gmail.com"
                "blur-my-shell@aunetx"
                "desktop-cube@schneegans.github.com"
                "drive-menu@gnome-shell-extensions.gcampax.github.com"
                "gsconnect@andyholmes.github.io"
                "pano@elhan.io"
                "places-menu@gnome-shell-extensions.gcampax.github.com"
              ];
              favorite-apps = [
                "org.gnome.Console.desktop"
                "org.gnome.Nautilus.desktop"
                "firefox-devedition.desktop"
                "thunderbird.desktop"
                "org.fritzing.Fritzing.desktop"
                "code.desktop"
                "butt.desktop"
                "com.obsproject.Studio.desktop"
                "sdrangel.desktop"
                "sdrpp.desktop"
                "virt-manager.desktop"
              ];
              last-selected-power-profile = "performance";
            };
            "org/gnome/shell/app-switcher" = {
              current-workspace-only = false;
            };
            "org/gnome/shell/extensions/appindicator" = {
              legacy-tray-enabled = true;
            };
            "org/gnome/shell/extensions/gsconnect" = {
              keep-alive-when-locked = true;
              name = config.networking.hostName;
              show-indicators = true;
            };
            "org/gnome/shell/extensions/pano" = {
              item-date-font-family = font_preferences.name.sans_serif;
              item-title-font-family = font_preferences.name.sans_serif;
              keep-search-entry = false;
              link-previews = true;
              open-links-in-browser = true;
              paste-on-select = false;
              play-audio-on-copy = false;
              search-bar-font-family = font_preferences.name.sans_serif;
              send-notification-on-copy = false;
              session-only-mode = true;
              show-indicator = true;
              sync-primary = true;
              watch-exclusion-list = true;
              wiggle-indicator = true;
            };
            "org/gnome/shell/extensions/vitals" = {
              fixed-widths = false;
              hide-icons = false;
              hide-zeros = false;
              hot-sensors = [
                "_processor_usage_"
                "_memory_usage_"
                "__network-rx_max__"
                "__network-tx_max__"
              ];
              include-public-ip = true;
              include-static-gpu-info = true;
              include-static-info = true;
              menu-centered = true;
              show-battery = true;
              show-fan = true;
              show-gpu = true;
              show-memory = true;
              show-network = true;
              show-processor = true;
              show-storage = true;
              show-system = true;
              show-temperature = true;
              show-voltage = true;
              use-higher-precision = true;
            };
            "org/gnome/shell/extensions/desktop-cube" = {
              do-explode = true;
              enable-desktop-dragging = true;
              enable-desktop-edge-switch = true;
              enable-overview-dragging = true;
              enable-overview-edge-switch = true;
              enable-panel-dragging = true;
              last-first-gap = true;
            };
            "org/gnome/mutter" = {
              attach-modal-dialogs = false;
              center-new-windows = true;
              dynamic-workspaces = true;
              edge-tiling = true;
              workspaces-only-on-primary = false;
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

            "org/gnome/Console" = {
              audible-bell = true;
              ignore-scrollback-limit = true;
              theme = "night";
              use-system-font = true;
              visual-bell = true;
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

            "org/gnome/gnome-system-monitor" = {
              cpu-smooth-graph = true;
              kill-dialog = true;
              network-in-bits = false;
              network-total-in-bits = false;
              process-memory-in-iec = true;
              resources-memory-in-iec = true;
              show-all-fs = true;
              show-dependencies = true;
              show-whose-processes = "all";
              smooth-refresh = true;
              solaris-mode = true;
            };
            "org/gnome/gnome-system-monitor/proctree" = {
              col-0-visible = true;
              col-1-visible = true;
              col-2-visible = true;
              col-3-visible = true;
              col-4-visible = true;
              col-6-visible = true;
              col-7-visible = true;
              col-8-visible = true;
              col-9-visible = true;
              col-10-visible = true;
              col-11-visible = true;
              col-12-visible = true;
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
            "org/gnome/gnome-system-monitor/disksview" = {
              col-available-visible = true;
              col-device-visible = true;
              col-directory-visible = true;
              col-free-visible = true;
              col-total-visible = true;
              col-type-visible = true;
              col-used-visible = true;
            };

            "org/gnome/Snapshot" = {
              enable-audio-recording = true;
              play-shutter-sound = true;
              show-composition-guidelines = true;
            };

            "com/github/huluti/Curtail" = {
              file-attributes = true;
              metadata = false;
              new-file = true;
              recursive = true;
            };

            "org/gnome/simple-scan" = {
              postproc-keep-original = true;
            };

            "com/github/tenderowl/frog" = {
              telemetry = false;
            };

            "app/drey/EarTag" = {
              musicbrainz-cover-size = "Maximum size";
            };

            "org/gnome/Music" = {
              inhibit-suspend = true;
            };

            "org/gnome/Totem" = {
              # subtitle-encoding = "UTF-8";
              # subtitle-font = "${font_preferences.name.sans_serif} ${toString (font_preferences.size * 2)}";
              audio-output-type = "stereo";
              autoload-subtitles = true;
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

            "org/gnome/calculator" = {
              show-thousands = true;
              show-zeroes = true;
            };

            "io/gitlab/adhami3310/Converter" = {
              show-less-popular = true;
            };

            "org/gnome/maps" = {
              show-scale = true;
            };

            "org/gnome/GWeather4" = {
              temperature-unit = "centigrade";
            };

            "app/drey/Dialect" = {
              color-scheme = "dark";
              show-pronunciation = true;
              src-auto = true;
            };

            "org/gnome/Contacts" = {
              sort-on-surname = false;
            };

            "org/gnome/Calls" = {
              auto-use-default-origins = true;
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
        dconf2nix
        debase
        dialect
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
        gnome-maps
        gnome-multi-writer
        gnome-music
        gnome-nettool
        gnome-power-manager
        gnome-system-monitor
        gnome-tecla
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
        jellyfin-media-player
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
        mattermost-desktop
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
        transmission_4-gtk
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
        vitals
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

        "image/aces" = "org.gnome.Loupe.desktop";
        "image/apng" = "org.gnome.Loupe.desktop";
        "image/avci" = "org.gnome.Loupe.desktop";
        "image/avcs" = "org.gnome.Loupe.desktop";
        "image/avif" = "org.gnome.Loupe.desktop";
        "image/bmp" = "org.gnome.Loupe.desktop";
        "image/cgm" = "org.gnome.Loupe.desktop";
        "image/dicom-rle" = "org.gnome.Loupe.desktop";
        "image/dpx" = "org.gnome.Loupe.desktop";
        "image/emf" = "org.gnome.Loupe.desktop";
        "image/fits" = "org.gnome.Loupe.desktop";
        "image/g3fax" = "org.gnome.Loupe.desktop";
        "image/gif" = "org.gnome.Loupe.desktop";
        "image/heic" = "org.gnome.Loupe.desktop";
        "image/heic-sequence" = "org.gnome.Loupe.desktop";
        "image/heif" = "org.gnome.Loupe.desktop";
        "image/heif-sequence" = "org.gnome.Loupe.desktop";
        "image/hej2k" = "org.gnome.Loupe.desktop";
        "image/hsj2" = "org.gnome.Loupe.desktop";
        "image/ief" = "org.gnome.Loupe.desktop";
        "image/j2c" = "org.gnome.Loupe.desktop";
        "image/jaii" = "org.gnome.Loupe.desktop";
        "image/jais" = "org.gnome.Loupe.desktop";
        "image/jls" = "org.gnome.Loupe.desktop";
        "image/jp2" = "org.gnome.Loupe.desktop";
        "image/jpeg" = "org.gnome.Loupe.desktop";
        "image/jph" = "org.gnome.Loupe.desktop";
        "image/jphc" = "org.gnome.Loupe.desktop";
        "image/jpm" = "org.gnome.Loupe.desktop";
        "image/jpx" = "org.gnome.Loupe.desktop";
        "image/jxl" = "org.gnome.Loupe.desktop";
        "image/jxr" = "org.gnome.Loupe.desktop";
        "image/jxrA" = "org.gnome.Loupe.desktop";
        "image/jxrS" = "org.gnome.Loupe.desktop";
        "image/jxs" = "org.gnome.Loupe.desktop";
        "image/jxsc" = "org.gnome.Loupe.desktop";
        "image/jxsi" = "org.gnome.Loupe.desktop";
        "image/jxss" = "org.gnome.Loupe.desktop";
        "image/ktx" = "org.gnome.Loupe.desktop";
        "image/ktx2" = "org.gnome.Loupe.desktop";
        "image/naplps" = "org.gnome.Loupe.desktop";
        "image/png" = "org.gnome.Loupe.desktop";
        "image/prs.btif" = "org.gnome.Loupe.desktop";
        "image/prs.pti" = "org.gnome.Loupe.desktop";
        "image/pwg-raster" = "org.gnome.Loupe.desktop";
        "image/svg+xml" = "org.gnome.Loupe.desktop";
        "image/t38" = "org.gnome.Loupe.desktop";
        "image/tiff" = "org.gnome.Loupe.desktop";
        "image/tiff-fx" = "org.gnome.Loupe.desktop";
        "image/vnd.adobe.photoshop" = "org.gnome.Loupe.desktop";
        "image/vnd.airzip.accelerator.azv" = "org.gnome.Loupe.desktop";
        "image/vnd.cns.inf2" = "org.gnome.Loupe.desktop";
        "image/vnd.dece.graphic" = "org.gnome.Loupe.desktop";
        "image/vnd.djvu" = "org.gnome.Loupe.desktop";
        "image/vnd.dvb.subtitle" = "org.gnome.Loupe.desktop";
        "image/vnd.dwg" = "org.gnome.Loupe.desktop";
        "image/vnd.dxf" = "org.gnome.Loupe.desktop";
        "image/vnd.fastbidsheet" = "org.gnome.Loupe.desktop";
        "image/vnd.fpx" = "org.gnome.Loupe.desktop";
        "image/vnd.fst" = "org.gnome.Loupe.desktop";
        "image/vnd.fujixerox.edmics-mmr" = "org.gnome.Loupe.desktop";
        "image/vnd.fujixerox.edmics-rlc" = "org.gnome.Loupe.desktop";
        "image/vnd.globalgraphics.pgb" = "org.gnome.Loupe.desktop";
        "image/vnd.microsoft.icon" = "org.gnome.Loupe.desktop";
        "image/vnd.mix" = "org.gnome.Loupe.desktop";
        "image/vnd.mozilla.apng" = "org.gnome.Loupe.desktop";
        "image/vnd.ms-modi" = "org.gnome.Loupe.desktop";
        "image/vnd.net-fpx" = "org.gnome.Loupe.desktop";
        "image/vnd.pco.b16" = "org.gnome.Loupe.desktop";
        "image/vnd.radiance" = "org.gnome.Loupe.desktop";
        "image/vnd.sealed.png" = "org.gnome.Loupe.desktop";
        "image/vnd.sealedmedia.softseal.gif" = "org.gnome.Loupe.desktop";
        "image/vnd.sealedmedia.softseal.jpg" = "org.gnome.Loupe.desktop";
        "image/vnd.svf" = "org.gnome.Loupe.desktop";
        "image/vnd.tencent.tap" = "org.gnome.Loupe.desktop";
        "image/vnd.valve.source.texture" = "org.gnome.Loupe.desktop";
        "image/vnd.wap.wbmp" = "org.gnome.Loupe.desktop";
        "image/vnd.xiff" = "org.gnome.Loupe.desktop";
        "image/vnd.zbrush.pcx" = "org.gnome.Loupe.desktop";
        "image/webp" = "org.gnome.Loupe.desktop";
        "image/wmf" = "org.gnome.Loupe.desktop";
        "image/x-emf" = "org.gnome.Loupe.desktop";
        "image/x-wmf" = "org.gnome.Loupe.desktop";

        "audio/1d-interleaved-parityfec" = "org.gnome.Music.desktop";
        "audio/32kadpcm" = "org.gnome.Music.desktop";
        "audio/3gpp" = "org.gnome.Music.desktop";
        "audio/3gpp2" = "org.gnome.Music.desktop";
        "audio/AMR" = "org.gnome.Music.desktop";
        "audio/AMR-WB" = "org.gnome.Music.desktop";
        "audio/ATRAC-ADVANCED-LOSSLESS" = "org.gnome.Music.desktop";
        "audio/ATRAC-X" = "org.gnome.Music.desktop";
        "audio/ATRAC3" = "org.gnome.Music.desktop";
        "audio/BV16" = "org.gnome.Music.desktop";
        "audio/BV32" = "org.gnome.Music.desktop";
        "audio/CN" = "org.gnome.Music.desktop";
        "audio/DAT12" = "org.gnome.Music.desktop";
        "audio/DV" = "org.gnome.Music.desktop";
        "audio/DVI4" = "org.gnome.Music.desktop";
        "audio/EVRC" = "org.gnome.Music.desktop";
        "audio/EVRC-QCP" = "org.gnome.Music.desktop";
        "audio/EVRC0" = "org.gnome.Music.desktop";
        "audio/EVRC1" = "org.gnome.Music.desktop";
        "audio/EVRCB" = "org.gnome.Music.desktop";
        "audio/EVRCB0" = "org.gnome.Music.desktop";
        "audio/EVRCB1" = "org.gnome.Music.desktop";
        "audio/EVRCNW" = "org.gnome.Music.desktop";
        "audio/EVRCNW0" = "org.gnome.Music.desktop";
        "audio/EVRCNW1" = "org.gnome.Music.desktop";
        "audio/EVRCWB" = "org.gnome.Music.desktop";
        "audio/EVRCWB0" = "org.gnome.Music.desktop";
        "audio/EVRCWB1" = "org.gnome.Music.desktop";
        "audio/EVS" = "org.gnome.Music.desktop";
        "audio/G711-0" = "org.gnome.Music.desktop";
        "audio/G719" = "org.gnome.Music.desktop";
        "audio/G722" = "org.gnome.Music.desktop";
        "audio/G7221" = "org.gnome.Music.desktop";
        "audio/G723" = "org.gnome.Music.desktop";
        "audio/G726-16" = "org.gnome.Music.desktop";
        "audio/G726-24" = "org.gnome.Music.desktop";
        "audio/G726-32" = "org.gnome.Music.desktop";
        "audio/G726-40" = "org.gnome.Music.desktop";
        "audio/G728" = "org.gnome.Music.desktop";
        "audio/G729" = "org.gnome.Music.desktop";
        "audio/G7291" = "org.gnome.Music.desktop";
        "audio/G729D" = "org.gnome.Music.desktop";
        "audio/G729E" = "org.gnome.Music.desktop";
        "audio/GSM" = "org.gnome.Music.desktop";
        "audio/GSM-EFR" = "org.gnome.Music.desktop";
        "audio/GSM-HR-08" = "org.gnome.Music.desktop";
        "audio/L16" = "org.gnome.Music.desktop";
        "audio/L20" = "org.gnome.Music.desktop";
        "audio/L24" = "org.gnome.Music.desktop";
        "audio/L8" = "org.gnome.Music.desktop";
        "audio/LPC" = "org.gnome.Music.desktop";
        "audio/MELP" = "org.gnome.Music.desktop";
        "audio/MELP1200" = "org.gnome.Music.desktop";
        "audio/MELP2400" = "org.gnome.Music.desktop";
        "audio/MELP600" = "org.gnome.Music.desktop";
        "audio/MP4A-LATM" = "org.gnome.Music.desktop";
        "audio/MPA" = "org.gnome.Music.desktop";
        "audio/PCMA" = "org.gnome.Music.desktop";
        "audio/PCMA-WB" = "org.gnome.Music.desktop";
        "audio/PCMU" = "org.gnome.Music.desktop";
        "audio/PCMU-WB" = "org.gnome.Music.desktop";
        "audio/QCELP" = "org.gnome.Music.desktop";
        "audio/RED" = "org.gnome.Music.desktop";
        "audio/SMV" = "org.gnome.Music.desktop";
        "audio/SMV-QCP" = "org.gnome.Music.desktop";
        "audio/SMV0" = "org.gnome.Music.desktop";
        "audio/TETRA_ACELP" = "org.gnome.Music.desktop";
        "audio/TETRA_ACELP_BB" = "org.gnome.Music.desktop";
        "audio/TSVCIS" = "org.gnome.Music.desktop";
        "audio/UEMCLIP" = "org.gnome.Music.desktop";
        "audio/VDVI" = "org.gnome.Music.desktop";
        "audio/VMR-WB" = "org.gnome.Music.desktop";
        "audio/aac" = "org.gnome.Music.desktop";
        "audio/ac3" = "org.gnome.Music.desktop";
        "audio/amr-wb+" = "org.gnome.Music.desktop";
        "audio/aptx" = "org.gnome.Music.desktop";
        "audio/asc" = "org.gnome.Music.desktop";
        "audio/basic" = "org.gnome.Music.desktop";
        "audio/clearmode" = "org.gnome.Music.desktop";
        "audio/dls" = "org.gnome.Music.desktop";
        "audio/dsr-es201108" = "org.gnome.Music.desktop";
        "audio/dsr-es202050" = "org.gnome.Music.desktop";
        "audio/dsr-es202211" = "org.gnome.Music.desktop";
        "audio/dsr-es202212" = "org.gnome.Music.desktop";
        "audio/eac3" = "org.gnome.Music.desktop";
        "audio/encaprtp" = "org.gnome.Music.desktop";
        "audio/flac" = "org.gnome.Music.desktop";
        "audio/flexfec" = "org.gnome.Music.desktop";
        "audio/fwdred" = "org.gnome.Music.desktop";
        "audio/iLBC" = "org.gnome.Music.desktop";
        "audio/ip-mr_v2.5" = "org.gnome.Music.desktop";
        "audio/matroska" = "org.gnome.Music.desktop";
        "audio/mhas" = "org.gnome.Music.desktop";
        "audio/midi-clip" = "org.gnome.Music.desktop";
        "audio/mobile-xmf" = "org.gnome.Music.desktop";
        "audio/mp4" = "org.gnome.Music.desktop";
        "audio/mpa-robust" = "org.gnome.Music.desktop";
        "audio/mpeg" = "org.gnome.Music.desktop";
        "audio/mpeg4-generic" = "org.gnome.Music.desktop";
        "audio/ogg" = "org.gnome.Music.desktop";
        "audio/opus" = "org.gnome.Music.desktop";
        "audio/parityfec" = "org.gnome.Music.desktop";
        "audio/prs.sid" = "org.gnome.Music.desktop";
        "audio/raptorfec" = "org.gnome.Music.desktop";
        "audio/rtp-enc-aescm128" = "org.gnome.Music.desktop";
        "audio/rtp-midi" = "org.gnome.Music.desktop";
        "audio/rtploopback" = "org.gnome.Music.desktop";
        "audio/rtx" = "org.gnome.Music.desktop";
        "audio/scip" = "org.gnome.Music.desktop";
        "audio/sofa" = "org.gnome.Music.desktop";
        "audio/sp-midi" = "org.gnome.Music.desktop";
        "audio/speex" = "org.gnome.Music.desktop";
        "audio/t140c" = "org.gnome.Music.desktop";
        "audio/t38" = "org.gnome.Music.desktop";
        "audio/telephone-event" = "org.gnome.Music.desktop";
        "audio/tone" = "org.gnome.Music.desktop";
        "audio/ulpfec" = "org.gnome.Music.desktop";
        "audio/usac" = "org.gnome.Music.desktop";
        "audio/vnd.3gpp.iufp" = "org.gnome.Music.desktop";
        "audio/vnd.4SB" = "org.gnome.Music.desktop";
        "audio/vnd.CELP" = "org.gnome.Music.desktop";
        "audio/vnd.audiokoz" = "org.gnome.Music.desktop";
        "audio/vnd.cisco.nse" = "org.gnome.Music.desktop";
        "audio/vnd.cmles.radio-events" = "org.gnome.Music.desktop";
        "audio/vnd.cns.anp1" = "org.gnome.Music.desktop";
        "audio/vnd.cns.inf1" = "org.gnome.Music.desktop";
        "audio/vnd.dece.audio" = "org.gnome.Music.desktop";
        "audio/vnd.digital-winds" = "org.gnome.Music.desktop";
        "audio/vnd.dlna.adts" = "org.gnome.Music.desktop";
        "audio/vnd.dolby.heaac.1" = "org.gnome.Music.desktop";
        "audio/vnd.dolby.heaac.2" = "org.gnome.Music.desktop";
        "audio/vnd.dolby.mlp" = "org.gnome.Music.desktop";
        "audio/vnd.dolby.mps" = "org.gnome.Music.desktop";
        "audio/vnd.dolby.pl2" = "org.gnome.Music.desktop";
        "audio/vnd.dolby.pl2x" = "org.gnome.Music.desktop";
        "audio/vnd.dolby.pl2z" = "org.gnome.Music.desktop";
        "audio/vnd.dolby.pulse.1" = "org.gnome.Music.desktop";
        "audio/vnd.dra" = "org.gnome.Music.desktop";
        "audio/vnd.dts" = "org.gnome.Music.desktop";
        "audio/vnd.dts.hd" = "org.gnome.Music.desktop";
        "audio/vnd.dts.uhd" = "org.gnome.Music.desktop";
        "audio/vnd.dvb.file" = "org.gnome.Music.desktop";
        "audio/vnd.everad.plj" = "org.gnome.Music.desktop";
        "audio/vnd.hns.audio" = "org.gnome.Music.desktop";
        "audio/vnd.lucent.voice" = "org.gnome.Music.desktop";
        "audio/vnd.ms-playready.media.pya" = "org.gnome.Music.desktop";
        "audio/vnd.nokia.mobile-xmf" = "org.gnome.Music.desktop";
        "audio/vnd.nortel.vbk" = "org.gnome.Music.desktop";
        "audio/vnd.nuera.ecelp4800" = "org.gnome.Music.desktop";
        "audio/vnd.nuera.ecelp7470" = "org.gnome.Music.desktop";
        "audio/vnd.nuera.ecelp9600" = "org.gnome.Music.desktop";
        "audio/vnd.octel.sbc" = "org.gnome.Music.desktop";
        "audio/vnd.presonus.multitrack" = "org.gnome.Music.desktop";
        "audio/vnd.qcelp" = "org.gnome.Music.desktop";
        "audio/vnd.rhetorex.32kadpcm" = "org.gnome.Music.desktop";
        "audio/vnd.rip" = "org.gnome.Music.desktop";
        "audio/vnd.sealedmedia.softseal.mpeg" = "org.gnome.Music.desktop";
        "audio/vnd.vmx.cvsd" = "org.gnome.Music.desktop";
        "audio/vorbis" = "org.gnome.Music.desktop";
        "audio/vorbis-config" = "org.gnome.Music.desktop";

        "video/1d-interleaved-parityfec" = "org.gnome.Totem.desktop";
        "video/3gpp" = "org.gnome.Totem.desktop";
        "video/3gpp-tt" = "org.gnome.Totem.desktop";
        "video/3gpp2" = "org.gnome.Totem.desktop";
        "video/AV1" = "org.gnome.Totem.desktop";
        "video/BMPEG" = "org.gnome.Totem.desktop";
        "video/BT656" = "org.gnome.Totem.desktop";
        "video/CelB" = "org.gnome.Totem.desktop";
        "video/DV" = "org.gnome.Totem.desktop";
        "video/FFV1" = "org.gnome.Totem.desktop";
        "video/H261" = "org.gnome.Totem.desktop";
        "video/H263" = "org.gnome.Totem.desktop";
        "video/H263-1998" = "org.gnome.Totem.desktop";
        "video/H263-2000" = "org.gnome.Totem.desktop";
        "video/H264" = "org.gnome.Totem.desktop";
        "video/H264-RCDO" = "org.gnome.Totem.desktop";
        "video/H264-SVC" = "org.gnome.Totem.desktop";
        "video/H265" = "org.gnome.Totem.desktop";
        "video/H266" = "org.gnome.Totem.desktop";
        "video/JPEG" = "org.gnome.Totem.desktop";
        "video/MP1S" = "org.gnome.Totem.desktop";
        "video/MP2P" = "org.gnome.Totem.desktop";
        "video/MP2T" = "org.gnome.Totem.desktop";
        "video/MP4V-ES" = "org.gnome.Totem.desktop";
        "video/MPV" = "org.gnome.Totem.desktop";
        "video/SMPTE292M" = "org.gnome.Totem.desktop";
        "video/VP8" = "org.gnome.Totem.desktop";
        "video/VP9" = "org.gnome.Totem.desktop";
        "video/encaprtp" = "org.gnome.Totem.desktop";
        "video/evc" = "org.gnome.Totem.desktop";
        "video/flexfec" = "org.gnome.Totem.desktop";
        "video/iso.segment" = "org.gnome.Totem.desktop";
        "video/jpeg2000" = "org.gnome.Totem.desktop";
        "video/jxsv" = "org.gnome.Totem.desktop";
        "video/matroska" = "org.gnome.Totem.desktop";
        "video/matroska-3d" = "org.gnome.Totem.desktop";
        "video/mj2" = "org.gnome.Totem.desktop";
        "video/mp4" = "org.gnome.Totem.desktop";
        "video/mpeg" = "org.gnome.Totem.desktop";
        "video/mpeg4-generic" = "org.gnome.Totem.desktop";
        "video/nv" = "org.gnome.Totem.desktop";
        "video/ogg" = "org.gnome.Totem.desktop";
        "video/parityfec" = "org.gnome.Totem.desktop";
        "video/pointer" = "org.gnome.Totem.desktop";
        "video/quicktime" = "org.gnome.Totem.desktop";
        "video/raptorfec" = "org.gnome.Totem.desktop";
        "video/raw" = "org.gnome.Totem.desktop";
        "video/rtp-enc-aescm128" = "org.gnome.Totem.desktop";
        "video/rtploopback" = "org.gnome.Totem.desktop";
        "video/rtx" = "org.gnome.Totem.desktop";
        "video/scip" = "org.gnome.Totem.desktop";
        "video/smpte291" = "org.gnome.Totem.desktop";
        "video/ulpfec" = "org.gnome.Totem.desktop";
        "video/vc1" = "org.gnome.Totem.desktop";
        "video/vc2" = "org.gnome.Totem.desktop";
        "video/vnd.CCTV" = "org.gnome.Totem.desktop";
        "video/vnd.dece.hd" = "org.gnome.Totem.desktop";
        "video/vnd.dece.mobile" = "org.gnome.Totem.desktop";
        "video/vnd.dece.mp4" = "org.gnome.Totem.desktop";
        "video/vnd.dece.pd" = "org.gnome.Totem.desktop";
        "video/vnd.dece.sd" = "org.gnome.Totem.desktop";
        "video/vnd.dece.video" = "org.gnome.Totem.desktop";
        "video/vnd.directv.mpeg" = "org.gnome.Totem.desktop";
        "video/vnd.directv.mpeg-tts" = "org.gnome.Totem.desktop";
        "video/vnd.dlna.mpeg-tts" = "org.gnome.Totem.desktop";
        "video/vnd.dvb.file" = "org.gnome.Totem.desktop";
        "video/vnd.fvt" = "org.gnome.Totem.desktop";
        "video/vnd.hns.video" = "org.gnome.Totem.desktop";
        "video/vnd.iptvforum.1dparityfec-1010" = "org.gnome.Totem.desktop";
        "video/vnd.iptvforum.1dparityfec-2005" = "org.gnome.Totem.desktop";
        "video/vnd.iptvforum.2dparityfec-1010" = "org.gnome.Totem.desktop";
        "video/vnd.iptvforum.2dparityfec-2005" = "org.gnome.Totem.desktop";
        "video/vnd.iptvforum.ttsavc" = "org.gnome.Totem.desktop";
        "video/vnd.iptvforum.ttsmpeg2" = "org.gnome.Totem.desktop";
        "video/vnd.motorola.video" = "org.gnome.Totem.desktop";
        "video/vnd.motorola.videop" = "org.gnome.Totem.desktop";
        "video/vnd.mpegurl" = "org.gnome.Totem.desktop";
        "video/vnd.ms-playready.media.pyv" = "org.gnome.Totem.desktop";
        "video/vnd.nokia.interleaved-multimedia" = "org.gnome.Totem.desktop";
        "video/vnd.nokia.mp4vr" = "org.gnome.Totem.desktop";
        "video/vnd.nokia.videovoip" = "org.gnome.Totem.desktop";
        "video/vnd.objectvideo" = "org.gnome.Totem.desktop";
        "video/vnd.radgamettools.bink" = "org.gnome.Totem.desktop";
        "video/vnd.radgamettools.smacker" = "org.gnome.Totem.desktop";
        "video/vnd.sealed.mpeg1" = "org.gnome.Totem.desktop";
        "video/vnd.sealed.mpeg4" = "org.gnome.Totem.desktop";
        "video/vnd.sealed.swf" = "org.gnome.Totem.desktop";
        "video/vnd.sealedmedia.softseal.mov" = "org.gnome.Totem.desktop";
        "video/vnd.uvvu.mp4" = "org.gnome.Totem.desktop";
        "video/vnd.vivo" = "org.gnome.Totem.desktop";
        "video/vnd.youtube.yt" = "org.gnome.Totem.desktop";

        "application/pdf" = "firefox-devedition.desktop";

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

# gsettings reset org.gnome.shell app-picker-layout

# FIXME: 05ac-033e-Gamepad > Rumble
# FIXME: ELAN7001 SPI Fingerprint Sensor
# FIXME: MariaDB > Login
# FIXME: Qt
# FIXME: hardinfo2
