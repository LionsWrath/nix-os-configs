# OpenCode, pinned to the release the Forge adapter is tested against.
# nixpkgs builds a different line (2.x), so this uses the official prebuilt
# binary from npm. It is a Bun executable with its code in an ELF section;
# only the interpreter is patched, and it must not be stripped.
{ lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "opencode";
  version = "1.19.5";

  src = fetchurl {
    url = "https://registry.npmjs.org/opencode-linux-x64/-/opencode-linux-x64-${version}.tgz";
    hash = "sha512-i1qh7VooLGML9xX6ud93y0JA8j/1aPeDYRKjsmYXrJX1TjIWHgBBMkEbEJPZthpWbsJg//XfBgR6Kb7+NPaJiQ==";
  };

  sourceRoot = "package";
  nativeBuildInputs = [ autoPatchelfHook ];
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/opencode $out/bin/opencode
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    HOME=$TMPDIR $out/bin/opencode --version | grep -qx ${version}
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
