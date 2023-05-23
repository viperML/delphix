# delphix

> from the Oracle of Delphi + nix

Library for testing and deploying your disko + NixOS configurations.


## Usage

You need to declare 2 NixOS configurations.

1. `target` configuration. This will be the configuration that you want to deploy, which includes a disko config.
1. `installer` configuration. This will be a minimal NixOS configuration, that includes the instructions to install `target`.

To configure the installer, declare an output like so:

```nix
{
  inputs.delphix.url = "github:viperML/delphix";

  outputs = {self, nixpkgs, delphix, ...}: {

    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      # Regular NixOS config with disko
    };

    nixosConfigurations."installer" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        delphix.nixosModules.installer
        {delphix.target = self.nixosConfigurations."nixos";}
      ];
    };

  };
}
```

Build the VM:

```
nix build .#nixosConfigurations.installer.config.delphix.vm -L
```

## Limitations

- Only 1 disk (/dev/vda)
- Properly handle cross-system
- ...