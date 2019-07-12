# Themelios - NixOS on a rock-solid ZFS foundation.
Bootstrap a zfs-on-root NixOS configuration in one command.

![Themelios NixOS Screenshot](https://github.com/a-schaefers/themelios/raw/master/themelios_usage.png)

## From any NixOS live disk, Themelios
- Automatically installs zfs and git to the livedisk if needed.
- Clones your git repo, optionally using a non-master branch.
- Finds your configuration.sh file automatically.
- Configures a zfs-on-root system to your configuration.sh file specification including the following options:
  * Uses sgdisk and/or wipefs, or dd to clear your disks.
  * Creates a single/mirror/raidz1/raidz2/raidz3 zpool.
  * Configures a zfs-on-root dataset scheme by default.
  * Optionally generates and imports an /etc/nixos/themelios-zfs.nix which includes sensible settings for zfs-on-root.
  * Optional "zfs-extra" enables further zfs-support options in NixOS.
  * Optional "overlay" feature allows easy custom pool creation settings and dataset scheme changes without need to hack on the script directly.
- Generates an /etc/nixos/configuration.nix which imports your top-level-nixfile from your repo-- (and thereby nixos-install's the rest of your operating system.)
- Aims to fail gracefully with continue and retry options.
- **Legacy** *and* **UEFI** are now both supported.
- **ZFS native-encryption is now possible**
  * See below for details...

## NEWS
### How to sync the systemd-boot (UEFI) boot loaders across multiple (ie. mirrored) disks
- Fri Jul 12 15:11:07 PDT 2019

See the end of this readme.md for information regarding how to do this in a very simple way.

### How to manually convert $HOME to use native ZFS encryption
- Sun May  5 01:58:45 PDT 2019

To use *native zfs-encryption*, use a UEFI bios system. This is needed because themelios will default to using systemd-boot with UEFI, (as GRUB does not support zfs-encryption yet...), and then install using themelios as normal, however, add the following nixos options to your configuration.nix:

```nix
boot.zfs.enableUnstable = true;
boot.zfs.requestEncryptionCredentials = true;
```

After successful installation, simply enable zfs native encryption features by doing a pool upgrade, then you should be able to create zfs native encrypted datasets. I recommend then recreating your $HOME dataset using an encrypted dataset. Be careful to ensure your /etc/nixos/hardware-configuration.nix file is accurate. Finally run a nixos-rebuild switch and reboot. It should ask your for your $HOME dataset password on the next reboot. Good luck.

The commands to convert $HOME to using zfs encryption should be as follows:
```bash
zpool upgrade -a && zfs upgrade -a
reboot

zfs destroy -r rpool/HOME/home # remember to make BACKUPS first!
zfs create -o mountpoint=legacy -o encryption=on -o keyformat=passphrase rpool/HOME/home
mount -t zfs rpool/HOME/home /home # just to confirm everything works before the next reboot...
zfs set com.sun:auto-snapshot=true rpool/HOME/home # if you intended to use zfs auto-snapshot...
zpool set autotrim=on rpool # if you are using SSD...
nixos-rebuild switch
reboot
```

If that doesn't work, report what happened and if you got it working, how you got it working in issue #3:
https://github.com/a-schaefers/themelios/issues/3

In the (distant) future, I plan to make this an option to be selected from within the install script itself.

## Try it in it a VM right now!
- From a NixOS LiveDisk VM,
```bash
[root@nixos:~] bash <(curl https://raw.githubusercontent.com/a-schaefers/themelios/master/themelios) vm-example a-schaefers/themelios
```
This command executes the script with curl and bash, which in turn downloads the a-schaefers/themelios repo from github, finds the "vm-example" directory with a configuration.sh file and begins the bootstrap process.

## "configuration.sh" [so-called]
Configuration.sh may actually be named anything you want and located anywhere in your project, Themelios will search for $1 by filename first and find it automatically, provided it is a uniquely named file.

If the filename isn't found, then Themelios will search for directories by the same name. So if you prefer using a standard naming convention, put a literal "configuration.sh" file inside of a uniquely named directory and feed Themelios the unique directory name.
The example "Try it init a VM right now!" command of this repository uses this method:
```bash
# vm-example is not a file inside this repo, but is a directory-- so this finds the dir hosts/vm-example/ and loads thel literal "configuration.sh" file.
[root@nixos:~] themelios vm-example a-schaefers/themelios
```

If none of this works for you, just tell themelios where the file is relative to project root:
```bash
[root@nixos:~] themelios ./hosts/vm-example/configuration.sh https://github.com/a-schaefers/themelios.git master
```

_NOTE: The username/repo-name shortcut only works for Github repos. Non-Github repos must provide the full remote._

**TL;DR. Feed Themelios a git repository url that contains a file which has the following configuration variables:**
```bash
# Themelios configuration.sh example

# DISK PREPARATION SETTINGS #

use_sgdisk_clear="true"    # use sgdisk --zap-all
use_wipefs_all="true"      # use wipefs --all
use_zero_disks="false"     # use dd if=/dev/zero ...

# ZFS POOL SETTINGS #

zfs_pool_name="rpool"
zfs_pool_type="mirror"     # use "" for single, or "mirror", "raidz1", etc.

# Note: using /dev/disk/by-id is also preferable.
zfs_pool_disks=("/dev/sda" "/dev/sdb")

# Datasets to be set with com.sun:auto-snapshot=true.
zfs_auto_snapshot=("$zfs_pool_name/HOME" "$zfs_pool_name/ROOT")

# If true, mount /nix outside of the / (root) dataset.
# Recommended true for now due to https://github.com/a-schaefers/themelios/issues/1
zfs_dataset_slashnix_no_root="true"

zfs_make_swap="false"            # creates a swap zvol (Not recommended in zfs-land.)
zfs_swap_size="4G"

# If set, themelios will source them if the files exist alongside configuration.sh
zfs_pool_overlay_file=""         # override zpool_create()
zfs_dataset_overlay_file=""      # override datasets_create()

# NIX_OS BOOTSTRAP SETTINGS #

# Your top-level configuration.nix file to be bootstrapped-- (use the relative path from the project_root.)
# For example, to bootstrap project_root/hosts/vm-example/default.nix
nix_top_level_configuration="hosts/vm-example"

# Directory name of to clone your git-remote in "/" (root). Do not use slashes.
# This is intended to be the directory to operate the nix installation from.
# For example, here is mine! https://github.com/a-schaefers/nix-config
nix_repo_name="nix-config"

# Optionally inserted as "nixos-install --root /mnt $nix_install_opts"
nix_install_opts=""

# Creates /etc/nixos/zfs-configuration.nix with sensible settings.
nix_zfs_configuration_enabled="true"

# Enable "extra" options [below] in addition to zfs_configuration?
nix_zfs_configuration_extra_enabled="true"
```

## Optional overlays
If you want to override the default Themelios zpool_create() or datasets_create() functions with your own code, then set the optional variables in your configuration.sh,
```bash
# If set, themelios will source them if the files exist alongside configuration.sh
zfs_pool_overlay_file=""         # override zpool_create()
zfs_dataset_overlay_file=""      # override datasets_create()
```
Create the files and place them alongside wherever your configuration.sh is.
The [vm-example in this repo](https://github.com/a-schaefers/themelios/tree/master/hosts/vm-example)
uses stock pool and dataset overlays by default. :)

You can also set the postinstall_overlay_file in the same way,
```bash
postinstall_overlay_file=""      # run arbritrary code after nixos-install and before umount /mnt.
```
The following is an example using [postinstall_overlay_file that mounts a usb stick and copies my Private keys to my dotfiles](https://github.com/a-schaefers/nix-config/blob/master/hosts/latitude/postinstall.sh).

## zfs-configuration.nix
If **nix_zfs_configuration_enabled="true"** in a configuration.sh file, Themelios will create /etc/nixos/zfs-configuration.nix with the following zfs-on-root settings:
```bash
{ ... }:
{ imports = [];

# Configure grub with zfs support.
boot.supportedFilesystems = [ "zfs" ];
boot.loader.grub.enable = true;
boot.loader.grub.version = 2;
boot.loader.grub.devices = [
$(for disk_id in "${zfs_pool_disks[@]}"
do
echo "\"$disk_id\""
done)
];

# The 32-bit host id of the machine, formatted as 8 hexadecimal characters.
# You should try to make this id unique among your machines.
networking.hostId = "$zfs_host_id";

# noop, the recommended elevator with zfs.
# shell_on_fail allows to force import manually in the case of zfs import failure.
boot.kernelParams = [ "elevator=noop" "boot.shell_on_fail" ];

# Grub on zfs has been known to have a hard time finding kernels with really/long/dir/paths.
# Copy the kernels to /boot and avoid the issue.
boot.loader.grub.copyKernels = true;

# Uncomment [on a working system] to ensure extra safeguards are active that zfs uses to protect zfs pools:
#boot.zfs.forceImportAll = false;
#boot.zfs.forceImportRoot = false;
}

```

## Additional configuration.sh settings - zfs extra
Enable **nix_zfs_configuration_extra_enabled="true"** in addition to **nix_zfs_configuration_enabled="true"** in configuration.sh for the following extras:
```bash
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
```

## Last things
If you have special [post nixos-install] needs and do not want the script to automatically umount /mnt, export zpool, and ask to reboot, pass NOUMOUNT=1 to the script.
```bash
[root@nixos:~] NOUMOUNT=1 themelios foo bar ...
```

## Debugging
### How to start over again from the beginning...
If something goes haywire and you just want to start the process all over without rebooting the machine, you could try the following:
```bash
[root@nixos:~] STARTOVER=1 POOL=rpool themelios foo bar
```

### fetchTarball currently does not work ...
While Themelios aims to fail gracefully, if the initial bootstrap fails and if there is not an error in your nix files, one commonly known cause of failure is use of fetchTarball. Using fetchTarball does not work during new NixOS installations. This is not Themelios' fault! Here's the NixOS bug that is already reported: https://github.com/NixOS/nix/issues/2405

## Build Themelios into a custom NixOS rescue iso
Save the following somewhere on an already existing NixOS install as iso.nix:
```nix
{config, pkgs, ...}:
let
  themelios = pkgs.writeScriptBin "themelios" ''
    bash <(curl https://raw.githubusercontent.com/a-schaefers/themelios/master/themelios) $@
  '';
in {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  networking = {
    networkmanager.enable = true;
    wireless.enable = false; #networkmanager.enable handles this
  };
    boot.supportedFilesystems = [ "zfs" ];
  environment.systemPackages = with pkgs; [ git themelios ];
}
```

And build it!
```bash
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix
```

The generated iso will be found inside the newly created "result/" directory.

_Note: It would be best practice to fork the project, audit the script, and modify the curl url to use your fork._ :)

## Putting it all together (a real-world example)
While I do not regard my personal setup to be the ideal for everybody, what follows is to show-case
[how Themelios can be used to bootstrap multiple, per-machine configurations](https://github.com/a-schaefers/nix-config).
The goal was simplicity, efficiency, and reproducibility.

## How to sync the systemd-boot (UEFI) boot loaders across multiple (ie. mirrored) disks
One limitation of UEFI / ESP's is that you cannot raid the ESP, and so it is required that /boot be mounted as fat32, outside of the zpool. If your primary (e.g. /dev/sda) disk were to fail in a mirrored configuration, by default, (while you wouldn't lose the copy of your zpool on the mirror), you would lose your bootloader because the mirrored (e.g. /dev/sdb disk) would not have a copy of the /boot files on its ESP. In any case, it may be worked around by copying all of the files from /boot on the /dev/sda disk to /boot on the /dev/sdb disk every time the files in /boot on the /dev/sda disk are changed. I have created a system service that does this.

On my UEFI mirrored machines, I mount the ESP of the mirror to "/boot2" in /etc/nixos/hardware-configuration.nix

```bash
mkdir /boot2
mount /dev/sdb2 /boot2
nixos-generate-config
```

Now in configuration.nix create the system service,

```nix
{ config, ... }:
# this is a workaround
# UEFI ESP's have a limitation in that they cannot RAID.
# this script monitors /boot for changes; and upon change, copies the files to /boot2
# this keeps the systemd-boot loader in sync for multi-disk arrays.
let
copyBootScript = pkgs.writeScriptBin "copyBootScript" ''
while inotifywait -r -e modify,create,delete /boot
do
rm -rf /boot2/* ; cp -a /boot/* /boot2
done
'';
in
{
imports = [  ];

systemd.services.copy-boot = {
path = [ pkgs.inotify-tools ];

after = [ "multi-user.target" ];
wantedBy = [ "multi-user.target" ];
script = "${copyBootScript}/bin/copyBootScript";
serviceConfig = {
User = "root";
};
};

systemd.services.copy-boot.enable = true;

}
```

Finally update the system so that /dev/sdb2 will be mounted on boot and the copy-boot service will be enabled.

```bash
nixos-rebuild switch
```

Now you should be able to `plug and play' the /dev/sdb hard drive anywhere and atleast you will be able to select and boot the current loader from the bios, in emergency situations.
