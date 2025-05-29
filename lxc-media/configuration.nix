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
    hostName = "lxc-media";
    useDHCP = true;
    # interfaces.eth0 = {
    #   ipv4.addresses = [
    #     {
    #       address = "192.168.10.10";
    #       prefixLength = 32;
    #     }
    #   ];
    # };

    defaultGateway = {
      address = "192.168.10.1";
      interface = "eth0";
    };

    networkmanager = {
      enable = true;
    };

    # firewall = {
    #   enable = true;
    #   allowedUDPPorts = [ 53 ];
    #   allowedTCPPorts = [ 53 ];
    # };
  };

  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_US.UTF-8";

  users = {
    users = {
      unbound = {
        home = "/var/lib/jellyfin";
        createHome = true;
        isSystemUser = true;
        group = "jellyfin";
      };
    };

    groups = {
      unbound = {
        members = [ "jellyfin" ];
      };
    };
  };

  programs.bash = {
    loginShellInit = ''
      ${pkgs.fastfetch}/bin/fastfetch
    '';
  };

  environment.systemPackages = with pkgs; [
    fastfetch
    dig
    cifs-utils
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    libva-utils
  ];

  services.jellyfin = {
    enable = true;
  };

  # supress systemd units that don't work because of LXC
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  system.stateVersion = "25.05";
}