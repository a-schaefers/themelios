{ config, pkgs, ... }:
# zfs test vm settings
{
  imports = [];
  boot.kernelModules = [ "microcode" ];
  boot.kernelParams = [ "" ];

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "America/Los_Angeles";

  programs.mtr.enable = true;
  programs.bash.enableCompletion = true;

  networking.hostName = "nixvm";

  nix.allowedUsers = [ "root" "@wheel" ];
  nix.trustedUsers = [ "root" "@wheel" ];
  nix.useSandbox = true;

  # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}
