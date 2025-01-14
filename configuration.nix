# By Abdullah As-Sadeed

{ config
, pkgs
, ...
}:
let
  android_nixpkgs = pkgs.callPackage
    (import (builtins.fetchGit {
      url = "https://github.com/tadfisher/android-nixpkgs.git";
    }))
    {
      channel = "stable";
    };
  android_sdk = android_nixpkgs.sdk (sdkPkgs: with sdkPkgs; [
    build-tools-35-0-0
    cmdline-tools-latest
    emulator
    extras-google-auto
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

    extraModulePackages = [

    ];

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

    userActivationScripts = {
      stdio = {
        text = ''
          rm -rf /home/bitscoper/.android/avd
          ln -s /home/bitscoper/.config/.android/avd /home/bitscoper/.android/avd
        '';
        deps = [

        ];
      };
    };

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

      cores = 0; # All
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
    rtkit.enable = true;

    polkit = {
      enable = true;
    };

    pam.services.hyprlock = {
      fprintAuth = true;
    };

    wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
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
      powerOnBoot = true;
    };

    rtl-sdr.enable = true;

    sane = {
      enable = true;
      openFirewall = true;
    };

    steam-hardware.enable = true;
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
    flatpak.enable = false;

    fwupd.enable = true;

    asusd = {
      enable = true;
      enableUserService = true;
    };

    acpid = {
      enable = true;

      powerEventCommands = '' '';
      acEventCommands = '' '';
      lidEventCommands = '' '';

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

    dbus.enable = true;

    fprintd = {
      enable = true;
      # tod = {
      #   enable = true;
      #   driver = pkgs.libfprint-2-tod1-elan;
      # };
    };

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
          command = "tuigreet --time --user-menu --greet-align center --asterisks --asterisks-char \"*\" --cmd \"uwsm start -S -F /run/current-system/sw/bin/Hyprland\"";
          user = "greeter";
        };
      };
    };

    udev = {
      enable = true;
      packages = with pkgs; [
        android-udev-rules
        game-devices-udev-rules
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

    udisks2 = {
      enable = true;

      settings = { };
    };

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

      extraConfig = '' '';
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

    logrotate = {
      enable = true;
      checkConfig = true;
      allowNetworking = true;
    };
  };

  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [

      ];
    };

    java = {
      enable = true;
      package = pkgs.jdk23;
      binfmt = true;
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

    xwayland.enable = true;

    appimage.enable = true;

    nix-index.enableBashIntegration = true;

    bash = {
      completion.enable = true;
      enableLsColors = true;

      shellAliases = {
        clean_build = "sudo nix-channel --update && sudo nix-env -u --always && sudo rm -rf /nix/var/nix/gcroots/auto/* && sudo nix-collect-garbage -d && nix-collect-garbage -d && sudo nix-store --gc && sudo nixos-rebuild switch --upgrade-all";
      };

      loginShellInit = '' '';

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

        pinentryPackage = (pkgs.pinentry-rofi.override {
          rofi = pkgs.rofi-wayland;
        });
      };

      dirmngr.enable = true;
    };

    adb.enable = true;

    nm-applet = {
      enable = true;
      indicator = true;
    };

    virt-manager.enable = true;

    system-config-printer.enable = true;

    nano = {
      enable = true;
      nanorc = '' '';
    };

    firefox = {
      enable = true;
      languagePacks = [
        "en-US"
      ];
    };

    thunderbird.enable = true;

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
    variables = pkgs.lib.mkForce {
      ANDROID_SDK_ROOT = android_sdk_path;
      ANDROID_HOME = android_sdk_path;

      # LD_LIBRARY_PATH = "${pkgs.glib.out}/lib/:${pkgs.libGL}/lib/:${pkgs.stdenv.cc.cc.lib}/lib:${existing_library_paths}";
    };

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      CHROME_EXECUTABLE = "chromium";
    };

    systemPackages = with pkgs; [
      acl
      agi
      aircrack-ng
      android-backup-extractor
      android-tools
      android_sdk # Custom
      anydesk
      aribb24
      aribb25
      audacity
      avrdude
      bat
      bleachbit
      blender
      bluez
      bluez-tools
      bridge-utils
      brightnessctl
      btop
      btrfs-progs
      burpsuite
      butt
      certbot-full
      clang
      clinfo
      cliphist
      cloudflare-warp
      cmake
      coreutils-full
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
      dconf-editor
      dmg2img
      esptool
      exfatprogs
      faac
      faad2
      fastfetch
      fd
      fdk_aac
      ffmpeg-full
      file
      flutter327
      fritzing
      fwupd-efi
      gcc
      gdb
      gimp-with-plugins
      git
      git-doc
      glib
      glibc
      gnome-font-viewer
      gnugrep
      gnumake
      gource
      gpredict
      gradle
      gradle-completion
      greetd.tuigreet
      grim
      guestfs-tools
      gzip
      hw-probe
      hyprcursor
      hyprls
      hyprpicker
      hyprpolkitagent
      i2c-tools
      iftop
      inotify-tools
      jellyfin-media-player
      john
      johnny
      jq
      keepassxc
      kind
      kubectl
      kubectl-graph
      kubectl-tree
      kubectl-view-allocations
      kubectl-view-secret
      kubernetes
      libGL
      libaom
      libappimage
      libde265
      libdvdcss
      libdvdnav
      libdvdread
      libfprint
      libfprint-tod
      libgcc
      libgpg-error
      libguestfs
      libheif
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
      lsof
      lynis
      mattermost-desktop
      memcached
      metasploit
      mixxx
      nano
      networkmanagerapplet
      ninja
      nix-bash-completions
      nix-diff
      nix-index
      nix-info
      nixos-icons
      nixpkgs-fmt
      nmap
      obs-studio
      oculante
      onedrive
      onionshare-gui
      openssl
      patchelf
      pavucontrol
      pciutils
      pcre
      pgadmin4-desktopmode
      php84
      pipewire
      pkg-config
      platformio
      platformio-core
      playerctl
      podman-compose
      podman-desktop
      podman-tui
      python313Full
      qbittorrent
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
      slurp
      smartmontools
      social-engineer-toolkit
      spice-gtk
      spice-protocol
      superfile
      swtpm
      telegram-desktop
      texliveFull
      thermald
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
      waycheck
      waydroid
      wayland
      wayland-protocols
      wayland-utils
      waylevel
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
      yaml
      zip
      zlib
    ]) ++
    (with php84Packages; [

    ]) ++
    (with python313Packages; [
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
    # (with androidenv.androidPkgs; [
    #   build-tools
    #   emulator
    #   platform-tools
    #   tools
    # ]) ++
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
  };

  xdg = {
    mime = {
      enable = true;

      addedAssociations = config.xdg.mime.defaultApplications;

      removedAssociations = { };

      defaultApplications = {
        "text/1d-interleaved-parityfec" = "code.desktop";
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
        "text/example" = "code.desktop";
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
        "text/RED" = "code.desktop";
        "text/rfc822-headers" = "code.desktop";
        "text/richtext" = "code.desktop";
        "text/rtf" = "code.desktop";
        "text/rtp-enc-aescm128" = "code.desktop";
        "text/rtploopback" = "code.desktop";
        "text/rtx" = "code.desktop";
        "text/SGML" = "code.desktop";
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
        "text/vnd.a" = "code.desktop";
        "text/vnd.abc" = "code.desktop";
        "text/vnd.ascii-art" = "code.desktop";
        "text/vnd.curl" = "code.desktop";
        "text/vnd.debian.copyright" = "code.desktop";
        "text/vnd.DMClientScript" = "code.desktop";
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
        "text/vnd.IPTC.NewsML" = "code.desktop";
        "text/vnd.IPTC.NITF" = "code.desktop";
        "text/vnd.latex-z" = "code.desktop";
        "text/vnd.motorola.reflex" = "code.desktop";
        "text/vnd.ms-mediapackage" = "code.desktop";
        "text/vnd.net2phone.commcenter.command" = "code.desktop";
        "text/vnd.radisys.msml-basic-layout" = "code.desktop";
        "text/vnd.senx.warpscript" = "code.desktop";
        "text/vnd.si.uricatalogue" = "code.desktop";
        "text/vnd.sun.j2me.app-descriptor" = "code.desktop";
        "text/vnd.sosi" = "code.desktop";
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

        "image/aces" = "oculante.desktop";
        "image/apng" = "oculante.desktop";
        "image/avci" = "oculante.desktop";
        "image/avcs" = "oculante.desktop";
        "image/avif" = "oculante.desktop";
        "image/bmp" = "oculante.desktop";
        "image/cgm" = "oculante.desktop";
        "image/dicom-rle" = "oculante.desktop";
        "image/dpx" = "oculante.desktop";
        "image/emf" = "oculante.desktop";
        "image/example" = "oculante.desktop";
        "image/fits" = "oculante.desktop";
        "image/g3fax" = "oculante.desktop";
        "image/gif" = "oculante.desktop";
        "image/heic" = "oculante.desktop";
        "image/heic-sequence" = "oculante.desktop";
        "image/heif" = "oculante.desktop";
        "image/heif-sequence" = "oculante.desktop";
        "image/hej2k" = "oculante.desktop";
        "image/hsj2" = "oculante.desktop";
        "image/ief" = "oculante.desktop";
        "image/j2c" = "oculante.desktop";
        "image/jaii" = "oculante.desktop";
        "image/jais" = "oculante.desktop";
        "image/jls" = "oculante.desktop";
        "image/jp2" = "oculante.desktop";
        "image/jpeg" = "oculante.desktop";
        "image/jph" = "oculante.desktop";
        "image/jphc" = "oculante.desktop";
        "image/jpm" = "oculante.desktop";
        "image/jpx" = "oculante.desktop";
        "image/jxl" = "oculante.desktop";
        "image/jxr" = "oculante.desktop";
        "image/jxrA" = "oculante.desktop";
        "image/jxrS" = "oculante.desktop";
        "image/jxs" = "oculante.desktop";
        "image/jxsc" = "oculante.desktop";
        "image/jxsi" = "oculante.desktop";
        "image/jxss" = "oculante.desktop";
        "image/ktx" = "oculante.desktop";
        "image/ktx2" = "oculante.desktop";
        "image/naplps" = "oculante.desktop";
        "image/png" = "oculante.desktop";
        "image/prs.btif" = "oculante.desktop";
        "image/prs.pti" = "oculante.desktop";
        "image/pwg-raster" = "oculante.desktop";
        "image/svg+xml" = "oculante.desktop";
        "image/t38" = "oculante.desktop";
        "image/tiff" = "oculante.desktop";
        "image/tiff-fx" = "oculante.desktop";
        "image/vnd.adobe.photoshop" = "oculante.desktop";
        "image/vnd.airzip.accelerator.azv" = "oculante.desktop";
        "image/vnd.cns.inf2" = "oculante.desktop";
        "image/vnd.dece.graphic" = "oculante.desktop";
        "image/vnd.djvu" = "oculante.desktop";
        "image/vnd.dwg" = "oculante.desktop";
        "image/vnd.dxf" = "oculante.desktop";
        "image/vnd.dvb.subtitle" = "oculante.desktop";
        "image/vnd.fastbidsheet" = "oculante.desktop";
        "image/vnd.fpx" = "oculante.desktop";
        "image/vnd.fst" = "oculante.desktop";
        "image/vnd.fujixerox.edmics-mmr" = "oculante.desktop";
        "image/vnd.fujixerox.edmics-rlc" = "oculante.desktop";
        "image/vnd.globalgraphics.pgb" = "oculante.desktop";
        "image/vnd.microsoft.icon" = "oculante.desktop";
        "image/vnd.mix" = "oculante.desktop";
        "image/vnd.ms-modi" = "oculante.desktop";
        "image/vnd.mozilla.apng" = "oculante.desktop";
        "image/vnd.net-fpx" = "oculante.desktop";
        "image/vnd.pco.b16" = "oculante.desktop";
        "image/vnd.radiance" = "oculante.desktop";
        "image/vnd.sealed.png" = "oculante.desktop";
        "image/vnd.sealedmedia.softseal.gif" = "oculante.desktop";
        "image/vnd.sealedmedia.softseal.jpg" = "oculante.desktop";
        "image/vnd.svf" = "oculante.desktop";
        "image/vnd.tencent.tap" = "oculante.desktop";
        "image/vnd.valve.source.texture" = "oculante.desktop";
        "image/vnd.wap.wbmp" = "oculante.desktop";
        "image/vnd.xiff" = "oculante.desktop";
        "image/vnd.zbrush.pcx" = "oculante.desktop";
        "image/webp" = "oculante.desktop";
        "image/wmf" = "oculante.desktop";
        "image/x-emf" = "oculante.desktop";
        "image/x-wmf" = "oculante.desktop";

        "audio/1d-interleaved-parityfec" = "vlc.desktop";
        "audio/32kadpcm" = "vlc.desktop";
        "audio/3gpp" = "vlc.desktop";
        "audio/3gpp2" = "vlc.desktop";
        "audio/aac" = "vlc.desktop";
        "audio/ac3" = "vlc.desktop";
        "audio/AMR" = "vlc.desktop";
        "audio/AMR-WB" = "vlc.desktop";
        "audio/amr-wb+" = "vlc.desktop";
        "audio/aptx" = "vlc.desktop";
        "audio/asc" = "vlc.desktop";
        "audio/ATRAC-ADVANCED-LOSSLESS" = "vlc.desktop";
        "audio/ATRAC-X" = "vlc.desktop";
        "audio/ATRAC3" = "vlc.desktop";
        "audio/basic" = "vlc.desktop";
        "audio/BV16" = "vlc.desktop";
        "audio/BV32" = "vlc.desktop";
        "audio/clearmode" = "vlc.desktop";
        "audio/CN" = "vlc.desktop";
        "audio/DAT12" = "vlc.desktop";
        "audio/dls" = "vlc.desktop";
        "audio/dsr-es201108" = "vlc.desktop";
        "audio/dsr-es202050" = "vlc.desktop";
        "audio/dsr-es202211" = "vlc.desktop";
        "audio/dsr-es202212" = "vlc.desktop";
        "audio/DV" = "vlc.desktop";
        "audio/DVI4" = "vlc.desktop";
        "audio/eac3" = "vlc.desktop";
        "audio/encaprtp" = "vlc.desktop";
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
        "audio/example" = "vlc.desktop";
        "audio/flac" = "vlc.desktop";
        "audio/flexfec" = "vlc.desktop";
        "audio/fwdred" = "vlc.desktop";
        "audio/G711-0" = "vlc.desktop";
        "audio/G719" = "vlc.desktop";
        "audio/G7221" = "vlc.desktop";
        "audio/G722" = "vlc.desktop";
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
        "audio/iLBC" = "vlc.desktop";
        "audio/ip-mr_v2.5" = "vlc.desktop";
        "audio/L8" = "vlc.desktop";
        "audio/L16" = "vlc.desktop";
        "audio/L20" = "vlc.desktop";
        "audio/L24" = "vlc.desktop";
        "audio/LPC" = "vlc.desktop";
        "audio/matroska" = "vlc.desktop";
        "audio/MELP" = "vlc.desktop";
        "audio/MELP600" = "vlc.desktop";
        "audio/MELP1200" = "vlc.desktop";
        "audio/MELP2400" = "vlc.desktop";
        "audio/mhas" = "vlc.desktop";
        "audio/midi-clip" = "vlc.desktop";
        "audio/mobile-xmf" = "vlc.desktop";
        "audio/MPA" = "vlc.desktop";
        "audio/mp4" = "vlc.desktop";
        "audio/MP4A-LATM" = "vlc.desktop";
        "audio/mpa-robust" = "vlc.desktop";
        "audio/mpeg" = "vlc.desktop";
        "audio/mpeg4-generic" = "vlc.desktop";
        "audio/ogg" = "vlc.desktop";
        "audio/opus" = "vlc.desktop";
        "audio/parityfec" = "vlc.desktop";
        "audio/PCMA" = "vlc.desktop";
        "audio/PCMA-WB" = "vlc.desktop";
        "audio/PCMU" = "vlc.desktop";
        "audio/PCMU-WB" = "vlc.desktop";
        "audio/prs.sid" = "vlc.desktop";
        "audio/QCELP" = "vlc.desktop";
        "audio/raptorfec" = "vlc.desktop";
        "audio/RED" = "vlc.desktop";
        "audio/rtp-enc-aescm128" = "vlc.desktop";
        "audio/rtploopback" = "vlc.desktop";
        "audio/rtp-midi" = "vlc.desktop";
        "audio/rtx" = "vlc.desktop";
        "audio/scip" = "vlc.desktop";
        "audio/SMV" = "vlc.desktop";
        "audio/SMV0" = "vlc.desktop";
        "audio/SMV-QCP" = "vlc.desktop";
        "audio/sofa" = "vlc.desktop";
        "audio/sp-midi" = "vlc.desktop";
        "audio/speex" = "vlc.desktop";
        "audio/t140c" = "vlc.desktop";
        "audio/t38" = "vlc.desktop";
        "audio/telephone-event" = "vlc.desktop";
        "audio/TETRA_ACELP" = "vlc.desktop";
        "audio/TETRA_ACELP_BB" = "vlc.desktop";
        "audio/tone" = "vlc.desktop";
        "audio/TSVCIS" = "vlc.desktop";
        "audio/UEMCLIP" = "vlc.desktop";
        "audio/ulpfec" = "vlc.desktop";
        "audio/usac" = "vlc.desktop";
        "audio/VDVI" = "vlc.desktop";
        "audio/VMR-WB" = "vlc.desktop";
        "audio/vnd.3gpp.iufp" = "vlc.desktop";
        "audio/vnd.4SB" = "vlc.desktop";
        "audio/vnd.audiokoz" = "vlc.desktop";
        "audio/vnd.CELP" = "vlc.desktop";
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
        "video/3gpp2" = "vlc.desktop";
        "video/3gpp-tt" = "vlc.desktop";
        "video/AV1" = "vlc.desktop";
        "video/BMPEG" = "vlc.desktop";
        "video/BT656" = "vlc.desktop";
        "video/CelB" = "vlc.desktop";
        "video/DV" = "vlc.desktop";
        "video/encaprtp" = "vlc.desktop";
        "video/evc" = "vlc.desktop";
        "video/example" = "vlc.desktop";
        "video/FFV1" = "vlc.desktop";
        "video/flexfec" = "vlc.desktop";
        "video/H261" = "vlc.desktop";
        "video/H263" = "vlc.desktop";
        "video/H263-1998" = "vlc.desktop";
        "video/H263-2000" = "vlc.desktop";
        "video/H264" = "vlc.desktop";
        "video/H264-RCDO" = "vlc.desktop";
        "video/H264-SVC" = "vlc.desktop";
        "video/H265" = "vlc.desktop";
        "video/H266" = "vlc.desktop";
        "video/iso.segment" = "vlc.desktop";
        "video/JPEG" = "vlc.desktop";
        "video/jpeg2000" = "vlc.desktop";
        "video/jxsv" = "vlc.desktop";
        "video/matroska" = "vlc.desktop";
        "video/matroska-3d" = "vlc.desktop";
        "video/mj2" = "vlc.desktop";
        "video/MP1S" = "vlc.desktop";
        "video/MP2P" = "vlc.desktop";
        "video/MP2T" = "vlc.desktop";
        "video/mp4" = "vlc.desktop";
        "video/MP4V-ES" = "vlc.desktop";
        "video/MPV" = "vlc.desktop";
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
        "video/SMPTE292M" = "vlc.desktop";
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
        "video/vnd.youtube.yt" = "vlc.desktop";
        "video/vnd.vivo" = "vlc.desktop";
        "video/VP8" = "vlc.desktop";
        "video/VP9" = "vlc.desktop";

        "application/pdf" = "firefox.desktop";

        "font/collection" = "org.gnome.font-viewer.desktop";
        "font/otf" = "org.gnome.font-viewer.desktop";
        "font/sfnt" = "org.gnome.font-viewer.desktop";
        "font/ttf" = "org.gnome.font-viewer.desktop";
        "font/woff" = "org.gnome.font-viewer.desktop";
        "font/woff2" = "org.gnome.font-viewer.desktop";
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

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    backupFileExtension = "old";

    users.bitscoper = {
      home = {
        pointerCursor = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 24;

          hyprcursor = {
            enable = true;
            size = config.home-manager.users.bitscoper.home.pointerCursor.size;
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

          # variables = [

          # ];
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
            "XCURSOR_SIZE, 24"
          ];

          exec-once = [
            "systemctl --user start hyprpolkitagent & setfacl --modify user:jellyfin:--x ~ & adb start-server &"
            "sleep 2 && uwsm app -- keepassxc"
            "uwsm app -- wl-paste --type text --watch cliphist store"
            "uwsm app -- wl-paste --type image --watch cliphist store"
            # "uwsm app -- nm-applet"
            "sleep 2 && systemctl --user start warp-taskbar"
            "uwsm app -- sdkmanager --licenses"
          ];

          bind = [
            "SUPER, L, exec, uwsm app -- hyprlock --immediate"
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

            "SUPER SHIFT, F, togglefloating,"
            "SUPER SHIFT, T, togglesplit,"
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

            "SUPER, R, exec, uwsm app -- kitty"
            "SUPER, T, exec, uwsm app -- kitty"

            ", XF86Explorer, exec, uwsm app -- kitty sh -c \"superfile\""
            "SUPER, E, exec, uwsm app -- kitty sh -c \"superfile\""

            "SUPER, F, exec, uwsm app -- kitty --hold sh -c \"fastfetch --thread true --detect-version true --logo-preserve-aspect-ratio true --temp-unit c --title-fqdn true --disk-show-regular true --disk-show-external true --disk-show-hidden true --disk-show-subvolumes true --disk-show-readonly true --disk-show-unknown true --physicaldisk-temp true --bluetooth-show-disconnected true --display-precise-refresh-rate true --cpu-temp true --cpu-show-pe-core-count true --cpuusage-separate true --gpu-temp true --gpu-driver-specific true --battery-temp true --localip-show-ipv4 true --localip-show-ipv6 true --localip-show-mac true --localip-show-loop true --localip-show-mtu true --localip-show-speed true --localip-show-prefix-len true --localip-show-all-ips true --localip-show-flags true --wm-detect-plugin true\""
            "SUPER, B, exec, uwsm app -- kitty sh -c \"btop\""

            "SUPER, W, exec, uwsm app -- firefox"
            "SUPER ALT, W, exec, uwsm app -- firefox --private-window"

            ", XF86Mail, exec, uwsm app -- thunderbird"
            "SUPER, M, exec, uwsm app -- thunderbird"

            "SUPER, C, exec, uwsm app -- code"
            "SUPER, D, exec, uwsm app -- dbeaver"

            "SUPER, V, exec, uwsm app -- vlc"
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
            "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            "col.inactive_border" = "rgba(595959aa)";

            no_focus_fallback = false;

            resize_on_border = true;
            hover_icon_on_border = true;
          };

          misc = {
            disable_autoreload = false;

            key_press_enables_dpms = true;
            mouse_move_enables_dpms = true;

            vfr = true;
            vrr = 1;

            render_ahead_of_time = false;

            mouse_move_focuses_monitor = true;

            disable_hyprland_logo = false;
            force_default_wallpaper = 0;
            disable_splash_rendering = true;

            font_family = "NotoSans Nerd Font";

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
            "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
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

            touchdevice =
              {
                enabled = true;
              };

            tablet = {
              left_handed = false;
            };
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
            rounding = 10;

            active_opacity = 1.0;
            inactive_opacity = 1.0;

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = "rgba(1a1a1aee)";
            };

            blur = {
              enabled = true;
              size = 3;
              passes = 1;

              vibrancy = 0.1696;
            };
          };

          animations = {
            enabled = "yes";

            bezier = [
              "easeOutQuint,0.23,1,0.32,1"
              "easeInOutCubic,0.65,0.05,0.36,1"
              "linear,0,0,1,1"
              "almostLinear,0.5,0.5,0.75,1.0"
              "quick,0.15,0,0.1,1"
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
          };
        };

        extraConfig = '' '';
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
          name = config.home-manager.users.bitscoper.home.pointerCursor.name;
          package = config.home-manager.users.bitscoper.home.pointerCursor.package;
          size = config.home-manager.users.bitscoper.home.pointerCursor.size;
        };

        font = {
          name = font_name.sans_serif;
          package = pkgs.nerd-fonts.noto;
          size = 11;
        };

        # gtk3.bookmarks = [
        #
        # ];
      };

      qt = {
        enable = true;

        platformTheme.name = "gtk";

        style = {
          name = "Dracula";
          package = pkgs.dracula-qt5-theme;
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
          defaultTimeout = 0; # Disabled

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

        udiskie = {
          enable = true;

          tray = "never";
          automount = true;
          notify = true;
        };

        hyprpaper = {
          enable = true;

          settings =
            let
              wallpaper_1 = builtins.fetchurl {
                url = "https://raw.githubusercontent.com/JaKooLit/Wallpaper-Bank/refs/heads/main/wallpapers/Dark_Nature.png";
              };
            in
            {
              ipc = "on";

              splash = false;

              preload =
                [
                  wallpaper_1
                ];

              wallpaper = [
                ", ${wallpaper_1}"
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
              fractional_scaling = 2; # 2 = Auto

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
                path = "screenshot";
                blur_passes = 4;
                blur_size = 4;
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
                # outer_color = "";
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
                # capslock_color = "";
                # numlock_color = "";
                # bothlock_color = "";

                # check_color = "";
                # fail_color = "";
                fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
                fail_timeout = 2000;
              }
            ];
          };

          extraConfig = '' '';
        };

        rofi = {
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

          theme =
            let
              inherit (config.home-manager.users.bitscoper.lib.formats.rasi) mkLiteral;
            in
            {
              "*" = {
                margin = 0;
                background-color = mkLiteral "transparent";
                padding = 0;
                spacing = 0;
                text-color = mkLiteral dracula_theme.hex.foreground;
              };

              "window" = {
                width = mkLiteral "768px";
                border = mkLiteral "1px";
                border-radius = mkLiteral "16px";
                border-color = mkLiteral dracula_theme.hex.purple;
                background-color = mkLiteral dracula_theme.hex.background;
              };

              "mainbox" = {
                padding = mkLiteral "16px";
              };

              "inputbar" = {
                border = mkLiteral "1px";
                border-radius = mkLiteral "8px";
                border-color = mkLiteral dracula_theme.hex.comment;
                background-color = mkLiteral dracula_theme.hex.current_line;
                padding = mkLiteral "8px";
                spacing = mkLiteral "8px";
                children = map mkLiteral [
                  "prompt"
                  "entry"
                ];
              };

              "prompt" = {
                text-color = mkLiteral dracula_theme.hex.foreground;
              };

              "entry" = {
                placeholder-color = mkLiteral dracula_theme.hex.comment;
                placeholder = "Search";
              };

              "listview" = {
                margin = mkLiteral "16px 0px 0px 0px";
                fixed-height = false;
                lines = 8;
                columns = 2;
              };

              "element" = {
                border-radius = mkLiteral "8px";
                padding = mkLiteral "8px";
                spacing = mkLiteral "8px";
                children = map mkLiteral [
                  "element-icon"
                  "element-text"
                ];
              };

              "element-icon" = {
                vertical-align = mkLiteral "0.5";
                size = mkLiteral "1em";
              };

              "element-text" = {
                text-color = mkLiteral "inherit";
              };

              "element.selected" = {
                background-color = mkLiteral dracula_theme.hex.current_line;
              };
            };
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

                on-click = "uwsm app -- pavucontrol";
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

                on-click = "uwsm app -- blueman-manager";
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

                on-click = "uwsm app -- nm-connection-editor";
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
                  {
                    type = "audio-out";
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

                on-click = "uwsm app -- kitty sh -c \"btop\"";
              };

              memory = {
                interval = 1;

                format = "{percentage}% ";

                tooltip = true;
                tooltip-format = "Used RAM: {used} GiB ({percentage}%)\nUsed Swap: {swapUsed} GiB ({swapPercentage}%)\nAvailable RAM: {avail} GiB\nAvailable Swap: {swapAvail} GiB";

                on-click = "uwsm app -- kitty sh -c \"btop\"";
              };

              cpu = {
                interval = 1;

                format = "{usage}% ";

                tooltip = true;

                on-click = "uwsm app -- kitty sh -c \"btop\"";
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

                on-click = "uwsm app -- kitty sh -c \"btop\"";
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

            #privacy-item.audio-out {
              color: ${dracula_theme.hex.foreground};
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

            # Colors
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

            # Splits/Windows
            active_border_color = dracula_theme.hex.foreground;
            inactive_border_color = dracula_theme.hex.comment;

            # Tab Bar Colors
            active_tab_foreground = dracula_theme.hex.background;
            active_tab_background = dracula_theme.hex.foreground;
            inactive_tab_foreground = dracula_theme.hex.background;
            inactive_tab_background = dracula_theme.hex.comment;

            # Marks
            mark1_foreground = dracula_theme.hex.background;
            mark1_background = dracula_theme.hex.red;

            # Cursor Colors
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

          extraConfig = '' '';
        };

        git = {
          enable = true;
          userName = "Abdullah As-Sadeed";
          userEmail = "bitscoper@gmail.com";
        };
      };
    };

    verbose = true;
  };
}
