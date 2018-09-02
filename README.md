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
- Currently uefi is unsupported. (UEFI does not allow for "pure" zfs-on-root systems and therefore using legacy bios with zfs boot environments is a more robust solution.)
- Configure more than one pool.
- Write zeros to more than one disk concurrently.
- Full Disk encryption (kinda just waiting for zfsonlinux to hit maturity in this area...)
- **Include the beadm script and with full beadm and nix grub integration on the bootloader. [There are big plans ahead!](https://github.com/a-schaefers/grubbe-mkconfig)**
- Posix. My bash-fu is an ongoing work-in-progress. Anyone who can help in this area with pull-requests, I'd appreciate it!

## Try it in it a VM right now!
- From a NixOS LiveDisk VM, download the themelios script and execute:
```bash
[root@nixos:~] themelios vm-example a-schaefers/themelios
```
This command will download the a-schaefers/themelios repo from github, find the "vm-example" directory with a configuration.sh file and begin the bootstrap process with no-questions-asked.

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
[root@nixos:~] themelios ./hosts/vm-example/configuration.sh a-schaefers/themelios
```

So basically, feed Themelios a file which [only] contains the following configuration variables:
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
THEMELIOS_ZFS_CARE="false"

####################
# ZFS_CARE Options #
####################

# Auto Scrubs
care_autoScrub="true"

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

## Optional overlays
##### This is about to change, will use the git repo to store the overlays shortly.
If you want to override the Themelios __zpool_create() or __datasets_create() functions with custom pool creation settings or a custom dataset layout just place the optional **/root/themelios-pool** or **/root/themelios-datasets** files on to the live disk and populate their contents with your custom code.

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

## Hacking the script
If you want to help make Themelios better, try to put everything in a function and call the functions at the end of file. This makes commenting out blocks of code easier and adding early exits to test sections of the script. Try to use variable and function names that explain the code as it executes so that we don't need too many comments.

## Making contributions
Check out the [What Themelios does not do](https://github.com/a-schaefers/themelios#what-themelios-does-not-do-yet) section and make PR's. I sure would appreciate all the help I can get!

Thank you! :)
