{ pkgs, ... }:
{
  imports = [
    ../devbox/default.nix
    ./hardware-configuration.nix
    ../../modules/services/orochi-opencode.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  networking.hostName = "hichi-devbox";

  # The LAN without IPv6. With it, Tailscale picked a link-local IPv6 path to the Android phone that
  # carried its pings but no data, so the Loom app timed out; over IPv4 it reaches the phone like other
  # hosts do. NetworkManager owns ens18 and would turn IPv6 back on, so the profile says so, not a sysctl.
  networking.networkmanager.ensureProfiles.profiles.lan = {
    connection = {
      id = "lan";
      type = "ethernet";
      interface-name = "ens18";
      autoconnect-priority = 10;
    };
    ipv4.method = "auto";
    ipv6.method = "disabled";
  };

  users.users.lionswrath.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1OTY109TkeFKYgv2mHKGqTNvh6+LQhOKDsUW6VdRw4 ragost@orochi-client"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9wPZ+cAFB6nFo3QjDD49encZWzqlIjt3Sf0nZ99KYH caio.tonetti@gmail.com"
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PubkeyAuthentication = true;
    };
  };
}
