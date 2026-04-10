{
  pkgs ? import <nixpkgs> { config.allowUnfree = true; },
  pkgVer ? "local",
}:

let

  archDir =
    if pkgs.stdenv.hostPlatform.isx86_64 then
      "x64"
    else if pkgs.stdenv.hostPlatform.isAarch64 then
      "arm64"
    else
      throw "Unsupported architecture";

  src = ./. + "/artifacts/${archDir}/linux-unpacked";

  deezer-desktop = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "deezer-desktop";
    version = pkgVer;
    inherit src;

    nativeBuildInputs = [
      pkgs.makeWrapper
    ];

    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      install -d $out/bin $out/share/deezer-desktop/resources $out/share/applications $out/share/icons/hicolor/scalable/apps

      cp $src/resources/dev.aunetx.deezer.desktop $out/share/applications/deezer-desktop.desktop
      substituteInPlace $out/share/applications/deezer-desktop.desktop \
        --replace-fail "run.sh" "deezer-desktop" \
        --replace-fail "dev.aunetx.deezer" "deezer-desktop"
      cp $src/resources/dev.aunetx.deezer.svg $out/share/icons/hicolor/scalable/apps/deezer-desktop.svg
      cp -r $src/resources/{app.asar,linux} $out/share/deezer-desktop/resources/

      makeWrapper "${pkgs.lib.getExe pkgs.electron}" "$out/bin/deezer-desktop" \
        --inherit-argv0 \
        --add-flags "$out/share/deezer-desktop/resources/app.asar" \
        --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
        --set DZ_RESOURCES_PATH "$out/share/deezer-desktop/resources"

      runHook postInstall
    '';
  });
in
{
  "deezer-desktop" = deezer-desktop;
  default = deezer-desktop;
}
