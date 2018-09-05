# themelios configuration.sh example

# disk preparation settings #

use_sgdisk_clear="true"    # use sgdisk --clear
use_wipefs_all="true"      # use wipefs --all
use_zero_disks="false"     # use dd if=/dev/zero ...

# zfs pool settings #

zfs_pool_name="zroot"
zfs_pool_type="mirror"     # e.g. change to "" for single disk, or maybe "raidz1" with 3 disks. :)

# separate each disk using new lines. (note: using /dev/disk/by-id is also preferable.)
zfs_pool_disks="/dev/sda"

# datasets to be set with com.sun:auto-snapshot=true (separate with new lines.)
zfs_auto_snapshot="$zfs_pool_name/HOME
$zfs_pool_name/ROOT"

# if true, mount /nix outside of the / (root) dataset.
# setting this to true would trade-off the ability to use zfs boot environments for extra disk space.
# if you use nix.gc.automatic, then this should not be much of an issue. recommended "false".
zfs_dataset_slashnix_no_root="false"

# todo allow true or false for this exception.
zfs_use_atime="off"              # set to "on" or "off" (recommended "off" for ssd.)

zfs_make_swap="false"            # creates a swap zvol
zfs_swap_size="4G"

# if set, themelios will source them if the files exist alongside configuration.sh
zfs_pool_overlay_file=""         # override zpool_create()
zfs_dataset_overlay_file=""      # override datasets_create()

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
