# Themelios
Bootstrap a zfs-on-root NixOS configuration in one command

![Themelios NixOS Screenshot](https://github.com/a-schaefers/themelios/raw/master/themelios_usage.png)

## What Themelios does
From any NixOS live disk, Themelios will do the following in approximate order:
- Automatically installs zfs and git to the livedisk if needed
- Clones your git repo, optionally using a non-master branch
- Finds your configuration.sh file automatically
- Configures a zfs-on-root system to your configuration.sh file specification including the following options:
  * Uses sgdisk and/or wipefs, or dd to clear your disks
  * Creates a single/mirror/raidz1/raidz2/raidz3 zpool
  * Configures a zfs-on-root dataset scheme by default
  * Optionally generates and imports an /etc/nixos/themelios-zfs.nix which includes essential settings for zfs-on-root.
  * Optional "zfs-care" enables further zfs-support options in NixOS
  * Optional "overlay" feature allows easy custom pool creation settings and dataset scheme changes without need to hack on the script directly
- Generates an /etc/nixos/configuration.nix which imports your top-level-nixfile from your repo (and thereby nixos-install's the rest of your operating system)
- Aims to fail gracefully with continue and retry options
- Themelios aims to be a simple script that is easy to hack on.

## What Themelios does not do (yet)
- Currently uefi is unsupported because UEFI does not allow for "pure" zfs-on-root systems and therefore using legacy bios with zfs boot environments is a more robust solution.
- Convert GPT to MS-DOS partition tables (GPT is zfs default and in 2018 this should be sufficient for most.)
- Full Disk encryption (Wait for native zfsonlinux to reach full maturity in this area. Or this may be possible with an overlay, please provide one if you can do it!)
- Configure more than one pool-- (this can be done with an overlay.)
- Write zeros to more than one disk concurrently.
- **Include the beadm script and with full beadm and nix grub integration on the bootloader. [This is my personal first priority.](https://github.com/a-schaefers/grubbe-mkconfig/issues/7)**
- Posix. My sh and bash-fu is an ongoing work-in-progress. Anyone who can help in this area with pull-requests, I'd appreciate it!

## Try it in it a VM right now!
- From a NixOS LiveDisk VM,
```bash
[root@nixos:~] bash <(curl https://raw.githubusercontent.com/a-schaefers/themelios/master/themelios) vm-example a-schaefers/themelios
```
This command executes the script with curl and bash, which in turn downloads the a-schaefers/themelios repo from github, finds the "vm-example" directory with a configuration.sh file and begins the bootstrap process.

## configuration.sh
Configuration.sh may actually be named anything you want and located anywhere in your project, Themelios will search by filename first and find it automatically, provided it is a uniquely named file.

If the filename isn't found, then Themelios will search for directories by the same name. So if you prefer using a standard naming convention, put a literal "configuration.sh" file inside of a uniquely named directory and feed Themelios the unique directory name.
The example "Try it init a VM right now!" command of this repository uses this method:
```bash
# vm-example is not a file inside this repo, so this finds the dir hosts/vm-example/ and loads configuration.sh
[root@nixos:~] themelios vm-example a-schaefers/themelios
```

If none of this works for you, just tell themelios where the file is relative to project root:
```bash
[root@nixos:~] themelios ./hosts/vm-example/configuration.sh https://github.com/a-schaefers/themelios.git master
```

**TL;DR. Feed Themelios a git repository url that contains a file which has the following configuration variables:**
```bash
# Themelios configuration.sh example
POOL_NAME="zroot"
POOL_TYPE=""          # May also be set to "mirror" or "raidz1", etc... Leave empty "" for single.

# use one disk per line here!
# POOL_DISKS="/dev/sda
# /dev/sdb
# /dev/sdc"
POOL_DISKS="/dev/sda"

SGDISK_CLEAR="true"   # Use sgdisk --clear
WIPEFS_ALL="true"     # Use wipefs --all
ZERO_DISKS="false"    # Use dd if=/dev/zero ...
ATIME="off"           # Set to "on" or "off" (recommended "off" for SSD.)
SNAPSHOT_ROOT="true"  # Set the value of com.sun:auto-snapshot
SNAPSHOT_HOME="true"
USE_ZSWAP="false"     # Creates a swap zvol
ZSWAP_SIZE="4G"

# Your top-level configuration.nix file to be bootstrapped-- (use the relative path from the project_root.)
# For example, to bootstrap project_root/hosts/vm-example/default.nix all of the following are equivalent:
TOP_LEVEL_NIXFILE="./hosts/vm-example"
TOP_LEVEL_NIXFILE="hosts/vm-example"
TOP_LEVEL_NIXFILE="hosts/vm-example/default.nix"

# Directory name of to clone your git-remote in "/" (root). # May be anything, but do not use slashes.
# This is intended to be the directory to operate the nix installation from.
NIXCFG_DIR="nix-config"

# If true, mount /nix outside of the / (root) dataset.
# Setting this to true would trade-off the ability to use zfs boot environments for extra disk space.
# If you use nix.gc.automatic, then this should not be much of an issue. Recommended "false".
NIXDIR_NOROOT="false" # mount /nix outside of the / (root) dataset.

# Creates /etc/nixos/themelios-zfs.nix with sensible settings
THEMELIOS_ZFS="true"
```

## themelios-zfs.nix
If THEMELIOS_ZFS="true" in a configuration.sh file, Themelios will create /etc/nixos/themelios-zfs.nix with the following sensible zfs-on-root settings:
```bash
{ ... }:
{ imports = [];

# some zfs-on-root sensible settings

# configure grub using /dev/disk/by-d and zfs-support
boot.supportedFilesystems = [ "zfs" ];
boot.loader.grub.enable = true;
boot.loader.grub.version = 2;
boot.loader.grub.devices = [
$(IFS=$'\n'
for DISK_ID in ${POOL_DISKS}
do
echo $(echo "\"${DISK_ID}\"")
done)
];

# The 32-bit host ID of the machine, formatted as 8 hexadecimal characters.
# You should try to make this ID unique among your machines.
networking.hostId = "${POOL_HOSTID}";

# noop elevator recommended.
# shell_on_fail allows to force import manually in the case of zfs import failure.
boot.kernelParams = [ "elevator=noop" "boot.shell_on_fail" ];

# grub on ZFS has been known to have a hard time finding kernels with really/long/dir/paths
# Just copy the kernels to /boot and avoid the issue.
boot.loader.grub.copyKernels = true;

# Setting these to false will ensure some safeguards are active that ZFS uses to protect your ZFS pools.
boot.zfs.forceImportAll = false;
boot.zfs.forceImportRoot = false;
}
```

## Additional configuration.sh settings - Zfs care
The following options are only applicable if both THEMELIOS_ZFS="true" and THEMELIOS_ZFS_CARE="true" in configuration.sh
```bash
# Enable ZFS_CARE Options? (Only enable this if THEMELIOS_ZFS="true" also.)
THEMELIOS_ZFS_CARE="true"

####################
# ZFS_CARE Options #
####################

# Auto Scrubs
care_autoScrub="true"

# Auto Snapshots
care_autoSnapshot_enabled="true"
care_autoSnapshot_frequent="8"   # Take a snapshot every 15 minutes and keep 8 in rotation
care_autoSnapshot_hourly="0"
care_autoSnapshot_daily="7"      # Take a daily snapshot and keep 7 in rotation
care_autoSnapshot_weekly="0"
care_autoSnapshot_monthly="0"

# Auto Garbage Collection
care_gc_automatic="true"
care_gc_dates="daily"
care_gc_options="--delete-older-than 7d"

# Auto /tmp clean
care_cleanTmpDir="true"
```

## Optional overlays
If you want to override the default Themelios __zpool_create() or __datasets_create() functions with your own code, then set the optional variables in your configuration.sh,
```bash
####################
# Overlay Section #
####################

# If set, Themelios will source them if the files exist alongside configuration.sh
POOL_OVERLAY_FILE="overlay-pool"         # Override __zpool_create()
DATASETS_OVERLAY_FILE="overlay-datasets" # Override __datasets_create()
```
And then create the files and place them alongside wherever your configuration.sh is :)

## Last things
If you have special [post nixos-install] needs and do not want the script to automatically umount /mnt, export zpool, and ask to reboot, pass NOUMOUNT=1 to the script.
```bash
[root@nixos:~] NOUMOUNT=1 themelios foo bar ...
```

## Debugging
If something goes haywire and you just want to start the process all over without rebooting the machine, you could try the following:
```bash
[root@nixos:~] STARTOVER=1 POOL_NAME=zroot themelios foo bar
```
## Making contributions
Check out the [What Themelios does not do](https://github.com/a-schaefers/themelios#what-themelios-does-not-do-yet) section and make PR's. I appreciate all the help I can get!

Thank you!
