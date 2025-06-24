# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/refs/heads/master.tar.gz";

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

  backlight_device = "intel_backlight";

  design_factor = 16;

  font_preferences = {
    package = pkgs.nerd-fonts.noto;

    name = {
      mono = "NotoMono Nerd Font Mono";
      sans_serif = "NotoSans Nerd Font";
      serif = "NotoSerif Nerd Font";
      emoji = "Noto Color Emoji";
    };

    size = builtins.floor (design_factor * 0.75); # 12
  };

  cursor = {
    theme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };

    size = builtins.floor (design_factor * 1.50); # 24
  };

  jasper_grey_dark_gtk_theme = (
    pkgs.jasper-gtk-theme.override {
      themeVariants = [
        "grey"
      ];
      colorVariants = [
        "dark"
      ];
      sizeVariants = [
        "standard"
      ];
      tweaks = [
      ];
    }
  );

  gtk_theme_name = "Jasper-Grey-Dark";

  gtk4_css_file = builtins.readFile "${jasper_grey_dark_gtk_theme}/share/themes/Jasper-Grey-Dark/gtk-4.0/gtk-dark.css";
  gtk4_css_lines = builtins.filter (x: builtins.isString x) (builtins.split "\n" gtk4_css_file);

  gtk4_css_color_lines = builtins.filter (
    line: builtins.match "^@define-color [^ ]+ [^;]+;" line != null
  ) gtk4_css_lines;
  gtk4_color_list = builtins.filter (x: x != null) (
    builtins.map (
      line:
      let
        m = builtins.match "@define-color ([^ ]+) ([^;]+);" line;
      in
      if m == null then
        null
      else
        {
          name = builtins.elemAt m 0;
          value = builtins.elemAt m 1;
        }
    ) gtk4_css_color_lines
  );
  gtk4_color_attributes = builtins.listToAttrs gtk4_color_list;

  colors = {
    hex = {
      background = gtk4_color_attributes.theme_bg_color;
      base_background = gtk4_color_attributes.theme_base_color;
      insensitive_background = gtk4_color_attributes.insensitive_bg_color;
      insensitive_base_background = gtk4_color_attributes.insensitive_base_color;
      selected_background = gtk4_color_attributes.theme_selected_bg_color;
      content_view_background = gtk4_color_attributes.content_view_bg;
      text_view_background = gtk4_color_attributes.text_view_bg;
      unfocused_background = gtk4_color_attributes.theme_unfocused_bg_color;
      unfocused_base_background = gtk4_color_attributes.theme_unfocused_base_color;
      unfocused_selected_background = gtk4_color_attributes.theme_unfocused_selected_bg_color;

      foreground = gtk4_color_attributes.theme_fg_color;
      unfocused_foreground = gtk4_color_attributes.theme_unfocused_fg_color;

      text = gtk4_color_attributes.theme_text_color;
      unfocused_text = gtk4_color_attributes.theme_unfocused_text_color;
      placeholder_text = gtk4_color_attributes.placeholder_text_color;

      error = gtk4_color_attributes.error_color;
      warning = gtk4_color_attributes.warning_color;
      success = gtk4_color_attributes.success_color;
    };

    rgba = {
      borders = gtk4_color_attributes.borders;
      unfocused_borders = gtk4_color_attributes.unfocused_borders;

      insensitive_foreground = gtk4_color_attributes.insensitive_fg_color;
      selected_foreground = gtk4_color_attributes.theme_selected_fg_color;
      unfocused_selected_foreground = gtk4_color_attributes.theme_unfocused_selected_fg_color;
      unfocused_insensitive_color = gtk4_color_attributes.unfocused_insensitive_color;
    };
  };

  animation_duration = 200; # ms

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

      # themePackages = [
      #   pkgs.nixos-bgrt-plymouth
      # ];
      # theme = "nixos-bgrt";

      theme = "black_hud";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = [ config.boot.plymouth.theme ];
        })
      ];

      font = "${pkgs.nerd-fonts.noto}/share/fonts/truetype/NerdFonts/Noto/NotoSansNerdFont-Regular.ttf";

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
        "pipe-operators"
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
    extraLocales = "all";

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
    enableIPv6 = true;

    domain = "local";
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
        5900 # VNC
      ];
      allowedUDPPorts = [
        5900 # VNC
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

    soteria = {
      enable = true;
      package = pkgs.soteria;
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
      cloudflare-warp # Unfree
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

      packages = with pkgs; [
      ];
    };

    timesyncd = {
      enable = true;

      servers = config.networking.timeServers;
      fallbackServers = config.networking.timeServers;
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

      defaultSession = "hyprland-uwsm";

      autoLogin = {
        enable = false;
        user = null;
      };

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

            Font = font_preferences.name.sans_serif;
          };
        };

        stopScript = '''';
      };

      logToJournal = true;
      logToFile = true;
    };

    gnome = {
      gnome-keyring.enable = true;
      gcr-ssh-agent.enable = true;
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

      wideArea = false;

      publish = {
        enable = true;
        domain = true;
        addresses = true;
        workstation = true;
        hinfo = true;
        userServices = true;
      };

      domainName = config.networking.domain;
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
        {
          addr = "::";
        }
      ];
      ports = [
        22
      ];
      allowSFTP = true;

      banner = config.networking.fqdn;

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
        ServerName ${config.networking.fqdn}
        ServerAlias *
        ServerTokens Full
        ServerAdmin bitscoper@${config.networking.fqdn}
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
      listen = "*";
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
          bind-address = "*";
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

      domain = config.networking.fqdn;
      hostname = config.networking.fqdn;
      origin = config.networking.fqdn;

      virtualMapType = "pcre";
      aliasMapType = "pcre";
      enableHeaderChecks = true;

      setSendmail = true;

      config = { };
    };

    opendkim = {
      enable = true;

      domains = "csl:${config.networking.fqdn}";
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

    wordpress = {
      sites = { };
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

    gtklock = {
      enable = true;
      # package = pkgs.gtklock;
      package = (pkgs.callPackage ./Custom_gtklock.nix { });
      modules = with pkgs; [
        gtklock-playerctl-module
        gtklock-powerbar-module
      ];

      config = {
        main = {
          time-format = "%I:%M %p";
          gtk-theme = gtk_theme_name;
        };
      };

      style = ''
        window {
          background-image: url("${wallpaper}");
          background-repeat: no-repeat;
          background-position: center;
          background-size: cover;
          background-color: ${colors.hex.background};
        }
      '';
    };

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

        pinentryPackage = pkgs.pinentry-gtk2;
      };

      dirmngr.enable = true;
    };

    ssh = {
      package = pkgs.openssh;

      startAgent = false; # `services.gnome.gcr-ssh-agent.enable' and `programs.ssh.startAgent' cannot both be enabled at the same time.
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

    gnome-disks.enable = true;
    system-config-printer.enable = true;
    seahorse.enable = true;

    nm-applet = {
      enable = true;
      indicator = true;
    };

    nautilus-open-any-terminal = {
      enable = true;
      terminal = "tilix";
    };

    file-roller.enable = true;

    virt-manager = {
      enable = true;
      package = pkgs.virt-manager;
    };

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
          keepassxc
        ];
      };

      policies = {
        Extensions = {
          Install = [
            "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/languagetool/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/search_by_image/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/simple-mass-downloader/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/single-file/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/tab-disguiser/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/zjm-whatfont/latest.xpi"
          ];

          Locked = [
            "gelprec.smd@gmail.com" # "Simple mass download"
            "jid1-BoFifL9Vbdl2zQ@jetpack" # "Decentraleyes"
            "uBlock0@raymondhill.net" # "uBlock Origin"
            "{19b92b95-9cca-4f8d-b364-37a81f7133d5}" # "Tab Disguiser"
            "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}" # "Search by Image"
            "{531906d3-e22f-4a6c-a102-8057b88a1a63}" # "SingleFile"
            "{dcb8caa2-63fa-41aa-a508-a45c5990ebdd}" # "WhatFont"
          ];
        };
      };

      autoConfig = '''';

      preferences = {
        "browser.contentblocking.category" = "strict";
        "browser.search.region" = "BD";
        "browser.search.suggest.enabled.private" = true;
        "dom.security.https_only_mode" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "security.warn_submit_secure_to_insecure" = true;
        # "privacy.fingerprintingProtection" = true;
        # "privacy.trackingprotection.enabled" = true;
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

    dconf = {
      enable = true;
      profiles.user.databases = [
        {
          lockAll = true;

          settings = {
            "com/saivert/pwvucontrol" = {
              beep-on-volume-changes = true;
              enable-overamplification = true;
            };

            "com/gexperts/Tilix" = {
              auto-hide-mouse = false;
              close-with-last-session = false;
              control-scroll-zoom = true;
              enable-wide-handle = true;
              encodings = [
                "UTF-8"
              ];
              focus-follow-mouse = true;
              middle-click-close = false;
              new-instance-mode = "new-window";
              paste-strip-first-char = false;
              paste-strip-trailing-whitespace = false;
              tab-position = "top";
              terminal-title-show-when-single = true;
              terminal-title-style = "normal";
              theme-variant = "dark";
              use-overlay-scrollbar = false;
              window-save-state = false;
              window-style = "normal";
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

            "org/gnome/file-roller/ui" = {
              view-sidebar = true;
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

            "com/github/tenderowl/frog" = {
              telemetry = false;
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

            "io/gitlab/adhami3310/Converter" = {
              show-less-popular = true;
            };

            "io/github/amit9838/mousam" = {
              unit = "metric";
              use-24h-clock = false;
              use-gradient-bg = true;
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
          };
        }
      ];
    };
  };

  fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [
      corefonts # Unfree
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
    enableDebugInfo = false;

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
        # logdy
        # reiser4progs
        above
        acl
        aircrack-ng
        alac
        alpaca
        amass
        android_sdk # Custom
        android-tools
        apkeep
        apkleaks
        apksigner
        aptdec
        aria2
        aribb24
        aribb25
        arj
        audacity
        autopsy
        avrdude
        baobab
        bcachefs-tools
        binary
        binwalk
        bleachbit
        blender
        bluez-tools
        brightnessctl
        btrfs-progs
        bulk_extractor
        bustle
        bzip2
        bzip3
        cabextract
        celestia
        celt
        certbot-full
        chainsaw
        chmlib
        clang
        clang-analyzer
        clang-manpages
        clang-tools
        clinfo
        cliphist
        cloc
        cloudflare-warp # Unfree
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
        dconf2nix
        debase
        dig
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
        eyedropper
        f2fs-tools
        faad2
        fdk_aac
        ffmpeg-full
        ffmpegthumbnailer
        fh
        file
        flake-checker
        flightgear
        flutter
        fritzing
        fwupd-efi
        gcc
        gdb
        ghidra
        gimp-with-plugins
        git-doc
        git-filter-repo
        glib
        glibc
        gnome-characters
        gnome-clocks
        gnome-decoder
        gnome-font-viewer
        gnome-frog
        gnome-graphs
        gnome-logs
        gnome-nettool
        gnugrep
        gnulib
        gnumake
        gnused
        gnutar
        gnutls
        gource
        gparted
        gpredict
        graphs
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
        host
        hw-probe
        hwloc
        hydra-check
        hyprland-protocols
        hyprland-qt-support
        hyprland-qtutils
        hyprls
        hyprsysteminfo
        i2c-tools
        iaito
        iftop
        inkscape
        inotify-tools
        isocodes
        jellyfin-media-player
        jfsutils
        jmol
        john
        johnny
        jxrlib
        keepassxc
        kernelshark
        kicad
        letterpress
        lhasa
        libaom
        libappimage
        libass
        libbluray
        libcamera
        libcdio
        libde265
        libdvdcss
        libdvdnav
        libdvdread
        libepoxy
        libfreeaptx
        libfreefare
        libftdi1 # Update of libftdi
        libgcc
        libGL
        libGLU
        libgpg-error
        libguestfs
        libheif
        libilbc
        liblc3
        libnotify
        libogg
        libopus
        libosinfo
        libraw
        libreoffice-fresh
        libsamplerate
        libserialport
        libusb1
        libuuid
        libuvc
        libva-utils
        libvncserver
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
        lyto
        lz4
        lzham
        lzip
        lzlib
        lzop
        macchanger
        mailutils
        masscan
        massdns
        mattermost-desktop
        media-player-info
        meld
        mesa-demos
        mfcuk
        mfoc
        mission-center
        monkeysAudio
        mousam
        mtools
        mtr-gui
        nautilus
        netdiscover
        nethogs
        netsniff-ng
        networkmanagerapplet
        ngrok # Unfree
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
        opencore-amr
        opendmarc
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
        playerctl
        podman-compose
        podman-desktop
        progress
        pwvucontrol
        python313Full
        qalculate-gtk
        qbittorrent
        qemu-utils
        qpwgraph
        radare2
        readline
        reiserfsprogs
        rpi-imager
        rpmextract
        rpPPPoE
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
        sipvicious
        sleuthkit
        slurp
        smartmontools
        smbmap
        songrec
        soundconverter
        spice
        spice-gtk
        spice-protocol
        spooftooph
        sslscan
        subfinder
        subtitleedit
        swaks
        switcheroo
        szyszka
        tagger
        telegram-desktop
        telegraph
        terminal-colors
        terminaltexteffects
        texliveFull
        theharvester
        thermald
        tilix
        time
        tor-browser
        tree
        trufflehog
        trustymail
        udftools
        udiskie
        unar
        unicode-character-database
        unicode-emoji
        universal-android-debloater # uad-ng
        unix-privesc-check
        unzip
        upnp-router-control
        usbimager
        usbutils
        util-linux
        vcdimager
        virt-viewer
        virtio-win
        virtiofsd
        vlc
        vlc-bittorrent
        vulkan-caps-viewer
        vulkan-tools
        wafw00f
        wavpack
        waycheck
        wayland-utils
        waylevel
        wayvnc
        webcamoid
        webfontkitgenerator
        wev
        wget
        whatfiles
        which
        whois
        wifite2
        win-spice
        wl-clipboard
        woff2
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
        zenity
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

            BackgroundColor = colors.hex.background;
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

            # MainColor = ""; # TODO
            # AccentColor = ""; # TODO

            # HighlightBorderColor= ""; # TODO
            # HighlightBackgroundColor= ""; # TODO
            # HighlightTextColor= ""; # TODO

            HeaderTextColor = colors.hex.foreground;
            TimeTextColor = colors.hex.foreground;
            DateTextColor = colors.hex.foreground;

            IconColor = colors.hex.foreground;
            PlaceholderTextColor = colors.hex.foreground;
            WarningColor = colors.hex.error;

            # LoginFieldBackgroundColor = ""; # TODO
            # LoginFieldTextColor = ""; # TODO
            # UserIconColor = ""; # TODO
            # HoverUserIconColor = ""; # TODO

            # PasswordFieldBackgroundColor = ""; # TODO
            # PasswordFieldTextColor = ""; # TODO
            # PasswordIconColor = ""; # TODO
            # HoverPasswordIconColor = ""; # TODO

            # LoginButtonBackgroundColor = ""; # TODO
            LoginButtonTextColor = colors.hex.foreground;

            SystemButtonsIconsColor = colors.hex.foreground;
            # HoverSystemButtonsIconsColor = ""; # TODO

            SessionButtonTextColor = colors.hex.foreground;
            # HoverSessionButtonTextColor = ""; # TODO

            VirtualKeyboardButtonTextColor = colors.hex.foreground;
            # HoverVirtualKeyboardButtonTextColor = ""; # TODO

            DropdownBackgroundColor = colors.hex.background;
            DropdownSelectedBackgroundColor = colors.hex.base_background;
            DropdownTextColor = colors.hex.foreground;

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
        sponge
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

      # https://www.iana.org/assignments/media-types/media-types.xhtml
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

        "application/gzip" = "org.gnome.FileRoller.desktop";
        "application/vnd.rar" = "org.gnome.FileRoller.desktop";
        "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
        "application/x-arj" = "org.gnome.FileRoller.desktop";
        "application/x-bzip2" = "org.gnome.FileRoller.desktop";
        "application/x-gtar" = "org.gnome.FileRoller.desktop";
        "application/x-rar-compressed " = "org.gnome.FileRoller.desktop"; # More common than "application/vnd.rar"
        "application/x-tar" = "org.gnome.FileRoller.desktop";
        "application/zip" = "org.gnome.FileRoller.desktop";

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
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];

      xdgOpenUsePortal = false; # Opening Programs

      config = {
        common = {
          default = [
            "gtk"
            "hyprland"
          ];

          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };
      };
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

          packages = with pkgs; [
          ];

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
            # hypr-dynamic-cursors
          ];

          xwayland.enable = true;

          sourceFirst = true;

          settings = {
            monitor = [
              # Name, Resolution, Position, Scale, Transform-Parameter, Transform
              ", highres, auto, 1, transform, 0"
              "eDP-1, highres, auto, 1, transform, 0"
              "HDMI-A-1, highres, auto, 1, transform, 0"
            ];

            env = [
              "XCURSOR_SIZE, ${toString cursor.size}"
            ];

            exec-once = [
              "udiskie --tray --appindicator --automount --notify --file-manager nautilus"

              "sleep 2 && keepassxc" # 2 s

              "wl-paste --type text --watch cliphist store"
              "wl-paste --type image --watch cliphist store"

              "setfacl --modify user:jellyfin:--x ~ & adb start-server &"

              "systemctl --user start warp-taskbar"

              "rm -rf ~/.local/share/applications/waydroid.*"
            ];

            bind = [
              "SUPER, L, exec, gtklock"
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

              "SUPER, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

              ", PRINT, exec, filename=\"$(xdg-user-dir DOWNLOAD)/ScreenShot_$(date +'%B-%d-%Y_%I-%M-%S_%p').png\"; grim -g \"$(slurp -d)\" -t png -l 9 \"$filename\" && wl-copy < \"$filename\"" # I use the Downloads directory for temporary work.

              "SUPER, A, exec, wofi --show drun --disable-history"
              "SUPER, R, exec, wofi --show run --disable-history"

              "SUPER, T, exec, tilix"

              ", XF86Explorer, exec, nautilus"
              "SUPER, F, exec, nautilus"

              "SUPER, U, exec, missioncenter"

              "SUPER, W, exec, firefox-devedition"
              "SUPER ALT, W, exec, firefox-devedition --private-window"

              ", XF86Mail, exec, thunderbird"
              "SUPER, M, exec, thunderbird"

              "SUPER, E, exec, codium"
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

              font_family = font_preferences.name.sans_serif;

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

            # "plugin:dynamic-cursors" = {
            #   enabled = true;
            #   hyprcursor = {
            #     enabled = true;
            #     nearest = true;
            #     resolution = -1;
            #   };

            #   threshold = 1;
            #   mode = "rotate";
            #   rotate = {
            #     length = cursor.size;
            #   };

            #   shake = {
            #     enabled = true;
            #     effects = false;
            #     nearest = true;
            #     ipc = true;
            #   };
            # };

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

              rounding = builtins.floor (design_factor * 0.50); # 8

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
            name = gtk_theme_name;
            package = jasper_grey_dark_gtk_theme;
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
            name = font_preferences.name.sans_serif;
            package = font_preferences.package;
            size = font_preferences.size;
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
          swaync = {
            enable = true;
            package = pkgs.swaynotificationcenter;

            settings = {
              "\$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/configSchema.json";
              cssPriority = "application";

              layer-shell = true;
              layer-shell-cover-screen = true;
              fit-to-screen = false;

              control-center-layer = "overlay";
              control-center-exclusive-zone = true;
              control-center-positionX = "right";
              control-center-positionY = "top";
              control-center-margin-top = builtins.floor (design_factor * 0.50); # 8
              control-center-margin-right = builtins.floor (design_factor * 0.50); # 8
              control-center-margin-bottom = builtins.floor (design_factor * 0.50); # 8
              control-center-margin-left = builtins.floor (design_factor * 0.50); # 8

              layer = "overlay";
              positionX = "right";
              positionY = "top";

              text-empty = "No Notifications";
              widgets = [
                "title"
                "notifications"
                "mpris"
                "dnd"
              ];
              widget-config = {
                title = {
                  text = "Notifications";

                  clear-all-button = true;
                  button-text = "Clear";
                };

                mpris = {
                  image-radius = design_factor;
                  blur = true;
                };

                dnd = {
                  text = "Do Not Disturb";
                };
              };

              image-visibility = "when-available";
              relative-timestamps = true;
              notification-inline-replies = true;
              notification-2fa-action = true;
              transition-time = animation_duration;

              timeout = 8;
              timeout-critical = 0; # 0 = Disable
              timeout-low = 4;

              keyboard-shortcuts = true;
              hide-on-action = true;
              hide-on-clear = true;
              script-fail-notify = true;
            };

            style = ''
              .blank-window {
                background: transparent;
              }

              .control-center {
                border-radius: ${toString design_factor}px;
                background-color: ${colors.hex.background};
                font-size: ${toString font_preferences.size}px;
                color: ${colors.hex.foreground};
              }

              .widget-title,
              .widget-dnd  {
                font-size: ${toString (font_preferences.size * 1.5)}px;
                color: ${colors.hex.foreground};
              }

              .widget-title > button {
                border-radius: ${toString design_factor}px;
              }

              .notification-row .notification-background .notification {
                border-radius: ${toString design_factor}px;
              }

              .notification-row .notification-background .notification .notification-default-action {
                border-radius: ${toString design_factor}px;
              }

              .notification-row .notification-background .notification .notification-default-action .notification-content {
                border-radius: ${toString design_factor}px;
              }

              .notification-row .notification-background .notification .notification-default-action .notification-content .body-image {
                border-radius: ${toString design_factor}px;
              }

              .notification-row .notification-background .notification .notification-default-action .notification-content .inline-reply .inline-reply-entry {
                border-radius: ${toString design_factor}px;
              }

              .notification-row .notification-background .notification .notification-default-action .notification-content .inline-reply .inline-reply-button {
                border-radius: ${toString design_factor}px;
              }

              .widget-mpris .widget-mpris-player {
                border-radius: ${toString design_factor}px;
              }

              .widget-mpris .widget-mpris-player .widget-mpris-album-art {
                border-radius: ${toString design_factor}px;
              }

              .widget-dnd > switch {
                border-radius: ${toString design_factor}px;
              }

              .widget-dnd > switch slider {
                border-radius: ${toString design_factor}px;
              }
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
          wofi = {
            enable = true;
            package = pkgs.wofi;

            settings = {
              normal_window = false;
              layer = "overlay";
              location = "center";

              gtk_dark = true;
              columns = 2;
              dynamic_lines = false;
              lines = 9; # 9 -1 = 8
              hide_scroll = false;

              hide_search = false;
              prompt = "Search";
              show_all = true;
              allow_markup = true;
              allow_images = true;
              image_size = 32;
              no_actions = true;

              insensitive = true;

              single_click = true;
              term = "tilix";
            };

            style = ''
              window {
                border-radius: ${toString design_factor}px;
              }

              #outer-box {
                padding: 16px;
              }

              #inner-box {
                margin-top: 16px;
              }

              #entry {
                margin-top: 4px;
                margin-bottom: 4px;
              }

              #img {
                margin-right: 4px;
              }
            '';
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
                  "group/backlight-and-ppd-and-idle-inhibitor"
                  "group/pulseaudio-and-bluetooth"
                  "group/hardware-statistics"
                  "network"
                  "privacy"
                ];

                modules-center = [
                  "clock"
                ];

                modules-right = [
                  "group/swaync-and-systemd"
                  "tray"
                  "group/workspaces-and-taskbar"
                ];

                clock = {
                  timezone = config.time.timeZone;
                  locale = "en_US";
                  interval = 1;

                  # format = "{:%I:%M:%S %p}";
                  format = "{:%I:%M %p}";
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

                "group/backlight-and-ppd-and-idle-inhibitor" = {
                  modules = [
                    "backlight"
                    "power-profiles-daemon"
                    "idle_inhibitor"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = animation_duration;
                  };
                  "orientation" = "inherit";
                };

                backlight = {
                  device = backlight_device;
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

                "group/pulseaudio-and-bluetooth" = {
                  modules = [
                    "pulseaudio"
                    "bluetooth"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = animation_duration;
                  };
                  "orientation" = "inherit";
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

                "group/hardware-statistics" = {
                  modules = [
                    "battery"
                    "cpu"
                    "memory"
                    "disk"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = animation_duration;
                  };
                  "orientation" = "inherit";
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

                cpu = {
                  interval = 1;

                  format = "{usage}% ";

                  tooltip = true;

                  on-click = "missioncenter";
                };

                memory = {
                  interval = 1;

                  format = "{percentage}% ";

                  tooltip = true;
                  tooltip-format = "Used RAM: {used} GiB ({percentage}%)\nUsed Swap: {swapUsed} GiB ({swapPercentage}%)\nAvailable RAM: {avail} GiB\nAvailable Swap: {swapAvail} GiB";

                  on-click = "missioncenter";
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

                privacy = {
                  icon-size = font_preferences.size;
                  icon-spacing = builtins.floor (design_factor * 0.50); # 8
                  transition-duration = 200;

                  modules = [
                    {
                      type = "screenshare";
                      tooltip = true;
                      tooltip-icon-size = font_preferences.size;
                    }
                    {
                      type = "audio-in";
                      tooltip = true;
                      tooltip-icon-size = font_preferences.size;
                    }
                  ];
                };

                "group/swaync-and-systemd" = {
                  modules = [
                    "custom/swaync"
                    "systemd-failed-units"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = false;
                    transition-duration = animation_duration;
                  };
                  "orientation" = "inherit";
                };

                "custom/swaync" = {
                  format = "{} {icon}";
                  format-icons = {
                    notification = "<span foreground=\"${colors.hex.warning}\"><sup></sup></span>";
                    none = "";

                    inhibited-notification = "<span foreground=\"${colors.hex.warning}\"><sup></sup></span>";
                    inhibited-none = "";

                    dnd-notification = "<span foreground=\"${colors.hex.warning}\"><sup></sup></span>";
                    dnd-none = "";

                    dnd-inhibited-notification = "<span foreground=\"${colors.hex.warning}\"><sup></sup></span>";
                    dnd-inhibited-none = "";
                  };

                  tooltip = false;

                  return-type = "json";
                  exec-if = "which swaync-client";
                  exec = "swaync-client -swb";
                  on-click = "swaync-client -t -sw";
                  on-click-right = "swaync-client -d -sw";
                  escape = true;
                };

                systemd-failed-units = {
                  system = true;
                  user = true;

                  hide-on-ok = false;

                  format = "{nr_failed_system}, {nr_failed_user} ";
                  format-ok = "";
                };

                tray = {
                  show-passive-items = true;
                  reverse-direction = false;
                  icon-size = font_preferences.size;
                  spacing = 4;
                };

                "group/workspaces-and-taskbar" = {
                  modules = [
                    "hyprland/workspaces"
                    "wlr/taskbar"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = false;
                    transition-duration = animation_duration;
                  };
                  "orientation" = "inherit";
                };

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
                  icon-size = font_preferences.size;
                  markup = true;

                  tooltip = true;
                  tooltip-format = "Title: {title}\nName: {name}\nID: {app_id}\nState: {state}";

                  on-click = "activate";
                };
              };
            };

            style = ''
              * {
                font-family: ${font_preferences.name.sans_serif};
                font-size: ${toString font_preferences.size};
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
              #clock,
              #custom-swaync,
              #privacy,
              #systemd-failed-units,
              #disk,
              #memory,
              #cpu,
              #battery,
              #window {
                border-radius: ${toString design_factor}px;
                background-color: ${colors.hex.background};
                padding: 2px 8px;
                color: ${colors.hex.foreground};
              }

              #power-profiles-daemon.power-saver,
              #power-profiles-daemon.balanced {
                color: ${colors.hex.success};
              }

              #power-profiles-daemon.performance {
                color: ${colors.hex.foreground};
              }

              #idle_inhibitor.deactivated {
                color: ${colors.hex.foreground};
              }

              #idle_inhibitor.activated {
                color: ${colors.hex.success};
              }

              #pulseaudio.muted,
              #pulseaudio.source-muted {
                color: ${colors.hex.error};
              }

              #pulseaudio.bluetooth {
                color: ${colors.hex.foreground};
              }

              #bluetooth.no-controller,
              #bluetooth.disabled,
              #bluetooth.off {
                color: ${colors.hex.error};
              }

              #bluetooth.on,
              #bluetooth.discoverable,
              #bluetooth.pairable {
                color: ${colors.hex.foreground};
              }

              #bluetooth.discovering,
              #bluetooth.connected {
                color: ${colors.hex.success};
              }

              #network.disabled,
              #network.disconnected,
              #network.linked {
                color: ${colors.hex.error};
              }

              #network.etherenet,
              #network.wifi {
                color: ${colors.hex.foreground};
              }

              #custom-swaync {
                font-family: ${font_preferences.name.mono};
              }

              #privacy-item.audio-in,
              #privacy-item.screenshare {
                color: ${colors.hex.success};
              }

              #systemd-failed-units.ok {
                color: ${colors.hex.foreground};
              }

              #systemd-failed-units.degraded {
                color: ${colors.hex.error};
              }

              #battery.plugged,
              #battery.full {
                color: ${colors.hex.foreground};
              }

              #battery.charging {
                color: ${colors.hex.success};
              }

              #battery.warning {
                color: ${colors.hex.warning};
              }

              #battery.critical {
                color: ${colors.hex.error};
              }

              #workspaces,
              #taskbar,
              #tray {
                background-color: transparent;
              }

              button {
                margin: 0px 2px;
                border-radius: ${toString design_factor}px;
                background-color: ${colors.hex.background};
                padding: 0px;
                color: ${colors.hex.foreground};
              }

              button * {
                padding: 0px 4px;
              }

              button.active {
                background-color: ${colors.hex.base_background};
              }

              #window label {
                padding: 0px 4px;
                font-size: ${toString font_preferences.size};
              }

              #tray > widget {
                border-radius: ${toString design_factor}px;
                background-color: ${colors.hex.background};
                color: ${colors.hex.foreground};
              }

              #tray image {
                padding: 0px 8px;
              }

              #tray > .passive {
                -gtk-icon-effect: dim;
              }

              #tray > .active {
                background-color: ${colors.hex.base_background};
              }

              #tray > .needs-attention {
                background-color: ${colors.hex.success};
                -gtk-icon-effect: highlight;
              }

              #tray > widget:hover {
                background-color: ${colors.hex.base_background};
              }
            '';
          };

          dircolors = {
            enable = true;
            package = pkgs.coreutils-full;

            enableBashIntegration = true;
            enableFishIntegration = true;

            settings = { };
          };

          nix-your-shell = {
            enable = true;
            package = pkgs.nix-your-shell;

            enableFishIntegration = true;
          };

          vscode = {
            enable = true;
            package = pkgs.vscodium;
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
                    ms-azuretools.vscode-docker
                    ms-python.black-formatter
                    ms-python.debugpy
                    ms-python.isort
                    ms-python.python
                    ms-toolsai.datawrangler
                    ms-toolsai.jupyter
                    ms-toolsai.jupyter-keymap
                    ms-toolsai.jupyter-renderers
                    ms-toolsai.vscode-jupyter-cell-tags
                    ms-toolsai.vscode-jupyter-slideshow
                    ms-vscode-remote.remote-containers
                    ms-vscode-remote.remote-ssh
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
                    rioj7.commandonallfiles
                    rubymaniac.vscode-paste-and-indent
                    ryu1kn.partial-diff
                    sanaajani.taskrunnercode
                    shardulm94.trailing-spaces
                    skyapps.fish-vscode
                    slevesque.vscode-multiclip
                    spywhere.guides
                    stylelint.vscode-stylelint
                    tailscale.vscode-tailscale
                    tamasfe.even-better-toml
                    timonwong.shellcheck
                    usernamehw.errorlens
                    vincaslt.highlight-matching-tag
                    visualstudioexptteam.intellicode-api-usage-examples
                    visualstudioexptteam.vscodeintellicode
                    vscjava.vscode-gradle
                    vscode-icons-team.vscode-icons
                    wmaurer.change-case
                    zainchen.json
                  ]
                  ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
                    {
                      name = "unique-lines";
                      publisher = "bibhasdn";
                      version = "1.0.0";
                      sha256 = "W0ZpZ6+vjkfNfOtekx5NWOFTyxfWAiB0XYcIwHabFPQ=";
                    }
                    {
                      name = "vscode-sort";
                      publisher = "henriiik";
                      version = "0.2.5";
                      sha256 = "pvlSlWJTnLB9IbcVsz5HypT6NM9Ujb7UYs2kohwWVWk=";
                    }
                    {
                      name = "vscode-sort-json";
                      publisher = "richie5um2";
                      version = "1.20.0";
                      sha256 = "Jobx5Pf4SYQVR2I4207RSSP9I85qtVY6/2Nvs/Vvi/0=";
                    }
                    {
                      name = "pubspec-assist";
                      publisher = "jeroen-meijer";
                      version = "2.3.2";
                      sha256 = "+Mkcbeq7b+vkuf2/LYT10mj46sULixLNKGpCEk1Eu/0=";
                    }
                    {
                      name = "arb-editor";
                      publisher = "Google";
                      version = "0.2.1";
                      sha256 = "uHdQeW9ZXYg6+VnD6cb5CU10/xV5hCtxt5K+j0qb7as=";
                    }
                    {
                      name = "vscode-serial-monitor";
                      publisher = "ms-vscode";
                      version = "0.13.250503001";
                      sha256 = "iuni/DybnUxdbvggvlCidurW4GevVPvwYO7/5i+S1ok=";
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
          }; # Unfree

          matplotlib = {
            enable = true;

            config = { };
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
              default = {
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
            ];
            nativeMessagingHosts = config.programs.firefox.nativeMessagingHosts.packages;

            commandLineArgs = [
              "--ozone-platform=wayland"
              "--password-store=gnome"
              "--proxy-auto-detect"
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
              obs-rgb-levels
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
          };
        };
      }
    ];

    users.root = { };
    users.bitscoper = { };

    verbose = true;
  };
}

# setfacl --modify user:jellyfin:--x ~

# FIXME: 05ac-033e-Gamepad > Rumble
# FIXME: ELAN7001 SPI Fingerprint Sensor
# FIXME: Hyprpaper Delay
# FIXME: MariaDB > Login
# FIXME: Notifications
# FIXME: Wofi > Window > Border Radius > Background
# FIXME: hardinfo2
# FIXME: rpi-imager
