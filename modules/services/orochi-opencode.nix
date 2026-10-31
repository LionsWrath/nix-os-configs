# The OpenCode server Orochi Loom's Forge drives, run natively as the user instead of in Docker, so
# agents get the same tools as the user's terminal (ssh, nix, git, docker). Forge stays in Docker and
# reaches it through the compose bridge (br-orochi), the only interface port 4096 is open on.
#
# The service sees its own view of a few paths (a private mount namespace), so the user's personal
# OpenCode keeps its config and sessions:
#   ~/.local/share/opencode  -> Loom's sessions (data/opencode)
#   ~/.config/opencode       -> Loom's config dir (data/opencode-config: AGENTS.md and the built-in skills)
#   /work, /skills, /opt/orochi -> the paths Forge uses for Thread dirs, the skill library and the skill-loader
#
# This is not a sandbox: a Thread can do what the user can. The bash "ask" rules in Loom's
# opencode.json turn risky commands into approvals in the app; they are guards, not a boundary.
{ pkgs, ... }:
let
  # Forge has an adapter per OpenCode API and detects which one runs when it starts, so restart Forge
  # after changing the release. 2.2.5 migrated Loom's 1.19.4 sessions on first start (one-way; the
  # 1.19.4 data is in orochi-loom/backups/opencode-before-2.2.5-20261031-013233).
  opencode = pkgs.callPackage ../programs/opencode/package.nix { release = "2.2.5"; };
  user = "lionswrath";
  home = "/home/${user}";
  loom = "${home}/Projects/orochi-loom";
  port = 4096;

  # Secrets go into the server's environment only, read from files and never printed.
  start = pkgs.writeShellScript "orochi-opencode-start" ''
    set -eu
    OPENCODE_SERVER_PASSWORD=$(cat ${loom}/.secrets/opencode_password)
    OPENROUTER_API_KEY=$(cat ${loom}/.secrets/openrouter_api_key)
    export OPENCODE_SERVER_PASSWORD OPENROUTER_API_KEY
    exec ${opencode}/bin/opencode serve --hostname 0.0.0.0 --port ${toString port}
  '';

  # The agent's shell is a zsh login shell, and /etc/zshenv resets PATH, so the `orochi` client the
  # Loom skills use must be on the system PATH, not only the service's.
  orochi = pkgs.writeShellScriptBin "orochi" ''
    exec ${loom}/docker/opencode/bin/orochi "$@"
  '';
in
{
  environment.systemPackages = [ orochi ];

  systemd.tmpfiles.rules = [
    "d ${loom}/data/opencode-config 0755 ${user} users -"
    "L+ ${loom}/data/opencode-config/AGENTS.md - - - - ${loom}/docker/opencode/AGENTS.md"
    "L+ ${loom}/data/opencode-config/skills - - - - ${loom}/docker/opencode/skills"
  ];

  systemd.services.orochi-opencode = {
    description = "OpenCode server for Orochi Loom";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    # The user's login PATH, for the server itself (agent shells set their own). Each entry gives its bin/.
    path = [
      "/run/wrappers"
      "/etc/profiles/per-user/${user}"
      "${home}/.nix-profile"
      "/run/current-system/sw"
    ];
    environment = {
      OPENCODE_DISABLE_AUTOUPDATE = "1";
      OPENCODE_CONFIG = "/opt/orochi/opencode.json";
      LOOM_URL = "http://127.0.0.1:7400";
      FABRIC_URL = "http://127.0.0.1:7410";
      FORGE_URL = "http://127.0.0.1:7420";
    };

    serviceConfig = {
      User = user;
      Group = "users";
      WorkingDirectory = "${loom}/work";
      ExecStart = start;
      Restart = "on-failure";
      RestartSec = 5;
      BindPaths = [
        "${loom}/data/opencode:${home}/.local/share/opencode"
        "${loom}/data/opencode-config:${home}/.config/opencode"
        "${loom}/work:/work"
      ];
      BindReadOnlyPaths = [
        "${loom}/data/skills:/skills"
        "${loom}/docker/opencode:/opt/orochi"
      ];
    };
  };

  networking.firewall.interfaces.br-orochi.allowedTCPPorts = [ port ];
}
