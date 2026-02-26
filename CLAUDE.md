# RPi5 NixOS Configuration

## Architecture

**Hybrid setup** — this repo owns NixOS system config only. User environment (shell, tools, git, tmux, starship, etc.) comes from [dotfiles](https://github.com/connorads/dotfiles) via standalone home-manager.

- System rebuild: `nrs` (reads `$NIXOS_FLAKE`, pointing to `~/git/rpi5`)
- User env rebuild: `hms` (reads `~/.config/nix` from dotfiles)

If you need to change user packages, shell config, or dev tools → that's a dotfiles change, not this repo.

## Repo Structure

| File | Purpose |
|------|---------|
| `flake.nix` | Standalone flake — 1 input: `nixos-raspberrypi` (kernel/firmware/nixosSystem) |
| `modules/base.nix` | Reusable NixOS baseline: nix settings, GC, timezone, zsh, system packages |
| `modules/security.nix` | Hardened SSH, fail2ban, passwordless sudo |
| `configuration.nix` | Host-specific: bootloader, networking, cachix, user, Tailscale, auto-upgrade, Docker, filesystems |
| `README.md` | Installation guide, update procedures, troubleshooting |

## How Changes Deploy

1. Push to `main` on GitHub
2. The Pi's `system.autoUpgrade` pulls from `github:connorads/rpi5#rpi5` daily at 04:00
3. If the config changed, it rebuilds and optionally reboots (03:00–06:00 window)

For immediate deployment: `ts ssh connor@rpi5 'sudo nixos-rebuild switch --flake "github:connorads/rpi5#rpi5"'`

## Testing Changes

```bash
nix flake check                                                    # Validate flake structure
nix build .#nixosConfigurations.rpi5.config.system.build.toplevel  # Full system build (needs aarch64-linux builder)
```

`nix flake check` is fast and catches syntax/eval errors. The full build requires a linux-builder (Mac) or running on aarch64-linux.

## Configuration Sections

### Safe to modify
- `configuration.nix` — networking, Tailscale flags, Docker, auto-upgrade schedule
- `modules/base.nix` — system packages, nix GC schedule
- `modules/security.nix` — SSH settings, fail2ban tuning

### Modify with care
- `system.autoUpgrade` — changing the flake URL breaks auto-updates
- `services.tailscale` — wrong flags can lock you out of remote access
- `networking.firewall` — overly restrictive rules can lock you out
- `services.openssh` — disabling breaks all remote access
- `users.users.connor.openssh.authorizedKeys` — wrong sha256 locks out SSH

### Never change
- `system.stateVersion` — must match the NixOS version used at install time
- `fileSystems` — must match the SD card partition labels from nixos-raspberrypi

### Not in this repo
- User packages, shell config, git config, tmux, starship → [dotfiles](https://github.com/connorads/dotfiles)

## Conventions

- British English in comments and docs
- Format with `nixfmt` (available as `nix fmt`)
- Document the *why* in comments, not the *what*

## Related

- **Dotfiles**: [github.com/connorads/dotfiles](https://github.com/connorads/dotfiles) — user environment for all machines including rpi5
- **Dotfiles rpi5 target**: `homeConfigurations."connor@rpi5"` in dotfiles flake
