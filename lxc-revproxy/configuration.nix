{ modulesPath, config, pkgs, ... }:

let
  PATH = "/etc/nginx/ssl";
  CERTIFICATE = "${PATH}/fullchain.pem";
  CERTIFICATE_KEY = "${PATH}/privkey.pem";
in

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
    hostName = "lxc-revproxy";
    useDHCP = false;
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = "192.168.10.11";
          prefixLength = 32;
        }
      ];
    };

    defaultGateway = {
      address = "192.168.10.1";
      interface = "eth0";
    };

    nameservers = [
      "192.168.10.10"
    ];

    networkmanager = {
      enable = true;
    };

    firewall = {
      enable = true;
      allowedUDPPorts = [ 80 443 ];
      allowedTCPPorts = [ 80 443 ];
    };
  };

  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_US.UTF-8";

  users = {
    users = {
      nginx = {
        home = "/var/lib/nginx";
        createHome = true;
        isSystemUser = true;
        group = "nginx";
      };
    };

    groups = {
      nginx = {
        members = [ "nginx" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    dig
    nginx
    certbot
  ];

  services.nginx = {
    enable = true;
    user = "nginx";
    group = "nginx";
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "media.lan.d35c.net" = {
        forceSSL = true;
        sslCertificate = CERTIFICATE;
        sslCertificateKey = CERTIFICATE_KEY;
        locations."/" = {
          proxyPass = "http://192.168.10.23:8096";
        };
      };
      "bookmarks.lan.d35c.net" = {
        forceSSL = true;
        sslCertificate = CERTIFICATE;
        sslCertificateKey = CERTIFICATE_KEY;
        locations."/" = {
          proxyPass = "http://192.168.10.30:8080";
        };
      };
      "bucket.lan.d35c.net" = {
        forceSSL = true;
        sslCertificate = CERTIFICATE;
        sslCertificateKey = CERTIFICATE_KEY;
        locations."/" = {
          proxyPass = "http://192.168.10.26:5000";
        };
      };
      "r2.lan.d35c.net" = {
        locations."/" = {
          proxyPass = "http://192.168.10.22:8006";
        };
      };
      "assistant.lan.d35c.net" = {
        locations."/" = {
          proxyPass = "http://192.168.20.25:8123";
        };
      };
      "explorer.lan.d35c.net" = {
        locations."/" = {
          proxyPass = "http://192.168.10.31:4000/";
        };
      };
    };
  };

  # supress systemd units that don't work because of LXC
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  system.stateVersion = "24.05";
}