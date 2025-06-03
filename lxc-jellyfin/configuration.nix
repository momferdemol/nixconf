{ modulesPath, config, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  boot.isContainer = true;

  boot.kernelParams = [ "i915.force_probe=46d0" ];

  nixpkgs.config.allowUnfree = true;

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      # vpl-gpu-rt          # for newer GPUs on NixOS >24.05 or unstable
      onevpl-intel-gpu  # for newer GPUs on NixOS <= 24.05
    ];
  };

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
    hostName = "lxc-jellfyin";
    networkmanager = {
      enable = true;
    };
    firewall = {
      enable = false;
    };
  };

  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_US.UTF-8";

  users = {
    users = {
      jellyfin = {
        home = "/var/lib/jellyfin";
        createHome = true;
        isSystemUser = true;
        group = "jellyfin";
        extraGroups = [ "render" "video" ];
      };
    };

    groups = {
      jellyfin = {
        members = [ "jellyfin" ];
      };
      synology = {
        gid = 10000;
        members = [ "jellyfin" ];
      };
      passcard = {
        gid = 44;
        members = [ "jellyfin" ];
      };
      passrender = {
        gid = 104;
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
    intel-gpu-tools
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

  system.stateVersion = "24.05";
}