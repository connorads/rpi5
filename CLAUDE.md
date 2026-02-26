# RPi5 NixOS Configuration

## Repo Structure

| File | Purpose |
|------|---------|
| `flake.nix` | Standalone flake — 2 inputs: `nixos-raspberrypi` (kernel/firmware/nixosSystem) + `home-manager` |
| `configuration.nix` | Full NixOS system config: networking, SSH, Tailscale, auto-upgrade, home-manager, packages |
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
- `home.packages` — add/remove user packages
- `environment.systemPackages` — add/remove system packages
- `programs.git.settings` — git config
- `time.timeZone` — timezone

### Modify with care
- `system.autoUpgrade` — changing the flake URL breaks auto-updates
- `services.tailscale` — wrong flags can lock you out of remote access
- `networking.firewall` — overly restrictive rules can lock you out
- `services.openssh` — disabling breaks all remote access
- `users.users.connor.openssh.authorizedKeys` — wrong sha256 locks out SSH

### Never change
- `system.stateVersion` — must match the NixOS version used at install time
- `fileSystems` — must match the SD card partition labels from nixos-raspberrypi

## Conventions

- British English in comments and docs
- Single-file config (`configuration.nix`) — no splitting into modules unless complexity warrants it
- Format with `nixfmt` (available as `nix fmt`)
- Document the *why* in comments, not the *what*

## Related

- **Dotfiles**: [github.com/connorads/dotfiles](https://github.com/connorads/dotfiles) — shell config, home-manager for other machines
- **Shell config on Pi**: Managed via dotfiles repo (`install.sh` clones it), not this repo
