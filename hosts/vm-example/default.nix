{ config, pkgs, ... }:
# just an example top-level "configuration.nix" file within the themelios scheme
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
}
