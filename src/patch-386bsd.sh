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
	# Check that prerequisite patches have been installed
	#
	echo -n  "Verifying prerequisite patches for $patch ...please wait"

	cd $TMPDIR
	rm -f reqs.$patch
	touch reqs.$patch
	ERROR=0
	cat $AVAILDIR/$patch/PATCH | while read x
	do
		set -- $x
		field=$1
		if test "$field" = "PATCHTO"
		then
			ex_patch=$3
			ex_file=$4
			if test ! -f $ex_file
			then
				echo $ex_patch >> reqs.$patch
			fi
		fi
	done

	#
	# List the patches required (if any) before installing this patch
	#
	if test -s reqs.$patch
	then
		header
		echo
		echo "The following patch(es) must be installed to install $patch:"
		echo
		sort -u < reqs.$patch

		echo -n "Do you want to install them now? "
		if $interactive
		then
			echo -n ""
			YESNO=0
			getyn
		else
			YESNO=1
			echo "YES"
		fi

		if test "$YESNO" = "0"
		then
			echo
			echo "[ INSTALLATION OF $patch HAS FAILED ]"
			condwait
			rm -f reqs.$patch
			echo
			return
		else
			for nn in `sort -u < reqs.$patch`
			do
				echo "   Installing $nn..."
				# gee, I CAN go recursive! Mooomm!  Look!
				m_install false patch$nn
			done
		fi
	fi
	rm -f reqs.$patch

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
			echo "    patch -c $fle $AVAILDIR/$patch/$pch" >> $LOG;
			patch -c $fle $AVAILDIR/$patch/$pch 2>>$LOG || {
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
cat << EOF_MARK

All is not lost!  During installation, a recovery script was created for
just such an emergency.  This will remove new files and back out changes
to any original files.

EOF_MARK
		echo -n "Undo changes? "
		YESNO=1
		getyn
		if test "$YESNO" = "0"
		then
			header
			echo "If you change your mind, and I strongly recommend you do!, the file"
			echo "        $UNDO"
			echo "contains the necessary commands.  Note that this is a temporary file"
			echo "and will go away unless you save it somewhere permanent *NOW*."
			echo

			exit 2
		fi

		#
		# Back out changes from patch
		#
		header
		echo -n "UNDOING $patch.  DO NOT INTERRUPT."
		/bin/sh $UNDO

		echo
		echo
		echo "You should check the log file"
		echo "        $LOG"
		echo "which contains the commands executed during installation and the file"
		echo "        $UNDO"
		echo "which contains the commands executed during the undo."
		echo "Do this *NOW* to insure the undo was successful."
		exit 2
	fi

	if $interactive
	then
		echo
		condwait
	fi
}


#
# m _ d e i n s t a l l
#
# Deinstall a patch.
#
# Parameters:	$1	patch to deinstall
# Procedure:
#	o	Verify that the files effected by this patch have not been
#		subsequently patched (thus creating a dependency on this
#		patch which would require removal of subsequent patches
#		before this patch can be removed.
#	o	If this isn't the last ("terminal") patch to all effected
#		files, notify which patches must be deinstalled and return
#		to menu.
#	o	If any files used in the deinstall are missing, notify and
#		return to menu (patch can never be deinstalled).
#	o	Give a chance to back out.
#	o	If backout, notify and return to menu.
#	o	Do real deinstall by rm'ing files created by this patch
#		and mv'ing the previous patch level over to of files modified
#		by this patch.
#	o	In case of failure, notify of log file containing failed
#		commands still necessary for deinstallation (manually by
#		user).  Return to menu.
#	o	If success, move from installed directory to ready directory.
#	o	Return to menu.
#
#
m_deinstall() {
	interactive="$1"
	patch="$2"

	if test "$patch" = "ALL"
	then

		PATCHLIST="$TMPDIR/patchlist"
		rm -f $PATCHLIST
		touch $PATCHLIST

		CWD=`pwd`
		cd $INSTDIR
		for xxx in *
		do
			echo $xxx
		done | sort -r >> $PATCHLIST
		cd $CWD

		if test ! -s $PATCHLIST
		then
			echo "[ NO PATCHES INSTALLED ]"
			echo
			condwait
			return
		fi

		header

		echo "***************************************************"
		echo "WARNING: THIS WILL DEINSTALL ALL INSTALLED PATCHES!"
		echo "***************************************************"
		echo -n "THIS IS YOUR LAST CHANCE!  CONTINUE DEINSTALLING? "
		YESNO=0
		getyn

		if test "$YESNO" = "0"
		then
			echo
			echo "[ MASS DEINSTALLATION ABORTED BY USER ]"
			echo
			condwait
			return
		fi

		echo
		echo "[ BEGINNING MASS DEINSTALLATION ... DO NOT INTERRUPT! ]"
		echo

		for xxx in `cat $PATCHLIST`
		do
			echo
			echo "   Deinstalling $xxx..."
			# gee, I hope I can go recursive...
			m_deinstall false $xxx
		done

		rm -f $PATCHLIST

		echo "[ MASS DEINSTALLAION COMPLETE ]"
		echo
		condwait

		return
	fi


	header

	if test ! -f $INSTDIR/$patch/PATCH
	then
		echo "$patch: no such patch has been installed!"
		echo
		condwait
		return
	fi

	#
	# Check that this was the most recently installed patch
	#
	echo -n  "Verifying no other patches require $patch ...please wait"
	required=0
	rm -f $TMPDIR/required
	cat $INSTDIR/$patch/PATCH | while read x
	do
		set -- $x
		field=$1
		#
		# Ignore DIR entries, since they can not be updated, they can
		# not have explicit dependencies.  Implicit dependencies
		# will take care of themselves, since a directory with any
		# entries in it can not be removed.
		#
		# In 'NEW', we initialize the patch number to the current
		# patch in case there is no "CURRENT PATCH LEVEL" line; if
		# we didn't, we might not be able to deinstall binaries.
		# Same goes for TARZ, treat just like NEW
		case $field in
		NEW)	dst=$5
			if test ! -f $dst; then
				echo
				echo "(FATAL: THE FILE $dst WAS DELETED BY THE USER)"
				echo
				echo "THIS FILE CAN NOT BE RETURNED TO IT'S PREVIOUS LEVEL!"
				touch $TMPDIR/fatal
				return
			fi;
			PLVLPATCH=`echo $patch | cut -c 6-99`;
			line=`grep "CURRENT PATCH LEVEL" $dst`;
			for i in $line;
			do
				PLVLVALUE="$PLVLPATCH"
				PLVLPATCH="$i"
			done;
			if test "patch$PLVLPATCH" != "$patch"; then
				if test "$required" = "0"
				then
					required=1
					touch $TMPDIR/required
					echo
					echo "This new file is required by:"
				fi
				echo "        $PLVLPATCH"
			fi;;
		PATCH)	lvl=$2
			fle=$4
			if test ! -f $fle.pl$lvl; then
				echo
				echo "(FATAL: THE FILE $fle.pl$lvl WAS DELETED BY THE USER)"
				echo
				echo "THIS FILE CAN NOT BE RETURNED TO IT's PREVIOUS LEVEL!"
				touch $TMPDIR/fatal
				return
			fi;
			if test ! -f $fle; then
				echo
				echo "(FATAL: THE FILE $fle WAS DELETED BY THE USER)"
				echo
				echo "THIS FILE CAN NOT BE RETURNED TO IT's PREVIOUS LEVEL!"
				touch $TMPDIR/fatal
				return
			fi;
			line=`grep "CURRENT PATCH LEVEL" $fle`;
			for i in $line;
			do
				PLVLVALUE="$PLVLPATCH"
				PLVLPATCH="$i"
			done;
			if test "patch$PLVLPATCH" != "$patch"; then
				if test "$required" = "0"
				then
					required=1
					touch $TMPDIR/required
					echo
					echo "This patch is required by:"
				fi
				echo "        $PLVLPATCH"
			fi;
			;;
		TARZ)	pch=$2
			dir=$3
			rm -rf $TARDIR $DIFFTMP
			mkdir $TARDIR
			cd $TARDIR
			cat $INSTDIR/$patch/$pch | gzip -d | tar xpf -
			find * -type f >$FINDTMP
			cat $FINDTMP | while read y 
			do
				if test "$?" != "0"
				then
					break
				fi
#XXXX need to do a diff here to see that the files match, if so
#     we can skip the patchlevel check for speed!
# find * -type f -exec diff -c {} $dir/{} >>$DIFFTMP \;
				PLVLPATCH=`echo $patch | cut -c 6-99`;
				line=`grep "CURRENT PATCH LEVEL" $dir/$y`;
				for i in $line;
				do
					PLVLVALUE="$PLVLPATCH"
					PLVLPATCH="$i"
				done;
				if test "patch$PLVLPATCH" != "$patch"; then
					if test "$required" = "0"
					then
						required=1
						touch $TMPDIR/required
						echo
						echo "This patch is required by:"
					fi
					echo "        $PLVLPATCH"
				fi
			done
			cd $TMPDIR
			rm -rf $TARDIR $DIFFTMP;;
		MOV)	src=$2
			dst=$3
			if test ! -f $dst; then
				echo
				echo "(FATAL: THE FILE $dst WAS DELETED BY THE USER)"
				echo
				echo "THIS FILE CAN NOT BE RETURNED TO IT'S PREVIOUS LEVEL!"
				touch $TMPDIR/fatal
				return
			fi;
			;;
		esac
	done

	#
	# Fatal errors get a different, per-file message (already output)
	#
	if test -f $TMPDIR/fatal
	then
		echo
		condwait
		rm -f $TMPDIR/required
		rm -f $TMPDIR/fatal
		return
	fi

	echo

	#
	# If this patch isn't the terminal patch for all files it effects,
	# then we can't remove it.
	#
	if test -f $TMPDIR/required
	then
		rm -f $TMPDIR/required
		echo "[ ABORT: PATCH IS REQUIRED BY SUBSEQUENT PATCHES ]"
		echo
		condwait
		return
	fi

	#
	# This patch is a terminal patch.  Verify removal before proceeding.
	#
	echo "Terminal patch.  No installed patches depend on this patch."
	echo
	echo -n "THIS IS YOUR LAST CHANCE!  CONTINUE DEINSTALLATION OF $patch? "
	if $interactive
	then
		echo -n ""
		YESNO=0
		getyn
	else
		echo "YES"
		YESNO=1
	fi

	#
	# Notify of backout if backout was requested
	#
	if test "$YESNO" = "0"
	then
		echo
		echo "[ DEINSTALLATION OF $patch ABORTED BY USER ]"
		echo
		condwait
		return
	fi

	#
	# REALLY DEINSTALL THE PATCH
	#
	header

	echo -n  "DEINSTALLATION OF $patch IN PROGRESS.  DO NOT INTERRUPT"

	LOG=$TMPDIR/deinstall.log
	UNDODIR=$TMPDIR/uninstdir
	rm -f $LOG $UNDODIR
	touch $LOG $UNDODIR

	echo -n "BEGIN DEINSTALLATION OF $patch - " >> $LOG
	echo `date` >> $LOG
	FAIL="$TMPDIR/fail_install"
	rm -f $FAIL
	cat $INSTDIR/$patch/PATCH | while read x
	do
		set -- $x
		field=$1
		case $field in
		DIR)	dst=$4
			echo "rmdir $dst > /dev/null 2>&1" >> $UNDODIR;;
		NEW)	dst=$5
			if rm -f $dst; then
				echo "rm -f $dst	#SUCCESS" >> $LOG
			else
				touch $FAIL
				echo "rm -f $dst	#FAILED" >> $LOG
			fi;
			;;
		PATCH)	lvl=$2
			fle=$4
			mv -f $fle.pl$lvl $fle;
			if touch $fle; then
				echo "mv -f $fle.pl$lvl $fle	#SUCCESS" >> $LOG
			else
				touch $FAIL
				echo "mv -f $fle.pl$lvl $fle	#FAILED" >> $LOG
			fi;
			;;
		TARZ)	pch=$2
			dir=$3
			mkdir $TARDIR
			cd $TARDIR
			cat $INSTDIR/$patch/$pch | gzip -d | tar xpf -
			find * \( -type f -or -type l \) >$FINDTMP
			cat $FINDTMP | while read y
			do
				if test "$?" != "0"
				then
					break
				fi;
				rm -f $dir/$y;
				if test "$?" != "0"; then
					touch $FAIL
					echo "rm -f $dir/$y	#FAILED" >> $LOG
				else
					echo "rm -f $dir/$y	#SUCCESS" >> $LOG
				fi;
			done
			find * -type d > $FINDTMP
			cat $FINDTMP | while read y
			do
				if test "$?" != "0"
				then
					break
				fi;
				echo "rmdir $dir/$y > /dev/null 2>&1" >> $UNDODIR
			done
			cd $TMPDIR
			rm -rf $FINDTMP $TARDIR
			echo "#removal of tar.z files	#SUCCESS" >> $LOG;;
		MOV)	src=$2
			dst=$3
			mv $dst $src
			if test "$?" != "0"; then
				touch $FAIL
				echo "mv $dst $src	#FAILED" >> $LOG
			else
				echo "mv $dst $src	#SUCCESS" >> $LOG
			fi;
			;;
		esac
	done

	#
	# If there is anything in the "$UNDODIR" file, we need to shell it
	# to actually "deinstall" the directories... we ignore the errors
	# by virtue of the subshell.  This will let many people "install"
	# and "deinstall" directories without the need for "updating"
	# their patch level.
	#
	if test -s "$UNDODIR"
	then
		# remove directories installed by this patch
		# first sort is in reverse order so that lower levels get
		# removed.
		sort -r < $UNDODIR > ${UNDODIR}.sort
		mv ${UNDODIR}.sort $UNDODIR
		/bin/sh	$UNDODIR
	fi

	# this file is no longer necessary, and a bother
	rm -f $UNDODIR

	if test ! -f $FAIL
	then
		echo -n "SUCCESSFUL " >> $LOG
	else
		echo -n "FAILED " >> $LOG
	fi
	echo -n "DEINSTALLATION OF $patch - " >> $LOG
	echo `date` >> $LOG

	echo

	if test ! -f $FAIL
	then
		echo "DEINSTALLATION OF $patch COMPLETED SUCCESSFULLY."
		if $interactive 
		then
			echo -n ""
		fi
		mv $INSTDIR/$patch $AVAILDIR/$patch

	else
		rm -f $FAIL
		echo "DEINSTALLATION OF $patch HAS FAILED!"

		echo
		echo "A list of the commands which failed is in the file:"
		echo
		echo "        $LOG"
		echo
		echo "Reexecute these commands manually to insure proper deinstallation;"
		echo "only failed commands need to be executed."
	fi

	if $interactive
	then
		echo
		condwait
	fi
}


#
# m _ h e l p
#
# Provide help on line during use of "patches" program
#
# Parameters:	<NULL>		help on help
#		?<patch>	help on patch (print description of patch
#				from the PATCH file)
#
# Procedure:
#	o	If there isn't a topic specified, it's help on how to use
#		the help command.
#	o	If there's a topic, assume it's a directory name of either
#		an installed or ready-to-install patch, and try to read the
#		PATCH file to get the DESC entered when the patch was created.
#
m_help() {
	topic="$1"

	if test "x$topic" = "x"
	then
		#
		# help on help command
		#
cat << EOF_MARK

HELP for the COMAND prompt:

	?		This screen
	?patch00001	Information about patch 00001
	Ipatch00001	Install patch 00001
	Dpatch00001	Deinstall patch 00001
	IALL		Install ALL patches (noninteractive)
	DALL		Deinstall ALL patches (noninteractive)
	Q		Quit this program

EOF_MARK
		condwait
	else
		#
		# help on topic -- "patch"
		#

		echo
		FNAME=0
		if test -d $AVAILDIR/$topic
		then
			echo "Help for uninstalled patch $topic:"
			FNAME="$AVAILDIR/$topic/PATCH"
		fi
		if test -d $INSTDIR/$topic
		then
			echo "Help for already installed patch $topic:"
			FNAME="$INSTDIR/$topic/PATCH"
		fi

		if test "$FNAME" = "0"
		then
			echo "No help available for $topic"
		else
			echo
			PRINT=0
			cat $FNAME | while read x
			do
				field=`echo $x | cut -f1 -d" "`
				if test "$PRINT" = "1"
				then
					if test "$field" = "%%REQ"
					then
						break;
					fi
					echo "$x"
				else
					if test "$field" = "%%DESC"
					then
						PRINT=1
					fi
				fi
			done
		fi

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
