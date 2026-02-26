# Raspberry Pi 5 — host-specific NixOS configuration.
# Reusable baseline (nix settings, GC, zsh, system pkgs) is in modules/base.nix.
# SSH hardening + fail2ban is in modules/security.nix.
# User environment (shell, tools, git, tmux, etc.) comes from dotfiles (hms).
{
  config,
  pkgs,
  lib,
  ...
}:

{
  system.stateVersion = "24.11";

  # ==========================================================================
  # Bootloader
  # ==========================================================================
  boot.loader.raspberry-pi.bootloader = "kernel";

  # ==========================================================================
  # Networking
  # ==========================================================================
  networking = {
    hostName = "rpi5";
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]; # SSH open for local access
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };

  # ==========================================================================
  # Cachix (nixos-raspberrypi binary cache for kernel builds)
  # ==========================================================================
  nix.settings = {
    substituters = [ "https://nixos-raspberrypi.cachix.org" ];
    trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  # ==========================================================================
  # User
  # ==========================================================================
  users.users.connor = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "docker"
    ];
    # Fetch SSH keys from GitHub (update sha256 when keys change: nix-prefetch-url https://github.com/connorads.keys)
    openssh.authorizedKeys.keys =
      let
        githubKeys = builtins.fetchurl {
          url = "https://github.com/connorads.keys";
          sha256 = "1alzqm1lijavww9rlrj7dy876jy50dfx0v3f4a813kyxz1273yi1";
        };
        parts = builtins.split "\n" (builtins.readFile githubKeys);
      in
      builtins.filter (k: builtins.isString k && k != "") parts;
    linger = true; # Keep user services after logout (for Docker)
  };

  # ==========================================================================
  # Tailscale (manual auth — ssh in, run: sudo tailscale up)
  # ==========================================================================
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--operator=connor"
      "--hostname=rpi5"
    ];
  };

  # ==========================================================================
  # Automatic Updates (pulls from GitHub daily, rebuilds if changed)
  # ==========================================================================
  system.autoUpgrade = {
    enable = true;
    flake = "github:connorads/rpi5#rpi5";
    flags = [
      "--refresh"
      "--print-build-logs"
    ];
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = true;
    rebootWindow = {
      lower = "03:00";
      upper = "06:00";
    };
  };

  # ==========================================================================
  # Docker (rootless)
  # ==========================================================================
  virtualisation.docker = {
    enable = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  security.unprivilegedUsernsClone = true;

  # ==========================================================================
  # Filesystems (labels set by nixos-raspberrypi image)
  # ==========================================================================
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
  };
}
