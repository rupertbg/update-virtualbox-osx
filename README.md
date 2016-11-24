# update-virtualbox-osx
A bash script to update VirtualBox and the extension pack automagically on OS X

## How do I use it?
Run the script from terminal `./update-virtualbox-osx.sh`
## What does it do?
The script basically runs through the following operations:

  1. Gets your local VirtualBox app version from `/Applications/VirtualBox.app`
  2. Reads in `LATEST.TXT` from official VirtualBox repo
  3. Finds the latest version `.dmg` and `.vbox-extpack`
  4. Compares app version against download version (x > y with . delimiter)
  5. Downloads, mounts and runs `.pkg` to install VirtualBox if an update or install is required
  6. Checks for `VBoxManage`, needed to install ext-pack
  7. Compares local ext-pack version
  8. Downloads and installs `.vbox-extpack` using `VBoxManage` if an update or install is required

(All downloads are from http://download.virtualbox.org/virtualbox/)
