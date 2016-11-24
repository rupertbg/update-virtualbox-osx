#!/bin/bash

############################
## VirtualBox Auto Update ##
############################

## VirtualBox App Location ##
APPLOCATION="/Applications/VirtualBox.app/"

## Temp storage ##
TMPLOC="/tmp/vbupdate"

## VirtualBox Repo ##
LOCATION="http://download.virtualbox.org/virtualbox"

## Versions ##
LOCALVERSION=`mdls -name kMDItemVersion $APPLOCATION | grep -Eo '".*"' | tr -d '"'`
ONLINEVERSION=`curl -s $LOCATION/LATEST.TXT`

## VirtualBox Installer ##
DMG=`curl -s $LOCATION/$ONLINEVERSION/ | grep -i '\.dmg\>' | grep -Eo '".*"' | tr -d '"'`
DMGDOWNLOAD="$LOCATION/$ONLINEVERSION/$DMG"

## Extension pack ##
VBMANAGE="/usr/local/bin/VBoxManage"
EXTPACK=`curl -s $LOCATION/$ONLINEVERSION/ | grep -i '\.vbox-extpack\>' | grep -Eo '".*"' | tr -d '"'`
EXTPACKDOWNLOAD="$LOCATION/$ONLINEVERSION/$EXTPACK"

## Version comparison function ##
LOCALMAJOR=`echo $LOCALVERSION | cut -d. -f1`
ONLINEMAJOR=`echo $ONLINEVERSION | cut -d. -f1`
LOCALMINOR=`echo $LOCALVERSION | cut -d. -f2`
ONLINEMINOR=`echo $ONLINEVERSION | cut -d. -f2`
LOCALPATCH=`echo $LOCALVERSION | cut -d. -f3`
ONLINEPATCH=`echo $ONLINEVERSION | cut -d. -f3`
##if [ ${#LOCAL} -lt 4 ] || [ ${#ONLINE} -lt 4 ]; then
##  l=$((4 - ${#LOCAL}))
##  o=$((4 - ${#ONLINE}))
##  for (( i = 0; i < $l; i++ )); do
##    LOCAL="${LOCAL}0"
##  done
##  for (( i = 0; i < $o; i++ )); do
##    ONLINE="${ONLINE}0"
##  done
##fi
if [[ "$LOCALVERSION" == "$ONLINEVERSION" ]]; then
  VERSIONRESULT=0
elif [ ${LOCALMAJOR} -lt ${ONLINEMAJOR} ] && [ ${LOCALMINOR} -lt ${ONLINEMINOR} ] && [ ${LOCALPATCH} -lt ${ONLINEPATCH} ]; then
  VERSIONRESULT=1
else
  VERSIONRESULT=2
fi

## VirtualBox downloader & installer ##

installVB () {
  mkdir $TMPLOC
  if [ ! -f "$TMPLOC/$DMG" ]; then
    echo "Downloading latest VirtualBox installer"
    sleep 1
    curl -o "$TMPLOC/$DMG" $DMGDOWNLOAD --progress-bar
  else
    echo "Latest version found locally"
    sleep 1
  fi
  echo "Mounting disk image"
  sleep 1
  hdiutil mount -nobrowse "$TMPLOC/$DMG" -mountpoint "/Volumes/$DMG" > /dev/null
  echo "Running pkg installer with root privileges - enter password if prompted"
  sleep 1
  sudo installer -verboseR -pkg "/Volumes/$DMG/virtualbox.pkg" -target "/"
  rm -rf $TMPLOC
  umount "/Volumes/$DMG"
}

installVBext () {
  mkdir $TMPLOC
  if [ ! -f "$TMPLOC/$EXTPACK"  ]; then
    echo "Downloading extension pack"
    sleep 1
    curl -o "$TMPLOC/$EXTPACK" $EXTPACKDOWNLOAD --progress-bar
  else
    echo "Latest VirtualBox extension pack found locally"
    sleep 1
  fi
  sudo $VBMANAGE extpack install --replace "$TMPLOC/$EXTPACK"
  rm -rf $TMPLOC
}

#### Script begin ####
if [ $ONLINEVERSION ]; then
  echo "Latest version: v$ONLINEVERSION"
  sleep 1
  if [ $VERSIONRESULT -eq 2 ]; then
    echo "Updating VirtualBox from v$LOCALVERSION to v$ONLINEVERSION"
    sleep 1
    installVB
    echo "VirtualBox updated"
    sleep 1
  elif [ ! -e $APPLOCATION ]; then
    echo "Installing VirtualBox v$ONLINEVERSION"
    sleep 1
    installVB
    echo "VirtualBox installed"
    sleep 1
  elif [ $VERSIONRESULT -eq 0 ]; then
    echo "No app update required - Current: v$LOCALVERSION Online: v$ONLINEVERSION"
    sleep 1
  elif [ $VERSIONRESULT -eq 1 ]; then
    echo "Local version appears newer than remote - Current: v$LOCALVERSION Online: v$ONLINEVERSION"
  fi

  if [ ! -f "$APPLOCATION/Contents/MacOS/VBoxManage" ]; then
    echo 'VBoxManage not present - Unable to install extension pack'
    sleep 1
  else
    extpackver=`$VBMANAGE list extpacks | /usr/bin/grep -A 1 'Oracle VM VirtualBox Extension Pack' | grep 'Version:' | sed 's/^.*: //' | tr -d " \t\n\r"`
    if [ $? -ne 0 ]; then
      echo "No extension packs present"
      sleep 1
      echo "Installing extension pack version $ONLINEVERSION"
      sleep 1
      installVBext
    else
      if [ $VERSIONRESULT -eq 2 ]; then
        echo "Updating extension pack to v$ONLINEVERSION"
        installVBext
      elif [ ! $extpackver ]; then
        echo "Installing extension pack v$ONLINEVERSION"
        installVBext
      elif [ $VERSIONRESULT -eq 0 ]; then
        echo "No extension pack update required - Current: v$extpackver Online: v$ONLINEVERSION"
        sleep 1
      elif [ $VERSIONRESULT -eq 1 ]; then
        echo "No extension pack update required - Current: v$extpackver Online: v$ONLINEVERSION"
      fi
    fi
  fi
else
  echo "Unable to locate online VirtualBox version"
  sleep 1
fi
exit 0
