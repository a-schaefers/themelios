# Themelios configuration.sh example

# DISK PREPARATION SETTINGS #

use_sgdisk_clear="true"    # use sgdisk --clear
use_wipefs_all="true"      # use wipefs --all
use_zero_disks="false"     # use dd if=/dev/zero ...

# ZFS POOL SETTINGS #

zfs_pool_name="zroot"
zfs_pool_type=""           # use "" for single, or "mirror", "raidz1", etc.

# Note: using /dev/disk/by-id is also preferable.
zfs_pool_disks=("/dev/sda")

# Datasets to be set with com.sun:auto-snapshot=true.
zfs_auto_snapshot=("$zfs_pool_name/HOME" "$zfs_pool_name/ROOT")

# If true, mount /nix outside of the / (root) dataset.
# Recommended true for now due to https://github.com/a-schaefers/themelios/issues/1
zfs_dataset_slashnix_no_root="true"

# Todo allow true or false for this exception.
zfs_use_atime="off"              # set to "on" or "off" (recommended "off" for ssd.)

zfs_make_swap="false"            # creates a swap zvol (Not recommended in zfs-land.)
zfs_swap_size="4G"

# If set, themelios will source them if the files exist alongside configuration.sh
zfs_pool_overlay_file=""         # override zpool_create()
zfs_dataset_overlay_file=""      # override datasets_create()
postinstall_overlay_file=""      # run arbritary code after nixos-install and before umount /mnt.

# NIX_OS BOOTSTRAP SETTINGS #

# Your top-level configuration.nix file to be bootstrapped-- (use the relative path from the project_root.)
# For example, to bootstrap project_root/hosts/vm-example/default.nix
nix_top_level_configuration="hosts/vm-example"

# Directory name of to clone your git-remote in "/" (root). Do not use slashes.
# This is intended to be the directory to operate the nix installation from.
# For example, here is mine! https://github.com/a-schaefers/nix-config
nix_repo_name="nix-config"

# Creates /etc/nixos/zfs-configuration.nix with sensible settings.
nix_zfs_configuration_enabled="true"

# Enable "extra" options [below] in addition to zfs_configuration?
nix_zfs_configuration_extra_enabled="true"

# Enables periodic scrubbing of ZFS pools.
nix_zfs_extra_auto_scrub="true"

# Enable the (OpenSolaris-compatible) ZFS auto-snapshotting service.
nix_zfs_extra_auto_snapshot_enabled="true"
nix_zfs_extra_auto_snapshot_frequent="8"   # take a snapshot every 15 minutes and keep 8 in rotation
nix_zfs_extra_auto_snapshot_hourly="0"
nix_zfs_extra_auto_snapshot_daily="7"      # take a daily snapshot and keep 7 in rotation
nix_zfs_extra_auto_snapshot_weekly="0"
nix_zfs_extra_auto_snapshot_monthly="0"

# Use NixOs automatic garbage collection?
nix_zfs_extra_gc_automatic="true"
nix_zfs_extra_gc_dates="weekly"
nix_zfs_extra_gc_options="--delete-older-than 30d"

# Clean /tmp automatically on boot.
nix_zfs_extra_clean_tmp_dir="true"
