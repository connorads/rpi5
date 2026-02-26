# NixOS on Raspberry Pi 5

## Overview

This repo owns the **NixOS system config** for the Pi 5 — hardware, networking, SSH, Tailscale, auto-upgrade, Docker.

**User environment** (shell, tools, git, tmux, starship, etc.) comes from [dotfiles](https://github.com/connorads/dotfiles) via standalone home-manager. Two rebuilds on the Pi:

| What | Command | Source |
|------|---------|--------|
| System | `nrs` | `~/git/rpi5` (via `$NIXOS_FLAKE`) |
| User env | `hms` | `~/.config/nix` (dotfiles) |

This separation lets an agent on the Pi modify NixOS system config without touching dotfiles.

Uses [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) for Pi 5 kernel and firmware support.

**Why two steps?** Ideally we'd build one image with everything (connor user, full config). But `nixos-raspberrypi`'s bootloader module conflicts with the upstream sd-image module's extlinux bootloader — you can't combine them. So we use a two-step process:

1. **Build installer image** — minimal NixOS with `nixos` user and your SSH keys baked in
2. **Deploy full config** — boot, SSH in, run `nixos-rebuild switch` to deploy your actual config

The flake has:
- `nixosConfigurations.rpi5` — your running system config
- `installerImages.rpi5` — the bootstrap installer image

## Build Installer Image

Build the installer with SSH keys baked in (uses linux-builder VM on Mac):

```bash
cd ~/rpi5
nix build .#installerImages.rpi5
```

Extract and flash:

```bash
zstd -d result/sd-image/*.img.zst -o rpi5.img
# Flash to USB drive (check disk number with: diskutil list)
diskutil unmountDisk disk4
sudo dd if=rpi5.img of=/dev/rdisk4 bs=4M status=progress
diskutil eject disk4
```

## First Boot

1. Plug USB drive into Pi 5, power on
2. Find IP: `nmap -sn 192.168.1.0/24` or check router DHCP leases
3. SSH in as `nixos` (keys from github.com/connorads.keys baked in):
   ```bash
   ssh nixos@<pi-ip>
   ```
4. Deploy full config directly from GitHub:
   ```bash
   sudo nixos-rebuild switch --flake 'github:connorads/rpi5#rpi5'
   ```
5. SSH as `connor@<pi-ip>` (the user in your config) — passwordless sudo enabled.

## Post-boot Setup

After first boot and system deploy:

1. SSH as `connor`:
   ```bash
   ssh connor@<pi-ip>
   ```

2. Clone dotfiles (sets up shell, tools, user env):
   ```bash
   curl -fsSL https://raw.githubusercontent.com/connorads/dotfiles/master/install.sh | bash
   ```

3. Set NixOS flake path in machine-local config:
   ```bash
   echo 'export NIXOS_FLAKE="$HOME/git/rpi5"' >> ~/.zshrc.local
   ```

4. Deploy user environment (gives you the full "feels like home" experience):
   ```bash
   hms
   ```

5. Clone system config (for local edits and agent access):
   ```bash
   git clone https://github.com/connorads/rpi5.git ~/git/rpi5
   ```

## Tailscale Setup

Set up Tailscale (opens auth link in browser):

```bash
sudo tailscale up
```

**Troubleshooting**: If auth link shows "expired" immediately, try:
1. Restart tailscaled: `sudo systemctl restart tailscaled`
2. Clear state and retry: `sudo rm /var/lib/tailscale/tailscaled.state && sudo systemctl restart tailscaled`
3. Try incognito browser window

After auth, operator and hostname are set automatically on next rebuild.
To set manually: `sudo tailscale set --operator=connor --hostname=rpi5`

Now `ts status`, `ts up` etc work without sudo, and the Pi is accessible as `rpi5` on the tailnet.

## Updating the Pi

### System config (this repo)

```bash
# From the Pi (after repo cloned to ~/git/rpi5)
nrs                      # reads $NIXOS_FLAKE

# From GitHub (no clone needed)
sudo nixos-rebuild switch --flake 'github:connorads/rpi5#rpi5'

# Remotely from Mac (once on Tailscale)
nixos-rebuild switch \
  --flake ~/rpi5#rpi5 \
  --build-host connor@rpi5 \
  --target-host connor@rpi5 \
  --use-remote-sudo
```

### User environment (dotfiles)

```bash
hms                      # home-manager switch from ~/.config/nix
```

### Both at once

```bash
up                       # updates tools, flake lock, then runs nrs + hms on NixOS
```

### Automatic system updates

The Pi auto-upgrades daily at 04:00 from `github:connorads/rpi5#rpi5`. Push to main and the next auto-upgrade picks it up.

## SSH Key Updates

SSH keys are fetched from `github.com/connorads.keys` at build time.

If you add/remove keys on GitHub, update the hash and rebuild:

```bash
nix-prefetch-url https://github.com/connorads.keys
# Update sha256 in:
#   - configuration.nix (for running system)
#   - flake.nix installerImages.rpi5 (for installer image)
nrs
```

## Fallback: Generic Installer

If you can't build the custom installer image:

1. Build generic installer (no SSH keys, random credentials):
   ```bash
   nix build github:nvmd/nixos-raspberrypi#installerImages.rpi5
   ```
2. Boot Pi with HDMI connected — random credentials shown on screen
3. SSH in with those credentials, then:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/connorads/dotfiles/master/install.sh | bash
   sudo nixos-rebuild switch --flake 'github:connorads/rpi5#rpi5'
   ```
