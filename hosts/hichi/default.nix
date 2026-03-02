{ ... }:
{
  imports = [
    ../devbox/default.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "hichi-devbox";

  users.users.lionswrath.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1OTY109TkeFKYgv2mHKGqTNvh6+LQhOKDsUW6VdRw4 ragost@orochi-client"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9wPZ+cAFB6nFo3QjDD49encZWzqlIjt3Sf0nZ99KYH caio.tonetti@gmail.com"
  ];

  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PubkeyAuthentication = true;
    PermitRootLogin = "no";
  };
}
