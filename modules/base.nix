# Reusable NixOS baseline for all Connor's servers.
# Host-specific config (hardware, networking, services) goes in configuration.nix.
{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "connor"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  time.timeZone = "Europe/London";
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    ncdu
    kitty.terminfo
  ];
}
