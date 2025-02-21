{ modulesPath, config, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  boot.isContainer = true;

  nixpkgs.config.allowUnfree = true;

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "Monday 04:00 UTC";
    rebootWindow = {
      lower = "04:00";
      upper = "06:00";
    };
  };

  nix.gc = {
    automatic = true;
    dates = "Monday 07:00 UTC";
    options = "--delete-older-than 7d";
  };

  # Run garbage collection whenever there is less than 500MB free space left
  nix.extraOptions = ''
    min-free = ${toString (500 * 1024 * 1024)}
  '';

  # clean up system logs old then 1 month
  systemd = {
    services.clear-log = {
      description = "clean 30+ old logs every week";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=30d";
      };
    };
    timers.clear-log = {
      wantedBy = [ "timers.target" ];
      partOf = [ "clear-log.service" ];
      timerConfig.OnCalendar = "weekly UTC";
    };
  };

  networking = {
    hostName = "lxc-unbound";
    useDHCP = false;
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = "192.168.10.10";
          prefixLength = 32;
        }
      ];
    };

    defaultGateway = {
      address = "192.168.10.1";
      interface = "eth0";
    };

    networkmanager = {
      enable = true;
    };

    firewall = {
      enable = true;
      allowedUDPPorts = [ 53 ];
      allowedTCPPorts = [ 53 ];
    };
  };

  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_US.UTF-8";

  users = {
    users = {
      unbound = {
        home = "/var/lib/unbound";
        createHome = true;
        isSystemUser = true;
        group = "unbound";
      };
    };

    groups = {
      unbound = {
        members = [ "unbound" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    dig
    unbound
  ];

  services.unbound = {
    enable = true;
    user = "unbound";
    group = "unbound";
    settings = {
      server = {
        verbosity = 1;
        auto-trust-anchor-file = "/var/lib/unbound/root.key";
        qname-minimisation = true;
        interface = "0.0.0.0";
        access-control = "192.168.0.0/16 allow";
        private-domain = "lan.d35c.net";
        local-zone = "\"lan.d35c.net.\" static";
        local-data = [
          "\"media.lan.d35c.net.\tIN A 192.168.10.11\""
          "\"bookmarks.lan.d35c.net.\tIN A 192.168.10.11\""
          "\"bucket.lan.d35c.net.\tIN A 192.168.10.11\""
          "\"r2.lan.d35c.net.\tIN A 192.168.10.11\""
          "\"assistant.lan.d35c.net.\tIN A 192.168.10.11\""
          "\"explorer.lan.d35c.net.\tIN A 192.168.10.11\""
        ];
      };

      forward-zone = [
        {
          name = ".";
          forward-addr = [
            "1.1.1.1"
            "9.9.9.9"
          ];
        }
      ];

      remote-control = {
        control-enable = false;
      };
    };
    enableRootTrustAnchor = true;
  };

  # supress systemd units that don't work because of LXC
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  system.stateVersion = "24.05";
}