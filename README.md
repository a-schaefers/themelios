# themelios
Bootstrap a zfs-on-root NixOS configuration in one command

```bash
usage() {
    cat << EOF
Usage: themelios <configuration.sh> <git remote> <branch (optional)>

The "configuration.sh" file may be named anything and located anywhere in the project_root.

One example:

       themelios configuration.sh https://github.com/a-schaefers/nix-config.git master

Github users may also use a shorthand:

       themelios configuration.sh a-schaefers/nix-config

Use -h or --help for more instructions.
EOF
    exit
}
```

## What does it do
From any NixOS live disk, Themelios will do the following in approximate order:
- Automatically installs zfs and git to the livedisk if needed.
- Clones your git repo, optionally using a non-master branch.
- Finds your configuration.sh file automatically.
- Configures a zfs-on-root system to your configuration.sh file specification including the following options:
  * Use sgdisk and/or wipefs, or dd to clear your disks.
  * Creates a single/mirror/raidz1/raidz2/raidz3 zpool
  * Configure a zfs-on-root dataset scheme by default
  * Bootstrap your top level .nix configuration and install the rest of your operating system
- Aims to fail gracefully with continue and retry options.
- A simple script, easy to hack on.

## What does it not do
- Currently uefi is unsupported.
- Configure more than one pool.
- Write zeros to more than one disk concurrently.
- Full Disk encryption (kinda just waiting for zfsonlinux to hit maturity on this.)

(PR's accepeted!)

## Configuration.sh Variables:
```bash
# Themelios configuration.sh example
POOL_NAME="zroot"
POOL_TYPE="raidz1"    # May also be set to "mirror". Leave empty "" for single.

# use one disk per line here!
POOL_DISKS="/dev/sda
/dev/sdb
/dev/sdc"

SGDISK_CLEAR="true"   # Use sgdisk --clear
WIPEFS_ALL="true"     # wipefs --all
ZERO_DISKS="false"    # uses dd if=/dev/zero ...
ATIME="off"           # recommended "off" for SSD disks.
SNAPSHOT_ROOT="true"  # Sets the value of com.sun:auto-snapshot
SNAPSHOT_HOME="true"
USE_ZSWAP="false"     # Creates a swap zvol
ZSWAP_SIZE="4G"

# Your top-level configuration.nix file relative path from the project_root.
# e.g. for the file project_root/hosts/hpZ620/default.nix use the following:
TOP_LEVEL_NIXFILE="hosts/hpZ620/default.nix"

# Directory name of <git-remote> in "/" (root). Do not use slashes.
NIXCFG_DIR="nix-config"
```

## Debug options:
See the end of the script for details.
