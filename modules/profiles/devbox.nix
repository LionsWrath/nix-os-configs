{ pkgs, ... }:
{
  # Devbox-oriented defaults (safe baseline)
  services.qemuGuest.enable = true;

  programs.git.enable = true;

  # Docker stack
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    # Core tooling
    curl
    jq
    yq
    ripgrep
    fd
    htop
    tmux

    # Python stack
    poetry
    micromamba
    python3
    python3Packages.pip
    python3Packages.virtualenv
    pyright
    ruff

    # Node stack
    nodejs_22
    yarn
    pnpm
    typescript
    nodePackages.npm-check-updates

    # Rust stack
    rustup
    cargo
    rustc
    clippy
    rustfmt

    # Containers / dev ops
    docker-compose
    lazydocker
  ];
}
