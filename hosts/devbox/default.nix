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
    openssh.authorizedKeys.keys = [
      # ragost key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1OTY109TkeFKYgv2mHKGqTNvh6+LQhOKDsUW6VdRw4 ragost@orochi-client"
    ];
  };

  networking.firewall.enable = true;

  system.stateVersion = "24.11";
}
