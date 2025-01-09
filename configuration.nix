# By Abdullah As-Sadeed

{ config
, pkgs
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
  android-sdk = android-nixpkgs.sdk (sdkPkgs: with sdkPkgs; [
    build-tools-35-0-0
    cmdline-tools-latest
    emulator
    extras-google-auto
    extras-google-google-play-services
    platform-tools
    platforms-android-35
    system-images-android-34-android-tv-x86
    system-images-android-34-android-wear-x86-64
    system-images-android-35-google-apis-playstore-x86-64
  ]);
  android-sdk-path = "${android-sdk}/share/android-sdk";

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

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    sensor.hddtemp = {
      enable = true;
      unit = "C";
      drives = [
        "/dev/disk/by-path/*"
      ];
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
      ];
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

    udev = {
      enable = true;
      packages = with pkgs; [
        android-udev-rules
        game-devices-udev-rules
        rtl-sdr
        usb-blaster-udev-rules
      ];
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
    };

    opendkim = {
      enable = true;

      selector = "default";
    };

    dovecot2 = {
      enable = true;
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
        ADMIN_EMAIL = "bitscoper@Bitscoper-WorkStation";

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

  security = {
    rtkit.enable = true;

    polkit = {
      enable = true;
    };

    pam.services.hyprlock = { };

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

    hyprlock.enable = true;

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

      protontricks.enable = true;
      extest.enable = true;

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

  environment = {
    variables = pkgs.lib.mkForce {
      ANDROID_SDK_ROOT = android-sdk-path;
      ANDROID_HOME = android-sdk-path;

      # LD_LIBRARY_PATH = "${pkgs.glib.out}/lib/:${pkgs.libGL}/lib/:${pkgs.stdenv.cc.cc.lib}/lib:${existingLibraryPaths}";
    };

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      CHROME_EXECUTABLE = "chromium";
    };

    systemPackages = with pkgs; [
      # gimp-with-plugins
      acl
      agi
      aircrack-ng
      android-backup-extractor
      android-sdk # Custom
      android-tools
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
      git
      git-doc
      glib
      glibc
      gnome-font-viewer
      gnumake
      gource
      gpredict
      gradle
      gradle-completion
      greetd.tuigreet
      grim
      guestfs-tools
      gzip
      hyprcursor
      hyprls
      hyprpaper
      hyprpicker
      hyprpolkitagent
      iftop
      inotify-tools
      jellyfin-media-player
      john
      johnny
      jq
      keepassxc
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
      mako
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
      rofi-wayland
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
      udiskie
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
      fontawesome5
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

  fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [
      corefonts
      font-awesome
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
        systemd.enable = false;

        plugins = [ ];

        settings = { };
      };

      xdg = {
        mime.enable = true;

        configFile."mimeapps.list".force = true;

        mimeApps = {
          enable = true;

          associations = {
            added = config.xdg.mime.addedAssociations;

            removed = config.xdg.mime.removedAssociations;
          };

          defaultApplications = config.xdg.mime.defaultApplications;
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
          name = "NotoSans Nerd Font";
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

      programs = {
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
                "user"
                "disk"
                "memory"
                "cpu"
                "load"
                "battery"
              ];

              power-profiles-daemon = {
                format = "{icon}";
                format-icons = {
                  default = "";
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
                timezone = "Asia/Dhaka";
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
                icon-size = 16;
                icon-spacing = 4;
                transition-duration = 200;

                modules = [
                  {
                    type = "screenshare";
                    tooltip = true;
                    tooltip-icon-size = 16;
                  }
                  {
                    type = "audio-out";
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
                  numlock = "󰎠";
                };
              };

              systemd-failed-units = {
                system = true;
                user = true;

                hide-on-ok = false;

                format = "{nr_failed_system}, {nr_failed_user} ";
                format-ok = "";
              };

              user = {
                interval = 1;
                icon = false;

                format = "{work_d}:{work_H}:{work_M}:{work_S}";

                open-on-click = false;
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

              load = {
                interval = 1;

                format = "{} ";

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
                format-charging = "{capacity}% ";
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
                active-first = true;
                sort-by-app-id = false;
                format = "{icon}";
                icon-theme = "Dracula";
                icon-size = 16;
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
                icon-size = 16;
                spacing = 8;
              };
            };
          };

          style = ''
            @define-color background-darker rgba(30, 31, 41, 230);
            @define-color background #282a36;
            @define-color selection #44475a;
            @define-color foreground #f8f8f2;
            @define-color comment #6272a4;
            @define-color cyan #8be9fd;
            @define-color green #50fa7b;
            @define-color orange #ffb86c;
            @define-color pink #ff79c6;
            @define-color purple #bd93f9;
            @define-color red #ff5555;
            @define-color yellow #f1fa8c;
          '';
        };

        kitty = {
          enable = true;

          shellIntegration = {
            mode = "no-rc";
            enableBashIntegration = true;
          };

          settings = {
            confirm_os_window_close = 0;

            # Colors
            foreground = "#f8f8f2";
            background = "#282a36";
            selection_foreground = "#ffffff";
            selection_background = "#44475a";
            url_color = "#8be9fd";
            title_fg = "#f8f8f2";
            title_bg = "#282a36";
            margin_bg = "#6272a4";
            margin_fg = "#44475a";
            removed_bg = "#ff5555";
            highlight_removed_bg = "#ff5555";
            removed_margin_bg = "#ff5555";
            added_bg = "#50fa7b";
            highlight_added_bg = "#50fa7b";
            added_margin_bg = "#50fa7b";
            filler_bg = "#44475a";
            hunk_margin_bg = "#44475a";
            hunk_bg = "#bd93f9";
            search_bg = "#8be9fd";
            search_fg = "#282a36";
            select_bg = "#f1fa8c";
            select_fg = "#282a36";

            # Splits/Windows
            active_border_color = "#f8f8f2";
            inactive_border_color = "#6272a4";

            # Tab Bar Colors
            active_tab_foreground = "#282a36";
            active_tab_background = "#f8f8f2";
            inactive_tab_foreground = "#282a36";
            inactive_tab_background = "#6272a4";

            # Marks
            mark1_foreground = "#282a36";
            mark1_background = "#ff5555";

            # Cursor Colors
            cursor = "#f8f8f2";
            cursor_text_color = "#282a36";

            # Black
            color0 = "#21222c";
            color8 = "#6272a4";

            # Red
            color1 = "#ff5555";
            color9 = "#ff6e6e";

            # Green
            color2 = "#50fa7b";
            color10 = "#69ff94";

            # Yellow
            color3 = "#f1fa8c";
            color11 = "#ffffa5";

            # Blue
            color4 = "#bd93f9";
            color12 = "#d6acff";

            # Magenta
            color5 = "#ff79c6";
            color13 = "#ff92df";

            # Cyan
            color6 = "#8be9fd";
            color14 = "#a4ffff";

            # White
            color7 = "#f8f8f2";
            color15 = "#ffffff";
          };

          font = {
            name = "NotoMono Nerd Font";
            package = pkgs.nerd-fonts.noto;
            size = 11;
          };
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
