{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-common = {
      url = "github:viperML/nix-common";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      withSystem,
      config,
      ...
    }: {
      systems = ["x86_64-linux"];

      flake.nixosModules.installer = ../installer.nix;

      flake.nixosConfigurations = withSystem "x86_64-linux" ({
        pkgs,
        system,
        ...
      }: {
        "target" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            inputs.disko.nixosModules.disko
            inputs.nix-common.nixosModules.sane
            ({modulesPath, ...}: {
              imports = [
                "${modulesPath}/profiles/minimal.nix"
                "${modulesPath}/profiles/qemu-guest.nix"
              ];
            })
          ];
        };

        "installer" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            config.flake.nixosModules.installer
            {delphix.target = config.flake.nixosConfigurations."target";}
          ];
        };
      });
    });
}
