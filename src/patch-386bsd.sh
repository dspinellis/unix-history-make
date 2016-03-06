:
# 18 Apr 93
#
# patches.sh
#
# This is a bourne shell program to apply the specified patch
# It is derived from the 386BSD interactive program
#
# When		Who			Description
# ---------	--------------------	------------------------------------
# 04 Mar 16	Diomidis Spinellis	Create non-interactive version
# 18 Apr 93	Rodney W. Grimes	New version number for patchkit release
# 13 Apr 93	Rodney W. Grimes	Merge in J.T. Conklins fixes agains
#					version 0.2.2, now at version 0.2.3-A7
# 12 Apr 93	J.T. Conklin		Speed up (against verson 0.2.2)
# 12 Apr 93	Rodney W. Grimes	Add PATH
# 10 Apr 93	Rodney W. Grimes	Revison stamp for 0.2.3-A5 kit
# 07 Apr 93	Rodney W. Grimes	Changed TARZ to be gzip files!
# 06 Apr 93	Rodney W. Grimes	Added MOV type patch
# 06 Apr 93	Rodney W. Grimes	Fixed up gzip/uncompress inbound
#		Nate Williams		Fix for expr, works with both versions
# 04 Apr 93	Rodney W. Grimes	Add TARZ type to PATCH file
#					use cp -p, to keep dates on NEW
#					Added gzip inbound support.
# 24 Mar 93	Rodney W. Grimes	Made output of patch -b go into log
# 18 Mar 93	Rodney W. Grimes	Fix rev, added ---'s to BAR
#					added rm reqs.$patch to clean up
# 02 Mar 93	Jordan Hubbard		Make deinstall touch moved file
# 01 Mar 93	Jordan Hubbard		Made installation of deps an option.
# 20 Jan 93	Bruce Evans		Fixed Uid and default answer problem
# 04 Oct 92	Terry Lambert		Stupid if; deinstall "NEW" patches
# 02 Oct 92	Terry Lambert		Remove annoying bells on D/I ALL
# 01 Oct 92	Terry Lambert		Added somthing to watch while ypu
#						are unpacking, root check,
#						-f on mv, rm for deinstall.
# 30 Sep 92	Terry Lambert		Added DIR, owner/mode to NEW
# 18 Sep 92	Terry Lambert		Fixed attempt to install/deinstall
#						nonexistant patches
# 14 Sep 92	Terry Lambert		Fixed install failure detection
# 06 Sep 92	Terry Lambert		Original
# ---------	--------------------	------------------------------------
#
# Copyright (c) 1992 Terrence R. Lambert.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#      This product includes software developed by Terrence R. Lambert.
# 4. The name Terrence R. Lambert may not be used to endorse or promote
#    products derived from this software without specific prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY TERRENCE R. LAMBERT ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE TERRENCE R. LAMBERT BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
#
VERSION="0.3.0-B1"
COPYRIGHT="Copyright (c) 1992,1993 Terry Lambert"
BAR="-------------------------------------------------------------------------------"
DONTWAIT=1
YESNO=0

ROOTDIR="$1"
PATCHDIR="$2"

AVAILDIR=$PATCHDIR/inbound
INSTDIR=$PATCHDIR/installed
LOGDIR=$PATCHDIR/log
TMPDIR=$PATCHDIR/tmp
FINDTMP=$TMPDIR/find
DIFFTMP=$TMPDIR/diff
TARDIR=$TMPDIR/tar


######################################################################
#
# F U N C T I O N S
#
######################################################################

#
# c o n d w a i t
#
# if DONTWAIT != 0, set 0, RETURN
# if DONTWAIT = 0, ask for keypress and return
#
condwait() {
	if test "$DONTWAIT" = "0"
	then
		echo "[ Hit <RETURN> to continue ]"
		read x
	else
		DONTWAIT=0
	fi
}

#
# g e t y n
#
# Get a "yes" or "no" input, and return a modified "YESNO" as a result.
# YESNO=1: yes, YESNO=0: no.  Default is from current setting of "YESNO".
#
getyn() {
	if test "$YESNO" = "0"
	then
		echo -n "(y/[n]) "
	else
		echo -n "([y]/n) "
	fi

	read x

	# empty return means accept default
	if test "$x""P" != "P"
	then

		case $x in
		y|Y|yes|Yes|YES|T|t|TRUE|true|True|1)	YESNO=1;;
		n|N|no|No|NO|F|f|FALSE|false|False|0)	YESNO=0;;
		# bad value is default -- change later?
		esac
	fi
}

#
# h e a d e r
#
# Print out the program header (usually per screen)
#
header() {
  :
}

#
# m _ i n s t a l l
#
# Install a patch.
#
# Parameters:	$1	name of patch directory in $AVAILDIR
# Procedure:
#
#	o	Verify the patches that must precede this patch have
#		already been installed.
#	o	If uninstalled prerequisities, notify and return to menu.
#	o	Give a chance to back out.
#	o	If a backout requested, notify and return to menu.
#	o	Try to install the patch.
#	o	If installation fails, give opportunity to "undo".
#	o	.	If undo requested, try undo and quit.
#	o	.	If no undo requested, notify and quit.
#	o	If installation successful, move patch to "installed"
#		directory and notify.
#	o	Return to menu.
#
m_install() {
	local interactive="$1"
	local patch="$2"

	if test "$patch" = "ALL"
	then

		PATCHLIST="$TMPDIR/patchlist"
		rm -f $PATCHLIST
		touch $PATCHLIST

		CWD=`pwd`
		cd $AVAILDIR
		for xxx in *
		do
			echo $xxx >> $PATCHLIST
		done
		cd $CWD

		if test ! -s $PATCHLIST
		then
			echo "'$PATCHLIST'"
			echo "[ NO PATCHES TO INSTALL! ]"
			echo
			condwait
			return
		fi

		echo
		echo "[ BEGINNING MASS INSTALLATION ... DO NOT INTERRUPT! ]"
		echo

		for xxx in `cat $PATCHLIST`
		do
			echo "   Installing $xxx..."
			# gee, I hope I can go recursive...
			m_install false $xxx
		done

		echo "[ MASS INSTALLAION COMPLETE ]"
		echo
		condwait

		return
	fi

	header

	if test ! -f $AVAILDIR/$patch/PATCH
	then
		echo "$patch: no such patch available for installation!"
		echo
		condwait
		return
	fi

	#
	# REALLY INSTALL THE PATCH
	#
	header

	echo "INSTALLATION OF $patch IN PROGRESS.  DO NOT INTERRUPT"

	LOG=$TMPDIR/log
	UNDO=$TMPDIR/uninstall
	UNDODIR=$TMPDIR/uninstdir
	rm -f $LOG $UNDO $UNDODIR
	touch $LOG $UNDO $UNDODIR

	echo -n "BEGIN INSTALLATION OF $patch - " >> $LOG
	echo `date` >> $LOG
	FAIL="$TMPDIR/fail_install"
	rm -f $FAIL
	#
	# Note: we will only attempt to create a directory if it isn't
	# there as a directory.  This means creating a directory over
	# a file or in a non-existant path is not allowed.
	#
	cat $AVAILDIR/$patch/PATCH | while read x
	do
		set -- $x
		field=$1
		case $field in
		DIR)	dstowner=$2
			dstmode=$3
			dst=$ROOTDIR/$4
			echo "rmdir $dst > /dev/null 2>&1" >> $UNDODIR;
			echo "    mkdir $dst" >> $LOG;
			if test ! -d $dst ; then
				mkdir $dst || {
					touch $FAIL
					break
				}
			fi;
			echo "    chmod $dstmode $dst" >> $LOG;
			chmod $dstmode $dst || {
				touch $FAIL
				break
			}
			;;
		NEW)	src=$AVAILDIR/$patch/$2;
			dstowner=$3
			dstmode=$4
			dst=$ROOTDIR/$5
			echo "rm $dst" >> $UNDO;
			echo "    cp -p $src $dst" >> $LOG;
			cp -p $src $dst || {
				touch $FAIL
				break
			}
			echo "    chmod $dstmode $dst" >> $LOG;
			chmod $dstmode $dst || {
				touch $FAIL
				break
			}
			;;
		PATCH)	lvl=$2
			pch=$3
			fle=$ROOTDIR/$4
			echo "mv $fle.pl$lvl $fle" >> $UNDO;
			echo "    patch -V none -c $fle $AVAILDIR/$patch/$pch" >> $LOG;
			patch -V none -c $fle $AVAILDIR/$patch/$pch 2>>$LOG || {
				touch $FAIL
				break
			}
			;;
		TARZ)	pch=$2
			dir=$ROOTDIR/$3
			echo "cd $dir" >> $UNDO;
			echo "    cd $dir" >> $LOG;
			cd $dir
			if test "$?" != "0"; then
				touch $FAIL
				break
			fi;
			echo "#XXX Can't UNDO TARZ $AVAILDIR/$patch/$pch" >> $UNDO;
			echo "    cat $AVAILDIR/$patch/$pch | gzip -d | tar xpvf -"  >> $LOG;
			cat $AVAILDIR/$patch/$pch | gzip -d | tar xpvf - >> $LOG;
			if test "$?" != "0"; then
				touch $FAIL
				break
			fi;
			echo "cd $TMPDIR" >> $UNDO
			cd $TMPDIR
			;;
		MOV)	src=$ROOTDIR/$2
			dst=$ROOTDIR/$3
			echo "mv $dst $src" >> $UNDO;
			echo "    mv $src $dst" >> $LOG;
			mv $src $dst
			if test "$?" != "0"; then
				touch $FAIL
				break
			fi;
			;;
		esac
	done

	# we put the directory deletion commands last, since new files may
	# have been created in new directories.  This is clever of us, since
	# it allows us to "uninstall" directories which have has stuff placed
	# in them without us having to be aware of the "stuff"
	cat $UNDODIR >> $UNDO

	# this file is now unnecessary and a bother...
	rm -f $UNDODIR

	if test ! -f $FAIL
	then
		echo -n "SUCCESSFUL " >> $LOG

		# this file is now unnecessary and a bother...
		rm -f $UNDO
	else
		echo -n "FAILED " >> $LOG
	fi
	echo -n "INSTALLATION OF $patch - " >> $LOG
	echo `date` >> $LOG

	if test ! -f $FAIL
	then
		echo
		echo "INSTALLATION OF $patch COMPLETED SUCCESSFULLY."
		if $interactive 
		then
			echo -n ""
		fi
		mv $AVAILDIR/$patch $INSTDIR/$patch

	else
		rm -f $FAIL
		echo
		echo "INSTALLATION OF $patch HAS FAILED!"
		echo
		echo "You should check the log file"
		echo "        $LOG"
		echo "which contains the commands executed during installation."
		exit 2
	fi

	if $interactive
	then
		echo
		condwait
	fi
}


######################################################################
#
# M A I N   P R O G R A M
#
######################################################################

if [ -z "$3" ] ; then
  echo "Usage: $0 source-dir patchkit-dir patch-to-apply" 1>&2
  echo "Example: patch-386bsd archive/386BSD-0.1-patched archive/386BSD-patchkit/ patch00001" 1>&2
  exit 1
fi

mkdir -p $TMPDIR $INSTDIR
m_install false "$3"
