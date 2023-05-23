{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: let
  target = config.delphix.target;
in {
  # _file = ./installer.nix;

  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
  ];

  options = with lib; {
    delphix = {
      target = mkOption {
        type = types.raw;
        description = "Target nixosConfiguration to install. Must include disko config.";
      };

      vm = mkOption {
        type = types.package;
        description = "Script to install the configuration against a VM";
      };
    };
  };

  config = {
    delphix.vm = pkgs.writeShellApplication {
      name = "${target.config.networking.hostName}-vm-installer";
      runtimeInputs = with pkgs; [
        qemu
      ];
      text = ''
        DISK="$PWD/disk.qcow2"
        rm -vf "$DISK"
        qemu-img create -f qcow2 "$DISK" 10G

        # FIXME system
        exec qemu-system-x86_64 \
            -kernel "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}" \
            -initrd "${config.system.build.netbootRamdisk}/initrd" \
            -nographic \
            -append "init=${config.system.build.toplevel}/init console=ttyS0,115200 loglevel=4 panic=-1" \
            -m 8192 \
            --enable-kvm \
            -cpu host \
            -no-reboot \
            -drive file="$DISK",media=disk,if=virtio
      '';
    };

    environment.etc."disko-format".source = target.config.system.build.formatScript;

    systemd.services = {
      "delphix-format" = {
        serviceConfig.ExecStart = target.config.system.build.formatScript;
        serviceConfig.Type = "oneshot";
        wantedBy = ["multi-user.target"];
      };

      "delphix-mount" = {
        serviceConfig.ExecStart = target.config.system.build.mountScript;
        serviceConfig.Type = "oneshot";
        wantedBy = [
          "multi-user.target"
        ];
        after = ["delphix-format.service"];
      };
    };
  };
}
