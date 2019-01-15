{ config, pkgs, ... }:
# zfs test vm settings
{
imports = [];

i18n = {
consoleFont = "Lat2-Terminus16";
consoleKeyMap = "us";
defaultLocale = "en_US.UTF-8";
};

time.timeZone = "America/Los_Angeles";

programs.mtr.enable = true;
programs.bash.enableCompletion = true;

networking.hostName = "themelios-vm";


# system.stateVersion (set to the same version as the ISO installer)

# This value determines the NixOS release with which your system is to be
# compatible, in order to avoid breaking some software such as database
# servers. You should change this only after NixOS release notes say you
# should.
system.stateVersion = "18.09"; # Did you read the comment?
}
