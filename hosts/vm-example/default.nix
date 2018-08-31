{ config, pkgs, ... }:
# zfs test vm settings
{
  imports = [];

  boot.loader.grub.devices = [ "/dev/sda" ];

  boot.kernelModules = [ "microcode" ];
  boot.kernelParams = [ "" ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "America/Los_Angeles";

  programs.mtr.enable = true;
  programs.bash.enableCompletion = true;

  networking.hostName = "nixvm";
  networking.networkmanager.enable = true;
  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 22 ];

  services.openssh.enable = true;
  powerManagement.enable = true;

  nix.allowedUsers = [ "root" "@wheel" ];
  nix.trustedUsers = [ "root" "@wheel" ];
  nix.useSandbox = true;

  # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}
