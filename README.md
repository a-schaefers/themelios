# themelios
Bootstrap a zfs-on-root NixOS configuration in one command

```bash
usage() {
    cat << EOF
Usage: themelios <configuration.sh> <git remote> <branch (optional)>

One example:

       themelios configuration.sh https://github.com/a-schaefers/nix-config.git master

Github users may also use a shorthand:

       themelios configuration.sh a-schaefers/nix-config

Use -h or --help for more instructions.
EOF
    exit
}

help() {
    cat <<EOF
Themelios - Bootstrap a zfs-on-root NixOS in one command.

Usage: themelios <configuration.sh> <git remote> <branch (optional)>

One example:

       themelios configuration.sh https://github.com/a-schaefers/nix-config.git master

Github users may also use a shorthand:

       themelios configuration.sh a-schaefers/nix-config

Store all machine-specific settings in bash variables in a separate <configuration.sh> script in your <git repo>.
Themelios will clone the repo, source the script, configure a zfs-on-root system to your specification,
and finally bootstrap your system by importing your NixOS configuration.nix setup. Use relative path imports!

Configuration.sh:
The "configuration.sh" file may be named anything and located anywhere in the project_root.

Available variables to be set:

          TOP_LEVEL_NIXFILE  => Your top-level configuration.nix file relative path from the project_root.
                             e.g. for the file project_root/hosts/hpZ620/default.nix use the following:
                             TOP_LEVEL_NIXFILE="hosts/hpZ620/default.nix"

                             NOTE: This variable is used as an import in /etc/nixos/configuration.nix.

          NIXCFG_DIR         => Directory name of <git-remote> in "/" (root). Do not use slashes.

          POOL_NAME          => e.g. POOL_NAME="zroot" or POOL_NAME="rpool"

          POOL_TYPE          => may be "" for single disk, or mirror/raidz1/raidz2/raidz3

          POOL_DISKS         => Separate each disk with line breaks, and I recommend using /dev/disk/by-id,
                             e.g. POOL_DISKS="/dev/sda
                             /dev/sdb
                             /dev/sdc"

          POOL_HOSTID        => Use 8-digit hexadecimal or simply POOL_HOSTID="random"

          WIPEFS_ALL         => use "true" or "false"

          SGDISK_CLEAR       => use "true" or "false"

          ZERO_DISKS         => use "true" or "false"

          ATIME              => Set to "on" or "off" (Setting to "off" is recommended for SSD)

          SNAPSHOT_ROOT      => use "true" / "false" or "" (Sets the value of com.sun:auto-snapshot)

          SNAPSHOT_HOME      => use "true" / "false" or "" (Sets the value of com.sun:auto-snapshot)

          USE_ZSWAP          => use "true" / "false" (Creates a swap zvol)

          ZSWAP_SIZE         => e.g. ZSWAP_SIZE="4G"
EOF
    exit
}
```
