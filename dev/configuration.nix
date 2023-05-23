{config, lib,  ...}: let
  efiSysMountPoint = "/efi";
in {
  documentation.enable = lib.mkForce false;

  boot = {
    kernelParams = [
      "console=ttyS0"
      "console=tty1"
    ];
    loader = {
      systemd-boot = {
        enable = true;
        # ESP is 100MB size
        configurationLimit = 1;
      };
      efi = {
        inherit efiSysMountPoint;
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      systemd.enable = true;
      availableKernelModules = ["xhci_pci"];
    };
  };

  systemd.network = {
    enable = true;
    networks.default = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };
  };
  networking = {
    useNetworkd = false;
    useDHCP = false;
  };

  services.qemuGuest.enable = true;

  disko.devices.disk."main" = {
    device = "/dev/vda";
    type = "disk";
    content = {
      type = "table";
      format = "gpt";
      partitions = [
        {
          name = "ESP";
          start = "1MiB";
          end = "100MiB";
          bootable = true;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = efiSysMountPoint;
          };
        }
        {
          name = "root";
          start = "100MiB";
          end = "100%";
          part-type = "primary";
          bootable = true;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        }
      ];
    };
  };
}
