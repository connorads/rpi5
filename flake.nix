# ==============================================================================
# RPi5 NixOS Configuration
# ==============================================================================
#
# Configurations:
#   - nixosConfigurations."rpi5"  : Raspberry Pi 5 (NixOS)
#   - installerImages.rpi5       : Pi 5 installer (SSH keys baked in)
#
# Rebuild: nixos-rebuild switch --flake .#rpi5
# Build Pi installer: nix build .#installerImages.rpi5
#
# ==============================================================================

{
  description = "RPi5 NixOS configuration";

  inputs = {
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixos-raspberrypi,
      home-manager,
    }:
    {
      formatter.aarch64-linux = nixos-raspberrypi.inputs.nixpkgs.legacyPackages.aarch64-linux.nixfmt;

      # Raspberry Pi 5: nixos-rebuild switch --flake .#rpi5
      nixosConfigurations."rpi5" = nixos-raspberrypi.lib.nixosSystem {
        specialArgs = {
          inherit nixos-raspberrypi;
        };
        modules = [
          (
            { ... }:
            {
              imports = with nixos-raspberrypi.nixosModules; [
                raspberry-pi-5.base
                raspberry-pi-5.bluetooth
              ];
            }
          )
          home-manager.nixosModules.home-manager
          ./configuration.nix
        ];
      };

      # Pi 5 installer image with SSH keys baked in (no HDMI needed)
      # Build: nix build .#installerImages.rpi5
      installerImages.rpi5 =
        let
          installer = nixos-raspberrypi.lib.nixosInstaller {
            specialArgs = {
              inherit nixos-raspberrypi;
            };
            modules = [
              (
                { ... }:
                {
                  imports = with nixos-raspberrypi.nixosModules; [
                    raspberry-pi-5.base
                    raspberry-pi-5.page-size-16k
                  ];
                }
              )
              (
                { ... }:
                let
                  githubKeys = builtins.fetchurl {
                    url = "https://github.com/connorads.keys";
                    sha256 = "1alzqm1lijavww9rlrj7dy876jy50dfx0v3f4a813kyxz1273yi1";
                  };
                  keys = builtins.filter (k: builtins.isString k && k != "") (
                    builtins.split "\n" (builtins.readFile githubKeys)
                  );
                in
                {
                  users.users.nixos.openssh.authorizedKeys.keys = keys;
                  users.users.root.openssh.authorizedKeys.keys = keys;
                }
              )
            ];
          };
        in
        installer.config.system.build.sdImage;
    };
}
