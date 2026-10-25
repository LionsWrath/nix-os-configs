{ pkgs, ... }:
let
  opencode = pkgs.callPackage ./package.nix { };
in
{
  environment.systemPackages = [ opencode ];

  # The binary lives in the read-only store and is pinned here; never self-update
  environment.variables.OPENCODE_DISABLE_AUTOUPDATE = "1";
}
