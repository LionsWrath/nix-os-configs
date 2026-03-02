{
  description = "NixOS configurations (profiles + hosts)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      mkSystem = system: modules:
        nixpkgs.lib.nixosSystem {
          inherit system modules;
        };
    in {
      nixosConfigurations = {
        # Existing desktop host (current layout kept for compatibility)
        hani = mkSystem "x86_64-linux" [
          ./hyprland/configuration.nix
        ];

        # Host-agnostic devbox baseline
        devbox = mkSystem "x86_64-linux" [
          ./hosts/devbox/default.nix
        ];

        # Concrete host profile (target: Proxmox VM)
        hichi = mkSystem "x86_64-linux" [
          ./hosts/hichi/default.nix
        ];
      };
    };
}
