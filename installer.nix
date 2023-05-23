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

      vm-interactive = mkOption {
        type = types.package;
        description = "Script to install the configuration to a VM";
      };
    };
  };

  config = {
    nix.settings.extra-experimental-features = [
      "nix-command"
      "flakes"
    ];

    delphix.vm-interactive = pkgs.writeShellApplication {
      name = "${target.config.networking.hostName}-vm-installer";
      runtimeInputs = with pkgs; [
        qemu_kvm
      ];
      text = ''
        DISK="$PWD/disk.qcow2"
        rm -vf "$DISK"
        qemu-img create -f qcow2 "$DISK" 10G

        exec qemu-kvm \
            -kernel "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}" \
            -initrd "${config.system.build.netbootRamdisk}/initrd" \
            -nographic \
            -append "init=${config.system.build.toplevel}/init console=ttyS0,115200 loglevel=4 panic=-1" \
            -m 8192 \
            --enable-kvm \
            -cpu host \
            -no-reboot \
            -drive file="$DISK",media=disk,if=virtio \
            "$@"
      '';
    };

    systemd.services = {
      "delphix-format" = {
        serviceConfig.ExecStart = target.config.system.build.formatScript;
        serviceConfig.Type = "oneshot";
        wantedBy = ["multi-user.target"];
      };

      "delphix-mount" = {
        serviceConfig.ExecStart = target.config.system.build.mountScript;
        serviceConfig.Type = "oneshot";
        wantedBy = ["multi-user.target"];
        after = ["delphix-format.service"];
      };

      "delphix-install" = {
        serviceConfig.Type = "oneshot";
        wantedBy = ["multi-user.target"];
        after = ["delphix-mount.service"];
        script = ''
          set -eux
          export PATH="${lib.makeBinPath [config.nix.package]}:$PATH"
          toplevel="${target.config.system.build.toplevel}"

          nix copy \
            --to /mnt \
            "$toplevel" \
            --no-check-sigs

          nix build \
            --store /mnt \
            "$toplevel" \
            --profile /mnt/nix/var/nix/profiles/system
        '';
      };

      "delphix-activate" = {
        serviceConfig.Type = "oneshot";
        wantedBy = ["multi-user.target"];
        after = ["delphix-install.service"];
        script = ''
          set -eux
          export PATH="${lib.makeBinPath [
            pkgs.utillinux
          ]}:$PATH"

          mkdir -p /mnt/etc
          touch /mnt/etc/NIXOS

          ${pkgs.nixos-install-tools}/bin/nixos-enter -- /nix/var/nix/profiles/system/sw/bin/sh -c "NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot"
        '';
      };
    };
  };
}
