{
  outputs = _: {
    nixosModules.installer = ./installer.nix;
  };
}
