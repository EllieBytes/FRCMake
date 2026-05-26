{ pkgs ? import <nixpkgs> {}, ... }:

pkgs.stdenv.mkDerivation {
    name = "frcmake-modules";
    version = "1.0.0";
    src = ./.;

    nativeBuildInputs = with pkgs; [
      cmake
    ];

    configurePhase = ''
      export FRCMAKE_DATAROOT=$out/share/
      cmake -S . -B build
    '';

    buildPhase = "";

    installPhase = ''
      export FRCMAKE_DATAROOT=$out/share/cmake
      mkdir -p $out/share/cmake
      cmake --install build
    '';
}
