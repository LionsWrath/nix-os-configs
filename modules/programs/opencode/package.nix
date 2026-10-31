# OpenCode, pinned to the releases the Forge adapters are tested against: one
# per API generation, since 2.x replaced the 1.x server API. Pick one with
# `callPackage ./package.nix { release = "1.19.4"; }`; the default is the newest.
#
# These are the official prebuilt binaries: 1.x from npm, 2.x from the GitHub
# release (npm stops at 1.x, and nixpkgs lags behind). Each is a Bun executable
# with its code in an ELF section; only the interpreter is patched, and it must
# not be stripped.
{ lib, stdenv, fetchurl, autoPatchelfHook, release ? "2.2.5" }:

let
  releases = {
    "1.19.4" = {
      url = "https://registry.npmjs.org/opencode-linux-x64/-/opencode-linux-x64-1.19.4.tgz";
      hash = "sha512-rQ/l3jmJoxf8ZYnBargg9alURlz6buEilysGODtzkcmcYtcZ91LOgF034oUUHHQl8/y1hbRTDvg6ujqUjQsMXw==";
      sourceRoot = "package";
      binary = "bin/opencode";
      versionOutput = "1.19.4";
    };
    "2.2.5" = {
      url = "https://github.com/anomalyco/opencode/releases/download/v2.2.5/opencode-linux-x64.tar.gz";
      hash = "sha256-CfRDAsEP0DaRL1nIH9Gu9d9F3Qb2SRl/nfybvip5YU4=";
      sourceRoot = ".";
      binary = "opencode";
      versionOutput = "opencode v2.2.5";
    };
  };
  r = releases.${release} or (throw "opencode: no pinned release ${release} (have: ${lib.concatStringsSep ", " (lib.attrNames releases)})");
in
stdenv.mkDerivation {
  pname = "opencode";
  version = release;

  src = fetchurl { inherit (r) url hash; };

  inherit (r) sourceRoot;
  nativeBuildInputs = [ autoPatchelfHook ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${r.binary} $out/bin/opencode
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    # 2.x creates $TMPDIR/opencode, which is where its binary was unpacked
    export HOME=$(mktemp -d) TMPDIR=$(mktemp -d)
    $out/bin/opencode --version | grep -qx "${r.versionOutput}"
  '';

  meta = {
    description = "AI coding agent for the terminal (official prebuilt binary)";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
