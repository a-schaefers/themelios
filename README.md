# Themelios
Bootstrap a zfs-on-root NixOS configuration in one command.

![Themelios NixOS Screenshot](https://github.com/a-schaefers/themelios/raw/master/themelios_usage.png)

## From any NixOS live disk, Themelios
- Automatically installs zfs and git to the livedisk if needed
- Clones your git repo, optionally using a non-master branch
- Finds your configuration.sh file automatically
- Configures a zfs-on-root system to your configuration.sh file specification including the following options:
  * Uses sgdisk and/or wipefs, or dd to clear your disks
  * Creates a single/mirror/raidz1/raidz2/raidz3 zpool
  * Configures a zfs-on-root dataset scheme by default
  * Optionally generates and imports an /etc/nixos/themelios-zfs.nix which includes sensible settings for zfs-on-root.
  * Optional "zfs-extra" enables further zfs-support options in NixOS
  * Optional "overlay" feature allows easy custom pool creation settings and dataset scheme changes without need to hack on the script directly
- Generates an /etc/nixos/configuration.nix which imports your top-level-nixfile from your repo (and thereby nixos-install's the rest of your operating system)
- Aims to fail gracefully with continue and retry options

## What Themelios does not do (yet)
- Currently UEFI is unsupported because UEFI does not allow for "pure" zfs-on-root systems and therefore using legacy bios with zfs boot environments is a more robust solution.
- Use msdos partition tables (Zfs is GPT by default.)
- Full Disk encryption (Let's wait for zfsonlinux native encryption to reach full maturity before implementing this...)
- **Include the beadm script and with full beadm and nix grub integration on the bootloader. [This is my personal first priority.](https://github.com/a-schaefers/grubbe-mkconfig/issues/7)**
- Posix. All NixOS live disks come with bash, this is a NixOS specific project, so bash is perfect. Have a nice day. :)

## Try it in it a VM right now!
- From a NixOS LiveDisk VM,
```bash
[root@nixos:~] bash <(curl https://raw.githubusercontent.com/a-schaefers/themelios/master/themelios) vm-example a-schaefers/themelios
```
This command executes the script with curl and bash, which in turn downloads the a-schaefers/themelios repo from github, finds the "vm-example" directory with a configuration.sh file and begins the bootstrap process.

## "configuration.sh" [so-called]
Configuration.sh may actually be named anything you want and located anywhere in your project, Themelios will search for $1 by filename first and find it automatically, provided it is a uniquely named file.

If the filename isn't found, then Themelios will search for directories by the same name. So if you prefer using a standard naming convention, put a literal "configuration.sh" file inside of a uniquely named directory and feed Themelios the unique directory name.
The example "Try it init a VM right now!" command of this repository uses this method:
```bash
# vm-example is not a file inside this repo, but is a directory-- so this finds the dir hosts/vm-example/ and loads thel literal "configuration.sh" file.
[root@nixos:~] themelios vm-example a-schaefers/themelios
```

If none of this works for you, just tell themelios where the file is relative to project root:
```bash
[root@nixos:~] themelios ./hosts/vm-example/configuration.sh https://github.com/a-schaefers/themelios.git master
```

_NOTE: The username/repo-name shortcut only works for Github repos. Non-Github repos must provide the full remote._

What can I say? I like shortcuts? One command was not enough, it needed to be one _memorable_ command!

**TL;DR. Feed Themelios a git repository url that contains a file which has the following configuration variables:**
```bash
# themelios configuration.sh example

# disk preparation settings #

use_sgdisk_clear="true"    # use sgdisk --clear
use_wipefs_all="true"      # use wipefs --all
use_zero_disks="false"     # use dd if=/dev/zero ...

# zfs pool settings #

zfs_pool_name="zroot"
zfs_pool_type="mirror"     # use "" for single, or "mirror", "raidz1", etc.

# note: using /dev/disk/by-id is also preferable.
zfs_pool_disks=("/dev/sda" "/dev/sdb")

# datasets to be set with com.sun:auto-snapshot=true
zfs_auto_snapshot=("$zfs_pool_name/HOME" "$zfs_pool_name/ROOT")

# if true, mount /nix outside of the / (root) dataset.
# setting this to true would trade-off the ability to use zfs boot environments for extra disk space.
# if you use nix.gc.automatic, then this should not be much of an issue. recommended "false".
zfs_dataset_slashnix_no_root="false"

# todo allow true or false for this exception.
zfs_use_atime="off"              # set to "on" or "off" (recommended "off" for ssd.)

zfs_make_swap="false"            # creates a swap zvol
zfs_swap_size="4G"

# nix_os bootstrap settings #

# your top-level configuration.nix file to be bootstrapped-- (use the relative path from the project_root.)
# for example, to bootstrap project_root/hosts/vm-example/default.nix
nix_top_level_configuration="hosts/vm-example"

# directory name of to clone your git-remote in "/" (root). # may be anything, but do not use slashes.
# this is intended to be the directory to operate the nix installation from.
nix_repo_name="nix-config"

# creates /etc/nixos/zfs-configuration.nix with sensible settings
nix_zfs_configuration_enabled="true"

# enable "extra" options [below] in addition to zfs_configuration?
nix_zfs_configuration_extra_enabled="true"
```

## Optional overlays
If you want to override the default Themelios zpool_create() or datasets_create() functions with your own code, then set the optional variables in your configuration.sh,
```bash
# if set, themelios will source them, so long as the files exist alongside configuration.sh
zfs_pool_overlay_file=""         # override zpool_create()
zfs_dataset_overlay_file=""      # override datasets_create()
```
And then create the files and place them alongside wherever your configuration.sh is :)

## zfs-configuration.nix
If **nix_zfs_configuration_enabled="true"** in a configuration.sh file, Themelios will create /etc/nixos/zfs-configuration.nix with the following zfs-on-root settings:
```bash
{ ... }:
{ imports = [];

# configure grub using /dev/disk/by-id and zfs-support.
boot.supportedFilesystems = [ "zfs" ];
boot.loader.grub.enable = true;
boot.loader.grub.version = 2;
boot.loader.grub.devices = [
$(for disk_id in "${zfs_pool_disks[@]}"
do
echo "\"$disk_id\""
done)
];

# the 32-bit host id of the machine, formatted as 8 hexadecimal characters.
# you should try to make this id unique among your machines.
networking.hostId = "$zfs_host_id";

# noop, the recommended elevator with zfs.
# shell_on_fail allows to force import manually in the case of zfs import failure.
boot.kernelParams = [ "elevator=noop" "boot.shell_on_fail" ];

# grub on zfs has been known to have a hard time finding kernels with really/long/dir/paths
# just copy the kernels to /boot and avoid the issue.
boot.loader.grub.copyKernels = true;

# setting these to false will ensure some safeguards are active that zfs uses to protect your zfs pools.
boot.zfs.forceImportAll = false;
boot.zfs.forceImportRoot = false;
}
```

## Additional configuration.sh settings - zfs extra
Enable **nix_zfs_configuration_extra_enabled="true"** in addition to **nix_zfs_configuration_enabled="true"** in configuration.sh for the following extras:
```bash
# auto scrubs
nix_zfs_extra_auto_scrub="true"

# auto snapshots
nix_zfs_extra_auto_snapshot_enabled="true"
nix_zfs_extra_auto_snapshot_frequent="8"   # take a snapshot every 15 minutes and keep 8 in rotation
nix_zfs_extra_auto_snapshot_hourly="0"
nix_zfs_extra_auto_snapshot_daily="7"      # take a daily snapshot and keep 7 in rotation
nix_zfs_extra_auto_snapshot_weekly="0"
nix_zfs_extra_auto_snapshot_monthly="0"

# auto garbage collection
nix_zfs_extra_gc_automatic="true"
nix_zfs_extra_gc_dates="daily"
nix_zfs_extra_gc_options="--delete-older-than 7d"

# auto /tmp clean
nix_zfs_extra_clean_tmp_dir="true"
```

## Last things
If you have special [post nixos-install] needs and do not want the script to automatically umount /mnt, export zpool, and ask to reboot, pass NOUMOUNT=1 to the script.
```bash
[root@nixos:~] NOUMOUNT=1 themelios foo bar ...
```

## Debugging
If something goes haywire and you just want to start the process all over without rebooting the machine, you could try the following:
```bash
[root@nixos:~] STARTOVER=1 POOL=zroot themelios foo bar
```

## Build Themelios into a custom NixOS rescue iso
Save the following somewhere on an already existing NixOS install as iso.nix:
```nix
{config, pkgs, ...}:
let
  themelios = pkgs.writeScriptBin "themelios" ''
    bash <(curl https://raw.githubusercontent.com/a-schaefers/themelios/master/themelios) $@
  '';
in {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  networking = {
    networkmanager.enable = true;
    wireless.enable = false; #networkmanager.enable handles this
    firewall.allowPing = true;
    firewall.allowedTCPPorts = [ 22 ];
    firewall.allowedUDPPorts = [ 22 ];
  };
  services.openssh.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  environment.systemPackages = with pkgs; [ git themelios ];
}
```

And build it!
```bash
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix
```

The generated iso will be found inside the newly created "result/" directory.

## Making contributions
Check out the [What Themelios does not do](https://github.com/a-schaefers/themelios#what-themelios-does-not-do-yet) section and make PR's. I appreciate all the help I can get!

Thank you!
