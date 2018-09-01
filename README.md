# Themelios
Bootstrap a zfs-on-root NixOS configuration in one command

![Themelios NixOS Screenshot](https://github.com/a-schaefers/themelios/raw/master/themelios_usage.png)

## What Themelios does
From any NixOS live disk, Themelios will do the following in approximate order:
- Automatically installs zfs and git to the livedisk if needed.
- Clones your git repo, optionally using a non-master branch.
- Finds your configuration.sh file automatically.
- Configures a zfs-on-root system to your configuration.sh file specification including the following options:
  * Uses sgdisk and/or wipefs, or dd to clear your disks.
  * Creates a single/mirror/raidz1/raidz2/raidz3 zpool
  * Configures a zfs-on-root dataset scheme by default
  * Generates an /etc/nixos/configuration.nix which imports your top-level-nixfile from your repo.
  * Optionally generates and imports an /etc/nixos/themelios-zfs.nix which includes essential settings for zfs-on-root.
  * Bootstraps your top level .nix configuration and installs the rest of your operating system
- Aims to fail gracefully with continue and retry options.
- A simple script, easy to hack on.

## What Themelios does not do (yet)
- Currently uefi is unsupported. (imho using legacy bios with zfs boot environments is more robust.)
- Configure more than one pool.
- Write zeros to more than one disk concurrently.
- Full Disk encryption (kinda just waiting for zfsonlinux to hit maturity in this area...)
- **Include the beadm script and with full beadm and nix grub integration on the bootloader. [There are big plans ahead!](https://github.com/a-schaefers/grubbe-mkconfig)**
- Posix. My bash-fu is an ongoing work-in-progress. Anyone who can help in this area with pull-requests, I'd appreciate it!

## Try it in it a VM right now!
- From a NixOS LiveDisk VM, download the themelios script and execute:
```bash
[root@nixos:~]# ./themelios vm-config.sh a-schaefers/themelios
```
This command will download the a-schaefers/themelios repo from github, then search the project for a file by the name of "vm-config.sh" and begin the bootstrap process with no-questions-asked.

## configuration.sh
Configuration.sh may actually be named anything you want and located anywhere in your project, Themelios will find it automatically. This allows for using multiple, per-machine configuration.sh files, provided they are uniquely named.
```bash
# Themelios configuration.sh example
POOL_NAME="zroot"
POOL_TYPE="raidz1"    # May also be set to "mirror". Leave empty "" for single.

# use one disk per line here!
POOL_DISKS="/dev/sda
/dev/sdb
/dev/sdc"

SGDISK_CLEAR="true"   # Use sgdisk --clear
WIPEFS_ALL="true"     # Use wipefs --all
ZERO_DISKS="false"    # Use dd if=/dev/zero ...
ATIME="off"           # Set to "on" or "off" (recommended "off" for SSD.)
SNAPSHOT_ROOT="true"  # Set the value of com.sun:auto-snapshot
SNAPSHOT_HOME="true"
USE_ZSWAP="false"     # Creates a swap zvol
ZSWAP_SIZE="4G"

# Your top-level configuration.nix file-- (use the relative path from the project_root.)
# For example, to bootstrap the file project_root/hosts/vm-example/default.nix use the following:
TOP_LEVEL_NIXFILE="hosts/vm-example"

# Directory name of <git-remote> in "/" (root). Do not use slashes.
NIXCFG_DIR="nix-config"

# If true, mount /nix outside of the / (root) dataset.
# Setting this to true would trade-off the ability to use zfs boot environments for extra disk space.
# If you use nix.gc.automatic, then this should not be much of an issue. Recommended "false".
NIXDIR_NOROOT="false" # mount /nix outside of the / (root) dataset.

# Creates /etc/nixos/themelios-zfs.nix with sensible settings
THEMELIOS_ZFS="true"

# "Zfs Care" section - If enabled, will append additional settings and services to themelios-zfs.nix
THEMELIOS_ZFS_CARE="false"
```

## themelios-zfs.nix
If THEMELIOS_ZFS="true" in a configuration.sh file, Themelios will create /etc/nixos/themelios-zfs.nix with sensible zfs-on-root settings:
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
If THEMELIOS_ZFS_CARE="true", Themelios will configure and append the following additional settings and services to themelios-zfs.nix
```bash
####################
# ZFS_CARE Options #
####################

# The following options are only applicable if both THEMELIOS_ZFS="true" and THEMELIOS_ZFS_CARE="true"

# Auto Scrubs
care_autoScrub="true" # Set services.zfs.autoScrub.enable = true;

# Auto Snapshots
care_autoSnapshot_enabled="true"
care_autoSnapshot_frequent="8" # Take a snapshot every 15 minutes and keep 8 in rotation
care_autoSnapshot_hourly="0"
care_autoSnapshot_daily="7" # Take a daily snapshot and keep 7 in rotation
care_autoSnapshot_weekly="0"
care_autoSnapshot_monthly="0"

# Auto Garbage Collection
care_gc_automatic="true"
care_gc_dates="daily"
care_gc_options="--delete-older-than 7d"

# Auto /tmp clean
care_cleanTmpDir="true"
```
