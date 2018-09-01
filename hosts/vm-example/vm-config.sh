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

# "zfs.care" section - If enabled, will append additional settings and services to themelios-zfs.nix
THEMELIOS_ZFS_CARE="false"

####################
# ZFS_CARE Options #
####################

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
