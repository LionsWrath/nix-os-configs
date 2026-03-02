{ pkgs, lib, ... }:
{
  imports = [
    ../../modules/common/base.nix
    ../../modules/profiles/devbox.nix

    # Add per-VM generated hardware profile in concrete host files:
    # ./hardware-configuration.nix
  ];

  # Host-agnostic defaults (override per VM)
  networking.hostName = lib.mkDefault "devbox";

  users.users.lionswrath = {
    isNormalUser = true;
    description = "lionswrath";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  networking.firewall.enable = true;

  system.stateVersion = "24.11";
}
