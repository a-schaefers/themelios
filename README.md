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
    - Aims to fail gracefully with continue and retry options, and helpful debug parameters.
    - A simple script, easy to hack on.

## What does it not do
    - Currently uefi is unsupported, mainly because I'm lazy to implement it and I feel that legacy is more robust.
    - Configure than one pool.

    (PR's accepeted!)

## Configuration.sh Variables:
```bash
Available variables to be set:

TOP_LEVEL_NIXFILE  => Your top-level configuration.nix file relative path from the project_root.
                      e.g. for the file project_root/hosts/hpZ620/default.nix use the following:
                      TOP_LEVEL_NIXFILE="hosts/hpZ620/default.nix"

    NOTE: This variable is used as an import in /etc/nixos/configuration.nix.

NIXCFG_DIR         => Directory name of <git-remote> in "/" (root). Do not use slashes.

POOL_NAME          => e.g. POOL_NAME="zroot" or POOL_NAME="rpool"

POOL_TYPE          => may be "" for single disk, or mirror/raidz1/raidz2/raidz3

POOL_DISKS         => Separate each disk with line breaks,  e.g.
POOL_DISKS="/dev/sda
/dev/sdb
/dev/sdc"

WIPEFS_ALL         => use "true" or "false" (Runs wipefs --all)

SGDISK_CLEAR       => use "true" or "false" (Runs sgdisk --clear)

ZERO_DISKS         => use "true" or "false" (Runs dd if=/dev/zero ...)

ATIME              => Set to "on" or "off" (Setting to "off" is recommended for SSD)

SNAPSHOT_ROOT      => use "true" / "false" or "" (Sets the value of com.sun:auto-snapshot for /)

SNAPSHOT_HOME      => use "true" / "false" or "" (Sets the value of com.sun:auto-snapshot for /home)

USE_ZSWAP          => use "true" / "false" (Creates a swap zvol)

ZSWAP_SIZE         => e.g. ZSWAP_SIZE="4G"

NIXDIR_NOROOT      => use "true" / "false" (Mounts /nix outside of the ROOT dataset, not recommended.)
```
