{
    description = "A Collection of CMake modules for FIRST Robotics Competitions teams.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      perSystem = { pkgs, ... }: {
        packages.default = pkgs.callPackage ./package.nix {};
        packages.frcmake = pkgs.callPackage ./package.nix {};
      };
    };
}
