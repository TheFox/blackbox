# Blackbox
Create [AES](http://en.wikipedia.org/wiki/Advanced_Encryption_Standard) 256 bit encrypted loop devices (.img files) under [Linux](http://www.linux.org/).

## Requirements
- Linux
- Root access
- dd
- losetup

## Manual
### Create
```
IMGPATH=./.secure.img
dd if=/dev/urandom of=$IMGPATH bs=2k count=5M
LOOPDEV=$(losetup -f)
losetup -Te aes256 $LOOPDEV $IMGPATH
mkfs -t ext3 $LOOPDEV
```

### Mount
```
IMGPATH=./.secure.img
MOUNTDIR=./secure
LOOPDEV=$(losetup -f)
losetup -e aes256 $LOOPDEV $IMGPATH
mount -t ext3 $LOOPDEV $MOUNTDIR
```

### Umount
```
umount $LOOPDEV
losetup -d $LOOPDEV
```

### Resize
```
IMGPATH=./.secure.img
dd if=/dev/urandom bs=2k count=5M >> $IMGPATH
LOOPDEV=$(losetup -f)
losetup -e aes256 $LOOPDEV $IMGPATH
fsck.ext3 -f $LOOPDEV
resize2fs $LOOPDEV
losetup -d $LOOPDEV
```

## License
Copyright (C) 2010 Christian Mayer <http://fox21.at>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
