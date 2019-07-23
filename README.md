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
### Themelios 2.0
Native ZFS encryption is now supported for both legacy and UEFI systems. Script cleaned and options simplified.

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

**TL;DR. Feed Themelios a git repository url that contains a [configuration.sh](https://github.com/a-schaefers/themelios/blob/testing/example_configuration.sh) file:**

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

### home-manager: a common source of bootstrap fails
At present, if the bootstrap fails due to home-manager, I comment out home-manager section of my configuration in /mnt during the initial bootstrap. Once rebooted, (and so out of the chroot), then I uncomment it and nixos-rebuild switch again.
