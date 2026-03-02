{ pkgs, ... }:
{
  # Devbox-oriented defaults (safe baseline)
  services.qemuGuest.enable = true;

  programs.git.enable = true;

  environment.systemPackages = with pkgs; [
    curl
    jq
    yq
    ripgrep
    fd
    htop
    tmux
    python3
    nodejs
    go
    rustup
  ];
}
