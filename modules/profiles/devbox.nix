{ pkgs, ... }:
{
  # Devbox-oriented defaults (safe baseline)
  services.qemuGuest.enable = true;

  programs.git.enable = true;

  # Docker stack
  virtualisation.docker.enable = true;

  # tmux baseline (improved from ArchConfig)
  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 200000;
    keyMode = "vi";
    terminal = "screen-256color";
    extraConfig = ''
      # Prefix: C-a (legacy muscle memory)
      unbind C-b
      set -g prefix C-a
      bind-key C-a send-prefix

      # Better splits in current path
      unbind '"'
      unbind %
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Fast pane navigation (Alt + arrows)
      bind -n M-Left  select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up    select-pane -U
      bind -n M-Down  select-pane -D

      # Quality-of-life
      set -g mouse on
      set -g base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on
      set -sg escape-time 10
      set -g focus-events on

      # Quiet bells
      set -g visual-activity off
      set -g visual-bell off
      set -g visual-silence off
      setw -g monitor-activity off
      set -g bell-action none

      # Copy mode (vim-like)
      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi y send -X copy-selection-and-cancel

      # Keep status minimal but visible
      set -g status on
      set -g status-position bottom
      set -g status-interval 5
      set -g status-style "bg=#0b1220,fg=#9fb3cf"
      set -g status-left "#[fg=#3b82f6]#S #[fg=#9fb3cf]|"
      set -g status-right "#[fg=#9fb3cf]%Y-%m-%d %H:%M"
      setw -g window-status-current-format "#[fg=#e6edf3,bold] #I:#W "
      setw -g window-status-format "#[fg=#8aa1c1] #I:#W "
    '';
  };

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
