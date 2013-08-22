# Blackbox
Create AES256 encrypted loop devices (.img files) under Linux.

Visit [fox21.at](http://fox21.at).

## Requirements
- Linux
- Root access
- dd
- losetup

## Manual
### create
```
IMGPATH=./.secure.img
dd if=/dev/urandom of=$IMGPATH bs=2k count=5M
LOOPDEV=$(losetup -f)
losetup -Te aes256 $LOOPDEV $IMGPATH
mkfs -t ext3 $LOOPDEV
```

### mount
```
IMGPATH=./.secure.img
MOUNTDIR=./secure
LOOPDEV=$(losetup -f)
losetup -e aes256 $LOOPDEV $IMGPATH
mount -t ext3 $LOOPDEV $MOUNTDIR
```

### umount
```
umount $LOOPDEV
losetup -d $LOOPDEV
```

### resize
```
IMGPATH=./.secure.img
dd if=/dev/urandom bs=2k count=5M >> $IMGPATH
LOOPDEV=$(losetup -f)
losetup -e aes256 $LOOPDEV $IMGPATH
fsck.ext3 -f $LOOPDEV
resize2fs $LOOPDEV
losetup -d $LOOPDEV
```
