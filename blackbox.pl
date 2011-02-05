#!/usr/bin/perl -w
# Created @ 30.12.2010 by TheFox@fox21.at
# Version: 1.1.1
# Copyright (c) 2010 TheFox

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Description:
# Create AES256 encrypted loop devices (.img files) under Linux.


use strict;
use FindBin;
use File::Basename;
use File::Copy;
use Cwd 'realpath';

$| = 1;

my $VERSION = '1.1.1';
my $ENCRYPTION = 'AES256';
my $IMG_SIZE_BASE = 1024 * 1024;
my $IMG_SIZE_MIN = 10;
my $DD_BS = 2048;


sub main{
	
	chdir $FindBin::Bin;
	
	print "blackbox $VERSION\nCopyright (c) 2010 TheFox\@fox21.at\nUSE AT YOUR OWN RISK!!!\n\n";
	if($<){
		print "It's recommended to run this script as root.\n\n";
	}
	
	my $modeCreate = 0;
	my $modeResize = 0;
	my $modeMount = 0;
	my $modeUmount = 0;
	my $modeYes = 0;
	my $modeAll = 0;
	my $modeBackup = 0;
	my $imgpath = '';
	my $dirpath = '';
	my $answer = '';
	my $loopdev = '';
	my $error = 0;
	
	if(@ARGV){
		while(my $arg = shift @ARGV){
			if($arg eq '-c'){
				$modeCreate = 1;
			}
			elsif($arg eq '-r'){
				$modeResize = 1;
			}
			elsif($arg eq '-m'){
				$modeMount = 1;
			}
			elsif($arg eq '-u'){
				$modeUmount = 1;
			}
			elsif($arg eq '-y'){
				$modeYes = 1;
			}
			elsif($arg eq '-a'){
				$modeAll = 1;
			}
			elsif($arg eq '-b'){
				$modeBackup = 1;
			}
			else{
				$imgpath = $arg;
				if(@ARGV){
					$dirpath = shift @ARGV;
				}
				last;
			}
		}
	}
	else{
		usagePrint();
	}
	
	if($modeCreate){
		if($imgpath eq ''){
			print STDERR "FATAL ERROR: Invalid image path.\n";
			exit 1;
		}
		if($imgpath !~ /.img$/){
			$imgpath .= '.img';
		}
		$imgpath = realpath($imgpath);
		if(!-e $imgpath){
			print "Create '$imgpath'.\n";
			print "How big should it be? For 1GiB type 1024. In MiB: ";
			chomp($answer = <STDIN>);
			if($answer =~ /^\d+$/){
				
				if($answer < $IMG_SIZE_MIN){
					print STDERR "FATAL ERROR: The img file must be at least $IMG_SIZE_MIN MiB big.\n";
					exit 1;
				}
				
				my $count = $answer * 1024 / $DD_BS * 1024;
				print "Creating. This can take a while ...\n";
				qx(dd if=/dev/urandom of="$imgpath" bs=$DD_BS count=$count);
				
				if(-e $imgpath){
					$error = 0;
					if(-s $imgpath == $IMG_SIZE_BASE * $answer){
						$loopdev = losetupFind();
						print "Using loop dev: '$loopdev'\n";
						
						print qq(losetup "$loopdev" "$imgpath"\n);
						if(!system(qq(losetup -T -e $ENCRYPTION "$loopdev" "$imgpath"))){
							
							print qq(mkfs "$loopdev"\n);
							if(system(qq(mkfs -t ext3 "$loopdev"))){
								print STDERR "FATAL ERROR: mkfs failed.\n";
								$error = 1;
							}
							
							print qq(losetup -d "$loopdev"\n);
							if(!system(qq(losetup -d "$loopdev"))){
								print qq(OK.\n'$imgpath' created.\n\nNow you can mount the image with the following command:\n$0 -m "$imgpath"\n);
							}
							else{
								print STDERR "FATAL ERROR: 'losetup -d' failed.\n";
								$error = 1;
							}
						}
						else{
							print STDERR "FATAL ERROR: losetup failed.\n";
							$error = 1;
						}
					}
					else{
						print STDERR "FATAL ERROR: $imgpath failed.\n";
						$error = 1;
					}
					
					if($error){
						unlink $imgpath;
						exit 1;
					}
				}
				else{
					print STDERR "FATAL ERROR: $imgpath failed.\n";
					exit 1;
				}
			}
			else{
				print STDERR "FATAL ERROR: Invalid number '$answer'. Only numbers.\n";
				exit 1;
			}
		}
		else{
			print STDERR "FATAL ERROR: '$imgpath' already exists.\n";
			exit 1;
		}
	}
	elsif($modeResize){
		print STDERR "FATAL ERROR: resize not implemented.\n";
		exit 1;
		
		# LOOPDEV=$(losetup -f)
		# dd if=/dev/urandom bs=1GiB count=1 >> file.img
		# losetup -e aes256 $LOOPDEV ./file.img
		# fsck.ext3 -f $LOOPDEV
		# resize2fs $LOOPDEV
	}
	elsif($modeMount){
		if($imgpath eq ''){
			print STDERR "FATAL ERROR: Invalid image path.\n";
			exit 1;
		}
		if(-e $imgpath && -f $imgpath){
			
			if(-s $imgpath < $IMG_SIZE_BASE * $IMG_SIZE_MIN){
				print STDERR "FATAL ERROR: '$imgpath' too small.\n";
				exit 1;
			}
			
			if($dirpath eq ''){
				my $imgpathBasename = basename($imgpath);
				(my $imgpathBasedir = $imgpath) =~ s/$imgpathBasename$//;
				(my $dirpathBasename = $imgpathBasename) =~ s/.img$//;
				
				if($dirpathBasename eq $imgpathBasename){
					print STDERR "FATAL ERROR: Your image file must have a .img extension.\n";
					exit 1;
				}
				if($dirpathBasename eq ''){
					print STDERR "FATAL ERROR: mount failed. [1]\n";
					exit 1;
				}
				
				$dirpath = "$imgpathBasedir$dirpathBasename";
			}
			if($dirpath eq ''){
				print STDERR "FATAL ERROR: mount failed. [2]\n";
				exit 1;
			}
			$dirpath = realpath($dirpath);
			
			if(!system(qq(mount | grep "$dirpath"))){
				print STDERR "FATAL ERROR: '$dirpath' is already mounted.\n";
				exit 1;
			}
			
			if(!-e $dirpath){
				print "The directory '$dirpath' doesn't exist.\nCreate?";
				if(input()){
					mkdir $dirpath;
					if(!-e $dirpath){
						print STDERR "FATAL ERROR: mkdir '$dirpath' failed.\n";
						exit 1;
					}
					print "mkdir '$dirpath' ok.\n";
				}
				else{
					print STDERR "Abort.\n";
					exit 1;
				}
			}
			if(!-d $dirpath){
				print STDERR "FATAL ERROR: '$dirpath': No such directory.\n";
				exit 1;
			}
			if($modeBackup){
				print "Make backup ...\n";
				if(copy($imgpath, "$imgpath.bak")){
					print "Backup OK.\n";
				}
				else{
					print STDERR "Backup failed.\n";
				}
			}
			
			print "Image file: '$imgpath'\nMount directory: '$dirpath'\n";
			$loopdev = losetupFind();
			print "Using loop dev: '$loopdev'\n";
			
			print qq(losetup "$loopdev" "$imgpath"\n);
			if(!system(qq(losetup -e $ENCRYPTION "$loopdev" "$imgpath"))){
				print qq(mount "$loopdev" "$dirpath"\n);
				if(!system(qq(mount -t ext3 "$loopdev" "$dirpath"))){
					print qq(OK\n\nTo close the image use the following command:\n$0 -u "$loopdev"\n);
				}
				else{
					print STDERR "FATAL ERROR: mount failed.\n";
					
					if(system(qq(losetup -d "$loopdev"))){
						print STDERR "ERROR: losetup failed.\n";
					}
					
					exit 1;
				}
			}
			else{
				print STDERR "FATAL ERROR: losetup failed.\n";
				exit 1;
			}
		}
		else{
			print STDERR "FATAL ERROR: '$imgpath': No such file.\n";
			exit 1;
		}
	}
	elsif($modeUmount){
		if($imgpath eq ''){
			print STDERR "FATAL ERROR: Invalid image path.\n";
			exit 1;
		}
		print qq(umount "$imgpath"\n);
		if(!system(qq(umount "$imgpath"))){
			print qq(losetup -d "$imgpath"\n);
			if(!system(qq(losetup -d "$imgpath"))){
				print "OK\n";
			}
			else{
				print STDERR "FATAL ERROR: losetup failed.\n";
				exit 1;
			}
		}
		else{
			print STDERR "FATAL ERROR: umount failed.\n";
			exit 1;
		}
	}
	elsif($modeAll){
		if(system(qq(losetup -a))){
			print STDERR "FATAL ERROR: losetup failed.\n";
			exit 1;
		}
	}
	else{
		usagePrint();
	}
	
	1;
}

sub usagePrint{
	my $bn = basename($0);
	print STDERR 
		"Usage:\n".
		"$bn -c FILE\n".
		"$bn -m [-b] FILE [DIRECTORY]\n".
		"$bn -u DEVICE\n".
		"$bn -a\n".
		"\n".
		"\t-c = Create a new image.\n".
		"\t-m = Mount an existing image.\n".
		"\t-b = Backup the image file.\n".
		"\t-u = Unmount an image.\n".
		"\t-a = Alias for 'losetup -a'.\n".
		"\n".
		"\tFILE = Path to the image file (.img).\n".
		"\tDEVICE = Is only used in combination with '-u'.\n".
		"\tDIRECTORY = Path to the mount directory.\n"
	;
	exit 1;
}

sub input{
	my $rv = 0;
	
	print ' [yN] ';
	my $k = <STDIN>;
	chomp $k;
	$k = lc $k;
	if($k eq 'y' || $k eq 'yes'){
		return 1;
	}
	return 0;
}

sub losetupFind{
	my $rv = qx(losetup -f);
	chomp $rv;
	if(-e $rv){
		return $rv;
	}
	print STDERR "ERROR: losetupFind: Couldn't find a valid loop device.\n";
	exit 1;
}

main();


# EOF
