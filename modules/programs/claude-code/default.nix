{ pkgs, lib, inputs, ... }:
let
  user = "lionswrath";

  # claude-code is unfree and 24.11 ships an outdated version
  pkgsUnstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };

  # Status line script, with its runtime deps pinned
  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = with pkgs; [ jq coreutils ];
    # Script reads optional fields and tolerates missing ones
    bashOptions = [ ];
    text = builtins.readFile ./statusline.sh;
  };

  statusLineSetting = builtins.toJSON {
    type = "command";
    command = "${statusline}/bin/claude-statusline";
    padding = 0;
  };
in
{
  environment.systemPackages = [
    pkgsUnstable.claude-code
    statusline
  ];

  # No persistent auto memory across sessions
  environment.variables.CLAUDE_CODE_DISABLE_AUTO_MEMORY = "1";

  # Claude Code rewrites ~/.claude/settings.json itself, so it can't be a
  # read-only store symlink. Instead, point statusLine at the current script
  # on every activation, unless the user set a custom (non-Nix) one.
  system.activationScripts.claudeCodeStatusLine = {
    deps = [ "users" ];
    text = ''
      home=${lib.escapeShellArg "/home/${user}"}
      settings="$home/.claude/settings.json"
      ${pkgs.coreutils}/bin/install -d -o ${user} -g users "$home/.claude"
      [ -s "$settings" ] || echo '{}' > "$settings"
      tmp=$(${pkgs.coreutils}/bin/mktemp)
      if ${pkgs.jq}/bin/jq --argjson sl ${lib.escapeShellArg statusLineSetting} '
          if (.statusLine == null)
             or ((.statusLine.command // "") | test("claude-statusline$|/\\.claude/statusline\\.sh$"))
          then .statusLine = $sl else . end
          # Compact earlier than the model maximum (user-overridable default)
          | .autoCompactWindow //= 400000
        ' "$settings" > "$tmp"; then
        ${pkgs.coreutils}/bin/install -m 644 -o ${user} -g users "$tmp" "$settings"
      else
        echo "claude-code: could not update $settings (invalid JSON?), leaving it alone" >&2
      fi
      rm -f "$tmp"
    '';
  };

  # User-level skills, symlinked into ~/.claude/skills so every session sees
  # them. Only symlinks are replaced; a real directory of the same name is
  # left alone.
  system.activationScripts.claudeCodeSkills = {
    deps = [ "users" ];
    text = ''
      skills=${lib.escapeShellArg "/home/${user}/.claude/skills"}
      ${pkgs.coreutils}/bin/install -d -o ${user} -g users "$skills"
      for src in ${./skills}/*/; do
        name=$(${pkgs.coreutils}/bin/basename "$src")
        dest="$skills/$name"
        if [ -L "$dest" ] || [ ! -e "$dest" ]; then
          ${pkgs.coreutils}/bin/ln -sfn "''${src%/}" "$dest"
          ${pkgs.coreutils}/bin/chown -h ${user}:users "$dest"
        else
          echo "claude-code: $dest is not a symlink, leaving it alone" >&2
        fi
      done
    '';
  };
}
