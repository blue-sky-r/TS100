#!/usr/bin/env bash

# CLI flash for TS100
#

[ $# -lt 1 ] && cat <<< """
usage: $0 fw.hex

flash fimware fw.hex into TS100

""" && exit 1

FW=$1
TMPMOUNT='/tmp/ts100'
#FWPATH="$TMPMOUNT/$( basename $FW | tr a-z A-Z )"
FWPATH="$TMPMOUNT/$( basename $FW )"
FWRDY=$( basename ${FW} '.hex' ).rdy

#echo "fw($FW) FWPATH($FWPATH) FWRDY($FWRDY)"; exit

[ ! -s  "$FW" ] && echo "ERROR - invalid/empty  firmware file $FW" && exit 1

# DFU mode
#
cat <<< """
Waiting for TS100 DFU (Device Firmware Update) mode:
- disconnect TS100
- pres & hold tip side button
- connect microusb (display shows DFU: version)

"""

mkdir "$TMPMOUNT" 2>/dev/null

while sleep 1;
do
	dfu=$( lsblk -P -d --output NAME,MODEL | grep "DFU Disk" )
	[ ! -z "$dfu" ] && break
	echo -n "."
done

[ -z "$dfu" ] && echo "ERR: DFU disk not found" && exit 2

echo "DFU mode found: $dfu"
eval $dfu

# mount in MS-DOS mode	
#
umount "/dev/$NAME" 2>/dev/null
sudo mount -t msdos "/dev/$NAME" "$TMPMOUNT"

# copy fw
#
echo -en "Copying firmware $FW -> $FWPATH ... "	
sudo cp "$FW" "$FWPATH"
sync
sleep 1
echo "done"
sudo umount "/dev/$NAME"
rmdir "$TMPMOUNT"

echo -en "Waiting for TS100 reboot and automount "

# reboot & automount
#
while sleep 1;
do
	# sdb 8:16 1 2M 0 disk /media/robert/6CE4-98A2
	mntdir=$( lsblk -P -d -r | awk '/^'$NAME'/ {print $7}' )
	#echo "mntdir($mntdir)"
	[ -n "$mntdir" ] && break
	echo -n "."
done

# verity RDY file
#
rdy=$( find  "$mntdir/" -iname "$FWRDY" ) 
[ -z "$rdy" ] && echo "ERROR flashing firmware $FW" || echo "Firmwre $FW flashed OK ($rdy)"
