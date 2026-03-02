{ pkgs, ... }:
{
  imports = [
    ../../modules/common/base.nix
    ../../modules/profiles/devbox.nix

    # NOTE: add generated hardware profile when applying to the VM:
    # ./hardware-configuration.nix
  ];

  networking.hostName = "hichi-devbox";

  users.users.lionswrath = {
    isNormalUser = true;
    description = "lionswrath";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  # Keep firewall enabled by default for VM baseline
  networking.firewall.enable = true;

  system.stateVersion = "24.11";
}
