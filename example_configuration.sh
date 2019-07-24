# Themelios configuration.sh example

# configuration.sh file example variables:
# note: DO NOT EDIT THEMELIOS DIRECTLY... That would be missing the whole point.
# create a configuration.sh with the following variables, e.g. as follows:
use_sgdisk_clear="true" # use sgdisk --clear
use_wipefs_all="true"   # use wipefs --all
use_zero_disks="false"  # use dd if=/dev/zero ...
zfs_pool_name="rpool"
zfs_pool_disks=("/dev/sda" "/dev/sdb") # Note: using /dev/disk/by-id is also preferable.
zfs_pool_type="mirror"  # use "" for single, or "mirror", "raidz1", etc.
zfs_auto_snapshot=("$zfs_pool_name/HOME" "$zfs_pool_name/ROOT") # datasets to be set with com.sun:auto-snapshot=true
nix_top_level_configuration="hosts/Z620" # Your top-level nix file to be bootstrapped
nix_repo_name="nix-config" # For example, here is mine! https://github.com/a-schaefers/nix-config
nix_zfs_configuration_extra_enabled="false" # uncomment below if set to true
# nix_zfs_extra_auto_scrub="true"
# nix_zfs_extra_auto_snapshot_enabled="true" # Enable the ZFS auto-snapshotting service
# nix_zfs_extra_auto_snapshot_frequent="8"
# nix_zfs_extra_auto_snapshot_hourly="24"
# nix_zfs_extra_auto_snapshot_daily="0"
# nix_zfs_extra_auto_snapshot_weekly="0"
# nix_zfs_extra_auto_snapshot_monthly="0"
# nix_zfs_extra_auto_optimise_store="true"
# nix_zfs_extra_gc_automatic="true"
# nix_zfs_extra_gc_dates="weekly"
# nix_zfs_extra_gc_options="--delete-older-than 7d"
# nix_zfs_extra_clean_tmp_dir="true"
