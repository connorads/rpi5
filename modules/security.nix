# Hardened SSH + fail2ban for internet-facing NixOS servers.
{ ... }:
{
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;
      MaxAuthTries = 3;
      LoginGraceTime = 20;
      AllowTcpForwarding = false;
      AllowAgentForwarding = true;
      X11Forwarding = false;
    };
  };

  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h";
    };
  };
}
