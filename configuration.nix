# By Abdullah As-Sadeed

{
  config,
  options,
  pkgs,
  lib,
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
      build-tools-36-1-0
      cmake-4-1-2
      cmdline-tools-latest
      emulator
      ndk-29-0-14206865
      platform-tools
      platforms-android-36
      system-images-android-36-google-apis-playstore-x86-64
      tools
    ]
  );
  android_sdk_path = "${android_sdk}/share/android-sdk";

  font_preferences = {
    package = pkgs.nerd-fonts.noto;

    name = {
      mono = "NotoMono Nerd Font Mono";
      sans_serif = "NotoSans Nerd Font";
      serif = "NotoSerif Nerd Font";
      emoji = "Noto Color Emoji";
    };
  };

  cursor = {
    theme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  design_factor = 16;

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

    kernel = {
      enable = true;

      sysctl = {
        "net.ipv4.tcp_syncookies" = true;
      };
    };

    kernelPackages = pkgs.linuxKernel.packages.linux_6_17;

    extraModulePackages = with config.boot.kernelPackages; [
      apfs
      cpupower
      mm-tools
      openafs
      tmon
      turbostat
      usbip
      zfs_unstable
    ];

    kernelModules = [
      "at24"
      "ee1004"
      "kvm-intel"
      "spd5118"
    ];

    extraModprobeConfig = ''
      options kvm_intel nested=1
      options kvm report_ignored_msrs=0
    '';

    kernelParams = [
      "boot.shell_on_fail"
      "intel_iommu=on"
      "iommu=pt"
      "kvm.ignore_msrs=1"
      "mitigations=auto"
      "rd.systemd.show_status=true"
      "rd.udev.log_level=err"
      "udev.log_level=err"
      "udev.log_priority=err"
    ];

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

    consoleLogLevel = 4; # 4 = KERN_WARNING

    tmp.cleanOnBoot = true;

    plymouth = {
      enable = true;

      themePackages = [
        pkgs.nixos-bgrt-plymouth
      ];
      theme = "nixos-bgrt";

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

    # activationScripts = { };
    # userActivationScripts = { };

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

      cores = 1;
      max-jobs = 1;
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

    # overlays = [ ];
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

      enableGtk2 = true;
      enableGtk3 = true;

      type = "ibus";
      ibus = {
        engines = with pkgs.ibus-engines; [
          openbangla-keyboard
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
      package = (
        pkgs.networkmanager.override {
          withSystemd = true;
        }
      );

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
        3389 # GNOME Remote Desktop - Remote Login
        3390 # GNOME Remote Desktop - Desktop Sharing
      ];
      allowedUDPPorts = [
        3389 # GNOME Remote Desktop - Remote Login
        3390 # GNOME Remote Desktop - Desktop Sharing
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
      package = (
        pkgs.sudo.override {
          withInsults = true;
        }
      );

      execWheelOnly = true;
      wheelNeedsPassword = true;
    };

    polkit = {
      enable = true;
      package = (
        pkgs.polkit.override {
          useSystemd = true;
        }
      );
    };

    rtkit.enable = true;

    wrappers = {
      spice-client-glib-usb-acl-helper.source = "${
        (pkgs.spice-gtk.override {
          withPolkit = true;
        })
      }/bin/spice-client-glib-usb-acl-helper";
    };

    audit = {
      enable = false;
    };
  };

  hardware = {
    enableAllFirmware = true; # Unfree
    enableRedistributableFirmware = true;
    firmware = with pkgs; [
      alsa-firmware
      linux-firmware
      sof-firmware
    ];

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
      package = (
        pkgs.bluez.override {
          enableExperimental = true;
        }
      );

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
          RemoteNameRequestRetryDelay = 60; # 1 Minute
          RefreshDiscovery = true;
          TemporaryTimeout = 0; # 0 = Disabled

          SecureConnections = "on";
          Privacy = "off";

          Experimental = true; # Shows Battery Percentage
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
      backends-package = (
        pkgs.sane-backends.override {
          withSystemd = true;
        }
      );
      # extraBackends = with pkgs; [ ];
      snapshot = false;

      openFirewall = true;
    };
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      package = pkgs.libvirt;

      qemu = {
        package = (
          pkgs.qemu_kvm.override {
            guestAgentSupport = true;
            alsaSupport = true;
            pulseSupport = true;
            pipewireSupport = true;
            sdlSupport = true;
            jackSupport = true;
            gtkSupport = true;
            vncSupport = true;
            smartcardSupport = true;
            spiceSupport = true;
            usbredirSupport = true;
            glusterfsSupport = true;
            openGLSupport = true;
            rutabagaSupport = true;
            virglSupport = true;
            libiscsiSupport = true;
            smbdSupport = true;
            tpmSupport = true;
            uringSupport = true;
            pluginsSupport = true;
            enableDocs = true;
            enableTools = true;
            enableBlobs = true;
          }
        );

        swtpm = {
          enable = true;
          package = pkgs.swtpm;
        };

        runAsRoot = true;
      };
    };
    spiceUSBRedirection.enable = true;

    containers.enable = true;

    docker = {
      enable = true;
      package = (
        pkgs.docker.override {
          buildxSupport = true;
          composeSupport = true;
          sbomSupport = true;
          initSupport = true;

          withSystemd = true;
          withBtrfs = true;
          withLvm = true;
          withSeccomp = true;
        }
      );

      logDriver = "journald";

      listenOptions = [
        "/run/docker.sock"
      ];

      daemon.settings = {
        ipv6 = true;

        live-restore = true;
      };

      enableOnBoot = true;
    };

    oci-containers.backend = "docker";

    waydroid = {
      enable = true;
      package = pkgs.waydroid;
    };
  };

  systemd = {
    package = (
      pkgs.systemd.override {
        withAcl = true;
        withCryptsetup = true;
        withDocumentation = true;
        withLogind = true;
        withOpenSSL = true;
        withPam = true;
        withPolkit = true;
      }
    );

    packages = with pkgs; [
      (hardinfo2.override {
        printingSupport = true;
      })
    ];

    services = {
      gnome-remote-desktop = {
        wantedBy = [
          "graphical.target"
        ];
      };

      hardinfo2_custom = {
        description = "Hardinfo2 support for root access";
        wantedBy = [ "basic.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.hardinfo2}/bin/hwinfo2_fetch_sysdata"; # The ${pkgs.hardinfo2}/lib/systemd/system/hardinfo2.service file intends to run ${pkgs.hardinfo2}/bin/hwinfo2_fetch_sysdata oneshot which calls ${pkgs.hardinfo2}/bin/.hwinfo2_fetch_sysdata-wrapped
        };

        enable = true;
      };
    }; # Custom Service Unit File due to Errors

  };

  services = {
    hardware.bolt.enable = true;

    dbus = {
      enable = true;
      dbusPackage = (
        pkgs.dbus.override {
          enableSystemd = true;
        }
      );

      implementation = "broker";
    };

    timesyncd = {
      enable = true;

      servers = config.networking.timeServers;
      fallbackServers = config.networking.timeServers;
    };

    fwupd = {
      enable = true;
      package = (
        pkgs.fwupd.override {
          enableFlashrom = true;
        }
      );
    };

    acpid = {
      enable = true;

      # powerEventCommands = '''';
      # acEventCommands = '''';
      # lidEventCommands = '''';

      logEvents = false;
    };

    thermald = {
      enable = true;
      package = pkgs.thermald;

      ignoreCpuidCheck = false;

      debug = false;
    };

    power-profiles-daemon = {
      enable = true;
      package = pkgs.power-profiles-daemon;
    };

    logind = {
      settings = {
        Login = {
          killUserProcesses = true;

          lidSwitch = "ignore";
          lidSwitchDocked = "ignore";
          lidSwitchExternalPower = "ignore";

          powerKey = "poweroff";
          powerKeyLongPress = "poweroff";

          rebootKey = "reboot";
          rebootKeyLongPress = "reboot";

          suspendKey = "suspend";
          suspendKeyLongPress = "suspend";

          hibernateKey = "hibernate";
          hibernateKeyLongPress = "hibernate";
        };
      };
    };

    displayManager.gdm = {
      enable = true;
      wayland = true;

      banner = config.networking.fqdn;
      autoSuspend = false;

      settings = {
        security = {
          DisallowTCP = false;
        };

        xdmcp = {
          Enable = true;
          HonorIndirect = true;
        };

        greeter = {
          IncludeAll = true;
        };
      };

      debug = false;
    };

    desktopManager.gnome = {
      enable = true;

      debug = false;
    };

    gnome = {
      at-spi2-core.enable = true;
      core-apps.enable = true;
      core-os-services.enable = true;
      core-shell.enable = true;
      games.enable = false;
      gcr-ssh-agent.enable = true;
      glib-networking.enable = true;
      gnome-browser-connector.enable = true;
      gnome-initial-setup.enable = false;
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true;
      gnome-remote-desktop.enable = true;
      gnome-settings-daemon.enable = true;
      gnome-user-share.enable = true;
      localsearch.enable = true;
      sushi.enable = true;
      tinysparql.enable = true;
      rygel = {
        enable = true;
        package = pkgs.rygel;
      };
    };

    udev = {
      enable = true;
      packages = with pkgs; [
        game-devices-udev-rules
        gnome-settings-daemon
        libmtp.out
        rtl-sdr
      ];
    };

    gvfs = {
      enable = true;
      package = (
        pkgs.gvfs.override {
          udevSupport = true;
        }
      );
    };

    udisks2 = {
      enable = true;
      package = pkgs.udisks2;

      mountOnMedia = false;
    };

    fprintd = {
      enable = true;
      package = if config.services.fprintd.tod.enable then pkgs.fprintd-tod else pkgs.fprintd;
      # tod = {
      #   enable = true;
      #   driver = ;
      # };
    };

    pipewire = {
      enable = true;
      package = (
        pkgs.pipewire.override {
          enableSystemd = true;
          vulkanSupport = true;
          bluezSupport = true;
          zeroconfSupport = true;
          raopSupport = true;
          rocSupport = true;
        }
      );
      systemWide = false;

      audio.enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      socketActivation = true;

      wireplumber = {
        enable = true;
        package = (
          pkgs.wireplumber.override {
            enableDocs = true;
          }
        );

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
      phpPackage =
        (pkgs.php.override {
          cgiSupport = true;
          cliSupport = true;
          fpmSupport = true;
          pearSupport = true;
          pharSupport = true;
          phpdbgSupport = true;
          argon2Support = true;
          cgotoSupport = true;
          staticSupport = true;
          ipv6Support = true;
          zendSignalsSupport = true;
          zendMaxExecutionTimersSupport = false;
          systemdSupport = true;
          valgrindSupport = true;
          ztsSupport = true;
        }).buildEnv
          {
            extensions =
              {
                enabled,
                all,
              }:
              enabled
              ++ (with all; [
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
                session
                sockets
                sodium
                systemd
                xdebug
                xml
                xmlreader
                xmlwriter
                xsl
                zip
                zlib
              ]);

            extraConfig = config.services.phpfpm.phpOptions;
          };

      settings = {
        log_level = "warning";
      };

      phpOptions = ''
        default_charset = "UTF-8"
        error_reporting = E_ALL
        display_errors = Off
        log_errors = On
        cgi.force_redirect = 1
        expose_php = Off
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
        xdebug.mode=debug
      '';
    };

    avahi = {
      enable = true;
      package = (
        pkgs.avahi.override {
          gtk3Support = true;
        }
      );

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
      package = (
        pkgs.openssh.override {
          withPAM = true;
          linkOpenssl = true;
          isNixos = true;
        }
      );

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
      allowed-origins = [
        "*"
      ];

      settings = {
        WebService = {
          AllowUnencrypted = false;

          LoginTo = true;
          AllowMultiHost = true;
        };
      };

      openFirewall = true;
    };

    printing = {
      enable = true;
      package = (
        pkgs.cups.override {
          enableSystemd = true;
        }
      );

      drivers = with pkgs; [
        (gutenprint.override {
          cupsSupport = true;
        })
        gutenprintBin
        hplip
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

    saned = {
      enable = true;
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
      package = pkgs.postgresql_18_jit;

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
      package = pkgs.mariadb_118;

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

      virtualMapType = "pcre";
      aliasMapType = "pcre";
      enableHeaderChecks = true;

      setSendmail = true;

      settings = {
        main = {
          mydomain = config.networking.fqdn;
          myhostname = config.networking.fqdn;
          myorigin = config.networking.fqdn;
        };
      };
    };

    opendkim = {
      enable = true;

      domains = "csl:${config.networking.fqdn}";
      selector = "default";

      # settings = { };
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
    };

    icecast = {
      enable = true;

      hostname = config.networking.fqdn;
      listen = {
        address = "0.0.0.0";
        port = 17101;
      };

      user = "nobody";
      group = "nogroup";

      admin = {
        user = "bitscoper";
        password = secrets.password_1_of_bitscoper;
      };

      extraConf = ''
        <location>${config.networking.fqdn}</location>
        <admin>bitscoper@${config.networking.fqdn}</admin>
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
        <server-id>${config.networking.fqdn}</server-id>
      ''; # <loglevel>2</loglevel> = Warn

      logDir = "/var/log/icecast/";
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

    tailscale = {
      enable = true;
      package = pkgs.tailscale;

      disableTaildrop = false;

      port = 0; # 0 = Automatic
      openFirewall = true;
    };

    kubernetes = {
      package = pkgs.kubernetes;
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

      libraries =
        options.programs.nix-ld.libraries.default
        ++ (with pkgs; [
          glib.out
          llvmPackages.stdenv.cc.cc.lib
          stdenv.cc.cc.lib
        ]);
    };

    java = {
      enable = true;
      package = (
        pkgs.jdk25.override {
          enableGtk = true;
        }
      );

      binfmt = true;
    };

    appimage = {
      enable = true;
      package = (
        pkgs.appimage-run.override {
          extraPkgs =
            pkgs: with pkgs; [
              libepoxy
            ];
        }
      );

      binfmt = true;
    };

    xwayland.enable = true;

    bash = {
      blesh.enable = true;

      completion = {
        enable = true;
        package = pkgs.bash-completion;
      };

      enableLsColors = true;

      undistractMe = {
        enable = true;
        playSound = true;
      };

      # shellAliases = { };

      # loginShellInit = '''';
      # shellInit = '''';

      interactiveShellInit = ''
        PROMPT_COMMAND="history -a"
      '';
    };

    zoxide = {
      enable = true;
      package = (
        pkgs.zoxide.override {
          withFzf = true;
        }
      );

      enableBashIntegration = true;

      flags = [
        "--cmd cd"
      ];
    };

    direnv = {
      enable = true;
      package = pkgs.direnv;

      nix-direnv.enable = true;
      loadInNixShell = true;

      enableBashIntegration = true;

      silent = false;
    };

    nix-index = {
      package = pkgs.nix-index;

      enableBashIntegration = true;
    };

    gnupg = {
      package = (
        pkgs.gnupg.override {
          guiSupport = true;
          withTpm2Tss = true;
        }
      );

      agent = {
        enable = true;

        enableBrowserSocket = true;
        enableExtraSocket = true;
        enableSSHSupport = false;

        pinentryPackage = (
          pkgs.pinentry-gnome3.override {
            withLibsecret = true;
          }
        );
      };

      dirmngr.enable = true;
    };

    ssh = {
      package = (
        pkgs.openssh.override {
          withPAM = true;
          linkOpenssl = true;
          isNixos = true;
        }
      );

      startAgent = false; # `services.gnome.gcr-ssh-agent.enable' and `programs.ssh.startAgent' cannot both be enabled at the same time.
      agentTimeout = null;
    };

    git = {
      enable = true;
      package = (
        pkgs.gitFull.override {
          svnSupport = true;
          guiSupport = true;
          withManual = true;
          withpcre2 = true;
          sendEmailSupport = true;
          withLibsecret = true;
          withSsh = true;
        }
      );

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
          email = "bitscoper@protonmail.com";
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
        batgrep
        batdiff
        batman
        batpipe
        batwatch
        prettybat
      ];
    };

    gnome-disks.enable = true;
    system-config-printer.enable = true;
    seahorse.enable = true;
    calls.enable = true;
    geary.enable = true;

    firefox = {
      enable = true;
      package = pkgs.firefox-devedition;
      languagePacks = [
        "bn"
        "en-US"
      ];

      policies = {
        Extensions = {
          Install = [
            "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/gnome-shell-integration/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/languagetool/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/search_by_image/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/simple-mass-downloader/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/single-file/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/tab-disguiser/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/zjm-whatfont/latest.xpi"
          ];

          Locked = [
            "@testpilot-containers" # "Firefox Multi-Account Containers"
          ];
        };
      };

      # autoConfig = '''';

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

    obs-studio = {
      enable = true;
      package = (
        pkgs.obs-studio.override {
          scriptingSupport = true;
          alsaSupport = true;
          pulseaudioSupport = true;
          browserSupport = true;
          pipewireSupport = true;
          withFdk = true;
        }
      );

      enableVirtualCamera = true;

      plugins = with pkgs.obs-studio-plugins; [
        obs-3d-effect
        obs-backgroundremoval
        obs-composite-blur
        obs-gradient-source
        obs-gstreamer
        obs-move-transition
        obs-multi-rtmp
        obs-mute-filter
        obs-pipewire-audio-capture
        obs-scale-to-sound
        obs-source-clone
        obs-source-record
        obs-source-switcher
        obs-text-pthread
        obs-transition-table
        obs-vaapi
        obs-vkcapture
      ];
    };

    # ghidra = {
    #   enable = true;
    #   package = pkgs.ghidra;
    #   gdb = true;
    # }; # Build Failure

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

    virt-manager = {
      enable = true;
      package = (
        pkgs.virt-manager.override {
          spiceSupport = true;
        }
      );
    };

    dconf = {
      enable = true;
      profiles.user.databases = [
        {
          lockAll = true;

          settings = {
            "com/github/huluti/Curtail" = {
              file-attributes = true;
              metadata = false;
              new-file = true;
              recursive = true;
            };

            "com/github/tenderowl/frog" = {
              telemetry = false;
            };

            "io/gitlab/adhami3310/Converter" = {
              show-less-popular = true;
            };

            "io/github/amit9838/mousam" = {
              unit = "metric";
              use-24h-clock = false;
              use-gradient-bg = true;
            };

            "org/gnome/desktop/a11y/interface" = {
              show-status-shapes = true;
            };

            "org/gnome/desktop/a11y/keyboard" = {
              bouncekeys-enable = false;
              slowkeys-enable = false;
              stickykeys-enable = false;
              togglekeys-enable = true;
            };

            "org/gnome/desktop/a11y/mouse" = {
              dwell-click-enabled = false;
            };

            "org/gnome/desktop/background" = {
              picture-options = "zoom";
            };

            "org/gnome/desktop/calendar" = {
              show-weekdate = true;
            };

            "org/gnome/desktop/datetime" = {
              automatic-timezone = false;
            };

            "org/gnome/desktop/input-sources" = {
              per-window = false;
              show-all-sources = true;
              sources = with lib.gvariant; [
                (mkTuple [
                  "xkb"
                  "us"
                ])
                (mkTuple [
                  "xkb"
                  "bd"
                ])
                (mkTuple [
                  "xkb"
                  "ara"
                ])
                (mkTuple [
                  "xkb"
                  "ru"
                ])
                (mkTuple [
                  "ibus"
                  "OpenBangla"
                ])
              ];
            };

            "org/gnome/desktop/interface" = {
              clock-show-date = true;
              clock-show-seconds = true;
              clock-show-weekday = true;
              color-scheme = "prefer-dark";
              cursor-blink = true;
              document-font-name = "${font_preferences.name.sans_serif} 11";
              enable-animations = true;
              enable-hot-corners = true;
              font-antialiasing = "grayscale";
              font-hinting = "slight";
              gtk-enable-primary-paste = true;
              gtk-key-theme = "Default";
              locate-pointer = true;
              monospace-font-name = "${font_preferences.name.mono} 11";
              overlay-scrolling = true;
              show-battery-percentage = true;
              text-scaling-factor = 1.0;
            };

            "org/gnome/desktop/media-handling" = {
              autorun-never = false;
            };

            "org/gnome/desktop/notifications" = {
              show-in-lock-screen = true;
            };

            "org/gnome/desktop/peripherals/keyboard" = {
              repeat = true;
            };

            "org/gnome/desktop/peripherals/mouse" = {
              accel-profile = "default";
              left-handed = false;
              natural-scroll = false;
            };

            "org/gnome/desktop/peripherals/pointingstick" = {
              accel-profile = "default";
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

            "org/gnome/desktop/privacy" = {
              disable-camera = false;
              old-files-age = lib.gvariant.mkUint32 0;
              remember-app-usage = false;
              remember-recent-files = false;
              remove-old-temp-files = true;
              remove-old-trash-files = true;
              report-technical-problems = false;
              send-software-usage-stats = false;
              usb-protection = true;
            };

            "org/gnome/desktop/remote-desktop/rdp" = {
              view-only = false;
            };

            "org/gnome/desktop/search-providers" = {
              disable-external = false;
            };

            "org/gnome/desktop/sound" = {
              allow-volume-above-100-percent = true;
              event-sounds = true;
            };

            "org/gnome/desktop/screensaver" = {
              lock-delay = lib.gvariant.mkUint32 0;
              lock-enabled = true;
            };

            "org/gnome/desktop/session" = {
              idle-delay = lib.gvariant.mkUint32 0;
            };

            "org/gnome/desktop/wm/preferences" = {
              action-double-click-titlebar = "toggle-maximize";
              action-middle-click-titlebar = "toggle-maximize-vertically";
              action-right-click-titlebar = "menu";
              auto-raise = false;
              button-layout = "appmenu:minimize,maximize,close";
              focus-mode = "mouse";
              mouse-button-modifier = "<Super>";
              resize-with-right-button = true;
            };

            "org/gnome/file-roller/ui" = {
              view-sidebar = true;
            };

            "org/gnome/Geary" = {
              autoselect = false;
              display-preview = false;
              run-in-background = true;
              images-trusted-domains = [
                "*"
              ];
              optional-plugins = [
                "sent-sound"
                "email-templates"
                "mail-merge"
              ];
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

            "org/gnome/mutter" = {
              attach-modal-dialogs = false;
              center-new-windows = true;
              dynamic-workspaces = true;
              edge-tiling = true;
              workspaces-only-on-primary = true;
            };

            "org/gnome/nautilus/icon-view" = {
              captions = [
                "size"
                "date_modified"
                "none"
              ];
            };

            "org/gnome/nautilus/preferences" = {
              click-policy = "double";
              date-time-format = "simple";
              recursive-search = "always";
              show-create-link = true;
              show-delete-permanently = true;
              show-directory-item-counts = "always";
              show-image-thumbnails = "always";
            };

            "org/gnome/settings-daemon/plugins/media-keys" = {
              volume-step = lib.gvariant.mkInt32 1;
            };

            "org/gnome/settings-daemon/plugins/power" = {
              power-button-action = "interactive";
            };

            "org/gnome/shell" = {
              disable-user-extensions = false;
              enabled-extensions = with pkgs.gnomeExtensions; [
                appindicator.extensionUuid
                blur-my-shell.extensionUuid
                clipboard-indicator.extensionUuid
                desktop-cube.extensionUuid
                gsconnect.extensionUuid
                vitals.extensionUuid
                xwayland-indicator.extensionUuid
              ];
            };

            "org/gnome/shell/app-switcher" = {
              current-workspace-only = false;
            };

            "org/gnome/shell/extensions/appindicator" = {
              legacy-tray-enabled = true;
            };

            "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
              blur = true;
            };

            "org/gnome/shell/extensions/blur-my-shell/applications" = {
              blur = true;
            };

            "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
              blur = true;
            };

            "org/gnome/shell/extensions/blur-my-shell/overview" = {
              blur = true;
            };

            "org/gnome/shell/extensions/blur-my-shell/panel" = {
              blur = true;
            };

            "org/gnome/shell/extensions/clipboard-indicator" = {
              cache-images = true;
              cache-only-favorites = false;
              case-sensitive-search = false;
              clear-on-boot = false;
              confirm-clear = true;
              disable-down-arrow = true;
              keep-selected-on-clear = false;
              move-item-first = false;
              notify-on-copy = false;
              notify-on-cycle = true;
              paste-button = false;
              paste-on-select = false;
              pinned-on-bottom = false;
              regex-search = true;
              strip-text = false;
            };

            "org/gnome/shell/extensions/vitals" = {
              alphabetize = true;
              fixed-widths = false;
              hide-zeros = true;
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

            "org/gnome/system/location" = {
              enabled = true;
            };

            "org/gtk/settings/file-chooser" = {
              clock-format = "12h";
            };

            "org/gtk/gtk4/settings/file-chooser" = {
              sort-directories-first = true;
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

            "system/locale" = {
              region = "en_US.UTF-8";
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

      LD_LIBRARY_PATH = lib.mkForce "${
        pkgs.lib.makeLibraryPath (
          with pkgs;
          [
            sqlite
          ]
        )
      }:$LD_LIBRARY_PATH";
    };

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    shellAliases = {
      fetch_upgrade_data = "sudo nix-channel --update && sudo nix-env -u --always";

      upgrade = "sudo nix-channel --update && sudo nix-env -u --always && sudo nixos-rebuild switch --refresh --install-bootloader --upgrade-all";

      clean_upgrade = "sudo nix-channel --update && sudo nix-env -u --always && sudo rm -rf /nix/var/nix/gcroots/auto/* && sudo nix-env --delete-generations old && sudo nix-collect-garbage -d && sudo nix-store --gc && sudo nix-store --optimise && sudo nixos-rebuild switch --refresh --install-bootloader --upgrade-all";
    };

    # extraInit = '''';
    # loginShellInit = '''';
    # shellInit = '''';
    # interactiveShellInit = '''';

    systemPackages =
      with pkgs;
      [
        # autopsy # Build Failure
        # protonvpn-gui # Build Failure
        # reiser4progs # Marked Broken
        # winboat # Build Failure
        above
        acl
        acpidump-all
        addlicense
        agi # Cannot find libswt
        aircrack-ng
        alpaca
        android_sdk # Custom
        android-backup-extractor
        android-tools
        anydesk
        apfsprogs
        apkeep
        apkleaks
        arduino-cli
        arduino-ide
        arduino-language-server
        armitage
        audacity
        avrdude
        baobab
        bash-language-server
        bcachefs-tools
        binary
        binwalk
        bleachbit
        bluez-tools
        btop
        btrfs-assistant
        btrfs-progs
        bulk_extractor
        bustle
        butt
        cameractrls-gtk4
        celestia
        certbot-full
        clang
        clang-analyzer
        clang-tools
        clinfo
        cloc
        cmake
        cmake-language-server
        collision
        coppwr
        cramfsprogs
        cryptsetup
        ctop
        cups-filters
        cups-printers
        curtail
        cve-bin-tool
        d-spy
        darktable
        dart
        dbeaver-bin
        dconf-editor
        dconf2nix
        debase
        dig
        dive
        dmg2img
        dmidecode
        dnsrecon
        docker-compose
        docker-language-server
        dosfstools
        dropwatch
        e2fsprogs
        efibootmgr
        esptool
        evtest
        evtest-qt
        exfatprogs
        eyedropper
        f2fs-tools
        ffmpegthumbnailer
        fh
        file
        file-roller
        fileinfo
        filezilla
        flake-checker
        flare-floss
        flutter
        fontfor
        fragments
        freecad
        fritzing
        fstl
        gcc15
        gdb
        ghex
        gimp3-with-plugins
        git-filter-repo
        github-changelog-generator
        gnome-calculator
        gnome-calendar
        gnome-characters
        gnome-clocks
        gnome-connections
        gnome-console
        gnome-contacts
        gnome-decoder
        gnome-feeds
        gnome-firmware
        gnome-font-viewer
        gnome-frog
        gnome-graphs
        gnome-logs
        gnome-mahjongg
        gnome-multi-writer
        gnome-nettool
        gnome-network-displays
        gnome-power-manager
        gnome-system-monitor
        gnome-tecla
        gnome-tweaks
        gnomecast
        gnugrep
        gnumake
        gnused
        gnutar
        gource
        gparted
        gpredict
        guestfs-tools
        gzip
        hashcat
        hashcat-utils
        hashes
        hdparm
        hfsprogs
        hieroglyphic
        host
        hw-probe
        hydra-check
        i2c-tools
        iaito
        iftop
        impression
        indent
        inkscape-with-extensions
        inotify-tools
        input-leap
        iotop-c
        jfsutils
        jmol
        john
        johnny
        junction
        kernel-hardening-checker
        kernelshark
        killall
        kind
        kmod
        kubectl
        kubectl-graph
        kubectl-tree
        kubectl-view-secret
        kubernetes-helm
        letterpress
        libreoffice-fresh
        libva-utils
        linux-exploit-suggester
        linuxConsoleTools
        logdy
        logtop
        loupe
        lsb-release
        lshw
        lsof
        lsscsi
        lssecret
        lvm2
        lynis
        lyto
        macchanger
        mailcap
        massdns
        md-lsp
        meld
        metadata-cleaner
        metasploit
        mfcuk
        mfoc
        minikube
        mousam
        mtools
        mtr-gui
        nautilus
        nethogs
        nikto
        nilfs-utils
        ninja
        nix-diff
        nix-info
        nix-tour
        nixd
        nixfmt-rfc-style
        nixpkgs-lint
        nixpkgs-review
        nmap
        ntfs3g
        nucleus
        nvme-cli
        onionshare-gui
        openafs
        opendmarc
        openssl
        paper-clip
        papers
        pciutils
        pdfarranger
        pg_top
        pinta
        pkg-config
        platformio
        postgres-language-server
        profile-cleaner
        progress
        psmisc
        qemu-utils
        qr-backup
        radare2
        raider
        refine
        reiserfsprogs
        rpi-imager
        rpmextract
        rpPPPoE
        rtl-sdr-librtlsdr
        rtl-sdr-osmocom
        scrcpy
        screen
        sdrangel
        selectdefaultapplication
        serial-studio
        share-preview
        sherlock
        simple-scan
        sipvicious
        sleuthkit
        smartmontools
        sof-tools
        songrec
        soundconverter
        sox
        sslscan
        stegseek
        subfinder
        subtitleedit
        switcheroo
        symlinks
        systemd-lsp
        szyszka
        telegraph
        terminal-colors
        terminaltexteffects
        texliveFull
        time
        tpm2-tools
        traitor
        tree
        trufflehog
        udftools
        udiskie
        ugit
        universal-android-debloater # uad-ng
        unix-privesc-check
        unzip
        upnp-router-control
        upscayl
        usbip-ssh
        usbutils
        util-linux
        virt-top
        virt-v2v
        virtiofsd
        vulkan-caps-viewer
        vulkan-tools
        wafw00f
        waycheck
        waydroid-helper
        wayland-utils
        waylevel
        webfontkitgenerator
        wev
        whatfiles
        which
        whois
        wl-clipboard
        wordbook
        wpprobe
        x2goclient
        xdg-user-dirs
        xdg-utils
        xfsdump
        xfsprogs
        xfstests
        xoscope
        yaml-language-server
        yara-x
        zenity
        zenmap
        zfs
        zip
        (blender.override {
          colladaSupport = true;
          jackaudioSupport = true;
          openUsdSupport = true;
          spaceNavSupport = true;
          waylandSupport = true;
        })
        (coreutils-full.override {
          aclSupport = true;
          withOpenssl = true;
        })
        (curlFull.override {
          brotliSupport = true;
          c-aresSupport = true;
          gsaslSupport = true;
          gssSupport = true;
          http2Support = true;
          http3Support = true;
          websocketSupport = true;
          idnSupport = true;
          opensslSupport = true;
          pslSupport = true;
          rtmpSupport = true;
          scpSupport = true;
          zlibSupport = true;
          zstdSupport = true;
        })
        (ffmpeg-full.override {
          withAlsa = true;
          withAom = true;
          withAribb24 = true;
          withAribcaption = true;
          withAss = true;
          withAvisynth = true;
          withBluray = true;
          withBs2b = true;
          withBzlib = true;
          withCaca = true;
          withCdio = true;
          withCelt = true;
          withChromaprint = true;
          withCodec2 = true;
          withDav1d = true;
          withDavs2 = true;
          withDc1394 = true;
          withDrm = true;
          withDvdnav = true;
          withDvdread = true;
          withFlite = true;
          withFontconfig = true;
          withFreetype = true;
          withFrei0r = true;
          withFribidi = true;
          withGme = true;
          withGnutls = true;
          withGsm = true;
          withHarfbuzz = true;
          withIconv = true;
          withIlbc = true;
          withJack = true;
          withJxl = true;
          withKvazaar = true;
          withLadspa = true;
          withLc3 = true;
          withLcevcdec = true;
          withLcms2 = true;
          withLzma = true;
          withModplug = true;
          withMp3lame = true;
          withMysofa = true;
          withOpenal = true;
          withOpencl = true;
          withOpencoreAmrnb = true;
          withOpencoreAmrwb = true;
          withOpengl = true;
          withOpenh264 = true;
          withOpenjpeg = true;
          withOpenmpt = true;
          withOpus = true;
          withPlacebo = true;
          withPulse = true;
          withQrencode = true;
          withQuirc = true;
          withRav1e = true;
          withRist = true;
          withRtmp = true;
          withRubberband = true;
          withSamba = true;
          withSdl2 = true;
          withShaderc = true;
          withShine = true;
          withSnappy = true;
          withSoxr = true;
          withSpeex = true;
          withSrt = true;
          withSsh = true;
          withSvg = true;
          withSvtav1 = true;
          withTheora = true;
          withTwolame = true;
          withUavs3d = true;
          withV4l2 = true;
          withV4l2M2m = true;
          withVaapi = true;
          withVdpau = true;
          withVidStab = true;
          withVmaf = true;
          withVoAmrwbenc = true;
          withVorbis = true;
          withVpx = true;
          withVulkan = true;
          withVvenc = true;
          withWebp = true;
          withX264 = true;
          withX265 = true;
          withXavs = true;
          withXavs2 = true;
          withXevd = true;
          withXeve = true;
          withXml2 = true;
          withXvid = true;
          withZimg = true;
          withZlib = true;
          withZmq = true;
          withZvbi = true;

          withUnfree = false;

          withGrayscale = true;
          withSwscaleAlpha = true;
          withMultithread = true;
          withNetwork = true;
        })
        (hardinfo2.override {
          printingSupport = true;
        })
        (kicad.override {
          addons = with pkgs.kicadAddons; [
            kikit
            kikit-library
          ];
          stable = true;
          withNgspice = true;
          withScripting = true;
          with3d = true;
          withI18n = true;
        })
        (python314.override {
          bluezSupport = true;
          mimetypesSupport = true;
          withReadline = true;
        })
        (sdrpp.override {
          airspy_source = true;
          airspyhf_source = true;
          bladerf_source = true;
          file_source = true;
          hackrf_source = true;
          limesdr_source = true;
          plutosdr_source = true;
          rfspace_source = true;
          rtl_sdr_source = true;
          rtl_tcp_source = true;
          soapy_source = true;
          spyserver_source = true;
          usrp_source = true;

          audio_sink = true;
          network_sink = true;
          portaudio_sink = true;

          m17_decoder = true;
          meteor_demodulator = true;

          frequency_manager = true;
          recorder = true;
          rigctl_server = true;
          scanner = true;
        })
        (tor-browser.override {
          libnotifySupport = true;
          waylandSupport = true;
          mediaSupport = true;
          audioSupport = true;
          pipewireSupport = true;
          pulseaudioSupport = true;
          libvaSupport = true;
        })
        (virt-viewer.override {
          spiceSupport = true;
        })
        (vlc.override {
          chromecastSupport = true;
          jackSupport = true;
          skins2Support = true;
          waylandSupport = true;
        })
        (wget.override {
          withLibpsl = true;
          withOpenssl = true;
        })
        config.services.phpfpm.phpPackage
      ]
      ++ config.boot.extraModulePackages
      # ++ (with ghidra-extensions; [
      #   findcrypt
      #   ghidra-delinker-extension
      #   ghidra-golanganalyzerextension
      #   ghidraninja-ghidra-scripts
      #   gnudisassembler
      #   lightkeeper
      #   machinelearning
      #   ret-sync
      #   sleighdevtools
      #   wasm
      # ]) # Build Failure
      ++ (with gnomeExtensions; [
        appindicator
        blur-my-shell
        clipboard-indicator
        desktop-cube
        gsconnect
        vitals
        xwayland-indicator
      ])
      ++ (with gst_all_1; [
        (gst-libav.override {
          enableDocumentation = true;
        })
        (gst-plugins-bad.override {
          enableZbar = true;
          opencvSupport = true;
          ldacbtSupport = true;
          webrtcAudioProcessingSupport = true;
          ajaSupport = true;
          openh264Support = true;
          enableGplPlugins = true;
          bluezSupport = true;
          microdnsSupport = true;
          enableDocumentation = true;
          guiSupport = true;
        })
        (gst-plugins-base.override {
          enableWayland = true;
          enableAlsa = true;
          enableCdparanoia = true;
          enableDocumentation = true;
        })
        (gst-plugins-good.override {
          gtkSupport = true;
          qt6Support = true;
          enableJack = true;
          enableWayland = true;
          enableDocumentation = true;
        })
        (gst-plugins-ugly.override {
          enableGplPlugins = true;
          enableDocumentation = true;
        })
        (gst-vaapi.override {
          enableDocumentation = true;
        })
        (gstreamer.override {
          enableDocumentation = true;
        })
      ])
      ++ (with texlivePackages; [
        latexmk
      ])
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
      ]);

    gnome.excludePackages = (
      with pkgs;
      [
        decibels
        epiphany
        gnome-maps
        gnome-music
        gnome-text-editor
        gnome-tour
        gnome-weather
        showtime
        snapshot
        totem
        yelp
      ]
    );
  };

  xdg = {
    mime = {
      enable = true;

      addedAssociations = config.xdg.mime.defaultApplications;

      # removedAssociations = { };

      # https://www.iana.org/assignments/media-types/media-types.xhtml
      defaultApplications = {
        "inode/directory" = "nautilus.desktop";

        "text/1d-interleaved-parityfec" = "codium.desktop";
        "text/cache-manifest" = "codium.desktop";
        "text/calendar" = "codium.desktop";
        "text/cql-expression" = "codium.desktop";
        "text/cql-identifier" = "codium.desktop";
        "text/cql" = "codium.desktop";
        "text/css" = "codium.desktop";
        "text/csv-schema" = "codium.desktop";
        "text/csv" = "codium.desktop";
        "text/dns" = "codium.desktop";
        "text/encaprtp" = "codium.desktop";
        "text/enriched" = "codium.desktop";
        "text/example" = "codium.desktop";
        "text/fhirpath" = "codium.desktop";
        "text/flexfec" = "codium.desktop";
        "text/fwdred" = "codium.desktop";
        "text/gff3" = "codium.desktop";
        "text/grammar-ref-list" = "codium.desktop";
        "text/hl7v2" = "codium.desktop";
        "text/html" = "codium.desktop";
        "text/javascript" = "codium.desktop";
        "text/jcr-cnd" = "codium.desktop";
        "text/markdown" = "codium.desktop";
        "text/mizar" = "codium.desktop";
        "text/n3" = "codium.desktop";
        "text/parameters" = "codium.desktop";
        "text/parityfec" = "codium.desktop";
        "text/plain" = "codium.desktop";
        "text/provenance-notation" = "codium.desktop";
        "text/prs.fallenstein.rst" = "codium.desktop";
        "text/prs.lines.tag" = "codium.desktop";
        "text/prs.prop.logic" = "codium.desktop";
        "text/prs.texi" = "codium.desktop";
        "text/raptorfec" = "codium.desktop";
        "text/RED" = "codium.desktop";
        "text/rfc822-headers" = "codium.desktop";
        "text/richtext" = "codium.desktop";
        "text/rtf" = "codium.desktop";
        "text/rtp-enc-aescm128" = "codium.desktop";
        "text/rtploopback" = "codium.desktop";
        "text/rtx" = "codium.desktop";
        "text/SGML" = "codium.desktop";
        "text/shaclc" = "codium.desktop";
        "text/shex" = "codium.desktop";
        "text/spdx" = "codium.desktop";
        "text/strings" = "codium.desktop";
        "text/t140" = "codium.desktop";
        "text/tab-separated-values" = "codium.desktop";
        "text/troff" = "codium.desktop";
        "text/turtle" = "codium.desktop";
        "text/ulpfec" = "codium.desktop";
        "text/uri-list" = "codium.desktop";
        "text/vcard" = "codium.desktop";
        "text/vnd.a" = "codium.desktop";
        "text/vnd.abc" = "codium.desktop";
        "text/vnd.ascii-art" = "codium.desktop";
        "text/vnd.curl" = "codium.desktop";
        "text/vnd.debian.copyright" = "codium.desktop";
        "text/vnd.DMClientScript" = "codium.desktop";
        "text/vnd.dvb.subtitle" = "codium.desktop";
        "text/vnd.esmertec.theme-descriptor" = "codium.desktop";
        "text/vnd.exchangeable" = "codium.desktop";
        "text/vnd.familysearch.gedcom" = "codium.desktop";
        "text/vnd.ficlab.flt" = "codium.desktop";
        "text/vnd.fly" = "codium.desktop";
        "text/vnd.fmi.flexstor" = "codium.desktop";
        "text/vnd.gml" = "codium.desktop";
        "text/vnd.graphviz" = "codium.desktop";
        "text/vnd.hans" = "codium.desktop";
        "text/vnd.hgl" = "codium.desktop";
        "text/vnd.in3d.3dml" = "codium.desktop";
        "text/vnd.in3d.spot" = "codium.desktop";
        "text/vnd.IPTC.NewsML" = "codium.desktop";
        "text/vnd.IPTC.NITF" = "codium.desktop";
        "text/vnd.latex-z" = "codium.desktop";
        "text/vnd.motorola.reflex" = "codium.desktop";
        "text/vnd.ms-mediapackage" = "codium.desktop";
        "text/vnd.net2phone.commcenter.command" = "codium.desktop";
        "text/vnd.radisys.msml-basic-layout" = "codium.desktop";
        "text/vnd.senx.warpscript" = "codium.desktop";
        "text/vnd.sosi" = "codium.desktop";
        "text/vnd.sun.j2me.app-descriptor" = "codium.desktop";
        "text/vnd.trolltech.linguist" = "codium.desktop";
        "text/vnd.typst" = "codium.desktop";
        "text/vnd.vcf" = "codium.desktop";
        "text/vnd.wap.si" = "codium.desktop";
        "text/vnd.wap.sl" = "codium.desktop";
        "text/vnd.wap.wml" = "codium.desktop";
        "text/vnd.wap.wmlscript" = "codium.desktop";
        "text/vnd.zoo.kcl" = "codium.desktop";
        "text/vtt" = "codium.desktop";
        "text/wgsl" = "codium.desktop";
        "text/xml-external-parsed-entity" = "codium.desktop";
        "text/xml" = "codium.desktop";

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
        "image/heic-sequence" = "org.gnome.Loupe.desktop";
        "image/heic" = "org.gnome.Loupe.desktop";
        "image/heif-sequence" = "org.gnome.Loupe.desktop";
        "image/heif" = "org.gnome.Loupe.desktop";
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
        "image/tiff-fx" = "org.gnome.Loupe.desktop";
        "image/tiff" = "org.gnome.Loupe.desktop";
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

        "audio/1d-interleaved-parityfec" = "vlc.desktop";
        "audio/32kadpcm" = "vlc.desktop";
        "audio/3gpp" = "vlc.desktop";
        "audio/3gpp2" = "vlc.desktop";
        "audio/aac" = "vlc.desktop";
        "audio/ac3" = "vlc.desktop";
        "audio/AMR-WB" = "vlc.desktop";
        "audio/amr-wb+" = "vlc.desktop";
        "audio/AMR" = "vlc.desktop";
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
        "audio/EVRC-QCP" = "vlc.desktop";
        "audio/EVRC" = "vlc.desktop";
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
        "audio/flac" = "vlc.desktop";
        "audio/flexfec" = "vlc.desktop";
        "audio/fwdred" = "vlc.desktop";
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
        "audio/GSM-EFR" = "vlc.desktop";
        "audio/GSM-HR-08" = "vlc.desktop";
        "audio/GSM" = "vlc.desktop";
        "audio/iLBC" = "vlc.desktop";
        "audio/ip-mr_v2.5" = "vlc.desktop";
        "audio/L16" = "vlc.desktop";
        "audio/L20" = "vlc.desktop";
        "audio/L24" = "vlc.desktop";
        "audio/L8" = "vlc.desktop";
        "audio/LPC" = "vlc.desktop";
        "audio/matroska" = "vlc.desktop";
        "audio/MELP" = "vlc.desktop";
        "audio/MELP1200" = "vlc.desktop";
        "audio/MELP2400" = "vlc.desktop";
        "audio/MELP600" = "vlc.desktop";
        "audio/mhas" = "vlc.desktop";
        "audio/midi-clip" = "vlc.desktop";
        "audio/mobile-xmf" = "vlc.desktop";
        "audio/mp4" = "vlc.desktop";
        "audio/MP4A-LATM" = "vlc.desktop";
        "audio/mpa-robust" = "vlc.desktop";
        "audio/MPA" = "vlc.desktop";
        "audio/mpeg" = "vlc.desktop";
        "audio/mpeg4-generic" = "vlc.desktop";
        "audio/ogg" = "vlc.desktop";
        "audio/opus" = "vlc.desktop";
        "audio/parityfec" = "vlc.desktop";
        "audio/PCMA-WB" = "vlc.desktop";
        "audio/PCMA" = "vlc.desktop";
        "audio/PCMU-WB" = "vlc.desktop";
        "audio/PCMU" = "vlc.desktop";
        "audio/prs.sid" = "vlc.desktop";
        "audio/QCELP" = "vlc.desktop";
        "audio/raptorfec" = "vlc.desktop";
        "audio/RED" = "vlc.desktop";
        "audio/rtp-enc-aescm128" = "vlc.desktop";
        "audio/rtp-midi" = "vlc.desktop";
        "audio/rtploopback" = "vlc.desktop";
        "audio/rtx" = "vlc.desktop";
        "audio/scip" = "vlc.desktop";
        "audio/SMV-QCP" = "vlc.desktop";
        "audio/SMV" = "vlc.desktop";
        "audio/SMV0" = "vlc.desktop";
        "audio/sofa" = "vlc.desktop";
        "audio/sp-midi" = "vlc.desktop";
        "audio/speex" = "vlc.desktop";
        "audio/t140c" = "vlc.desktop";
        "audio/t38" = "vlc.desktop";
        "audio/telephone-event" = "vlc.desktop";
        "audio/TETRA_ACELP_BB" = "vlc.desktop";
        "audio/TETRA_ACELP" = "vlc.desktop";
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
        "audio/vnd.dts.hd" = "vlc.desktop";
        "audio/vnd.dts.uhd" = "vlc.desktop";
        "audio/vnd.dts" = "vlc.desktop";
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
        "audio/vnd.rhetorex.32kadpcm" = "vlc.desktop";
        "audio/vnd.rip" = "vlc.desktop";
        "audio/vnd.sealedmedia.softseal.mpeg" = "vlc.desktop";
        "audio/vnd.vmx.cvsd" = "vlc.desktop";
        "audio/vorbis-config" = "vlc.desktop";
        "audio/vorbis" = "vlc.desktop";

        "video/1d-interleaved-parityfec" = "vlc.desktop";
        "video/3gpp-tt" = "vlc.desktop";
        "video/3gpp" = "vlc.desktop";
        "video/3gpp2" = "vlc.desktop";
        "video/AV1" = "vlc.desktop";
        "video/BMPEG" = "vlc.desktop";
        "video/BT656" = "vlc.desktop";
        "video/CelB" = "vlc.desktop";
        "video/DV" = "vlc.desktop";
        "video/encaprtp" = "vlc.desktop";
        "video/evc" = "vlc.desktop";
        "video/FFV1" = "vlc.desktop";
        "video/flexfec" = "vlc.desktop";
        "video/H261" = "vlc.desktop";
        "video/H263-1998" = "vlc.desktop";
        "video/H263-2000" = "vlc.desktop";
        "video/H263" = "vlc.desktop";
        "video/H264-RCDO" = "vlc.desktop";
        "video/H264-SVC" = "vlc.desktop";
        "video/H264" = "vlc.desktop";
        "video/H265" = "vlc.desktop";
        "video/H266" = "vlc.desktop";
        "video/iso.segment" = "vlc.desktop";
        "video/JPEG" = "vlc.desktop";
        "video/jpeg2000" = "vlc.desktop";
        "video/jxsv" = "vlc.desktop";
        "video/matroska-3d" = "vlc.desktop";
        "video/matroska" = "vlc.desktop";
        "video/mj2" = "vlc.desktop";
        "video/MP1S" = "vlc.desktop";
        "video/MP2P" = "vlc.desktop";
        "video/MP2T" = "vlc.desktop";
        "video/mp4" = "vlc.desktop";
        "video/MP4V-ES" = "vlc.desktop";
        "video/mpeg" = "vlc.desktop";
        "video/mpeg4-generic" = "vlc.desktop";
        "video/MPV" = "vlc.desktop";
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
        "video/vnd.directv.mpeg-tts" = "vlc.desktop";
        "video/vnd.directv.mpeg" = "vlc.desktop";
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
        "video/VP8" = "vlc.desktop";
        "video/VP9" = "vlc.desktop";
        "video/x-matroska" = "vlc.desktop"; # https://mime.wcode.net/mkv

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

        "x-scheme-handler/mailto" = "org.gnome.Geary.desktop";
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
        xdg-desktop-portal-gtk
      ];

      xdgOpenUsePortal = false; # Opening Programs

      config = {
        common = {
          default = [
            "gnome"
            "gtk"
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

    platformTheme = "gnome";
    style = "adwaita-dark";
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
      hardinfo2 = { };
    };

    enforceIdUniqueness = true;
    mutableUsers = true;

    defaultUserShell = pkgs.bash;

    motd = "Welcome";

    users.bitscoper = {
      isNormalUser = true;

      name = "bitscoper";
      description = "Abdullah As-Sadeed"; # Full Name

      extraGroups = [
        "adbusers"
        "audio"
        "dialout"
        "docker"
        "hardinfo2"
        "input"
        "jellyfin"
        "kvm"
        "libvirtd"
        "lp"
        "networkmanager"
        "plugdev"
        "qemu-libvirtd"
        "scanner"
        "seat"
        "tty"
        "uucp"
        "video"
        "wheel"
        "wireshark"
      ];

      useDefaultShell = true;
    };
  };

  gtk.iconCache.enable = true;

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
          };

          pointerCursor = {
            name = cursor.theme.name;
            package = cursor.theme.package;

            gtk.enable = true;
          };

          preferXdgDirectories = true;

          # sessionSearchVariables = { };

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
            name = "Adwaita-dark";
            package = pkgs.gnome-themes-extra;
          };

          iconTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
          };

          cursorTheme = {
            name = cursor.theme.name;
            package = cursor.theme.package;
          };

          font = {
            name = font_preferences.name.sans_serif;
            package = font_preferences.package;
          };
        };

        qt = {
          enable = true;

          platformTheme.name = "adwaita";
          style.name = "adwaita-dark";
        };

        services = {
        };

        programs = {
          dircolors = {
            enable = true;
            package = (
              pkgs.coreutils-full.override {
                aclSupport = true;
                withOpenssl = true;
              }
            );

            enableBashIntegration = true;
          };

          kubecolor = {
            enable = true;
            package = pkgs.kubecolor;

            enableAlias = true;

            settings = {
              kubectl = pkgs.lib.getExe pkgs.kubectl;
              preset = "dark";
            };
          };

          gradle = {
            enable = true;
            package = pkgs.gradle;
          };

          matplotlib = {
            enable = true;

            config = {
              axes = {
                grid = true;
              };
            };
          };

          keepassxc = {
            enable = true;
            package = (
              pkgs.keepassxc.override {
                withKeePassBrowser = true;
                withKeePassBrowserPasskeys = true;
                withKeePassFDOSecrets = true;
                withKeePassKeeShare = true;
                withKeePassNetworking = true;
                withKeePassSSHAgent = true;
                withKeePassYubiKey = true;
              }
            );

            # settings = { };
          };

          gh = {
            enable = true;
            package = pkgs.gh;
            extensions = with pkgs; [
              gh-contribs
              gh-notify
              gh-skyline
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

              # aliases = { };
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

            # credentials = { };
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
                    antfu.slidev
                    anweber.vscode-httpyac
                    arrterian.nix-env-selector
                    bierner.color-info
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
                    cweijan.vscode-database-client2
                    dart-code.dart-code
                    dart-code.flutter
                    davidanson.vscode-markdownlint
                    dendron.adjust-heading-level
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
                    james-yu.latex-workshop
                    jbockle.jbockle-format-files
                    jellyedwards.gitsweep
                    jkillian.custom-local-formatters
                    jnoortheen.nix-ide
                    jock.svg
                    llvm-vs-code-extensions.vscode-clangd
                    lokalise.i18n-ally
                    mads-hartmann.bash-ide-vscode
                    mechatroner.rainbow-csv
                    meganrogge.template-string-converter
                    mishkinf.goto-next-previous-member
                    mkhl.direnv
                    moshfeu.compare-folders
                    ms-azuretools.vscode-containers
                    ms-azuretools.vscode-docker
                    ms-kubernetes-tools.vscode-kubernetes-tools
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
                    ms-vscode.anycode
                    ms-vscode.cmake-tools
                    ms-vscode.cpptools # Unfree
                    ms-vscode.hexeditor
                    ms-vscode.live-server
                    ms-vscode.makefile-tools
                    ms-vscode.test-adapter-converter
                    njpwerner.autodocstring
                    oderwat.indent-rainbow
                    piousdeer.adwaita-theme
                    platformio.platformio-vscode-ide
                    quicktype.quicktype
                    redhat.vscode-xml
                    redhat.vscode-yaml
                    rioj7.commandonallfiles
                    rubymaniac.vscode-paste-and-indent
                    ryu1kn.partial-diff
                    sanaajani.taskrunnercode
                    shardulm94.trailing-spaces
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
                    vspacecode.whichkey
                    wmaurer.change-case
                    xdebug.php-debug
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
                      version = "0.13.251103001";
                      sha256 = "Mq6h49v5jgM6HR1fgLH82uv3HrqBpxf6ru+l0uoIo/c=";
                    }
                  ];

                enableUpdateCheck = true;
                enableExtensionUpdateCheck = true;

                # userSettings = { };
              };
            };
          };

          yt-dlp = {
            enable = true;
            package = (
              pkgs.yt-dlp.override {
                atomicparsleySupport = true;
                ffmpegSupport = true;
                rtmpSupport = true;
                withAlias = true;
              }
            );

            settings = {
              no-embed-thumbnail = true;
            };
          };
        };
      }
    ];

    users.root = { };
    users.bitscoper = { };

    verbose = true;
  };
}

# FIXME: 05ac-033e-Gamepad > Rumble
# FIXME: Cockpit > Login
# FIXME: ELAN7001 SPI Fingerprint Sensor
# FIXME: MariaDB > Login
