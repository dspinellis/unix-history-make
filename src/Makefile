# Downloaded and expanded data
MOUNTS= archive/CSRG/cd1.mnt archive/CSRG/cd2.mnt \
	archive/CSRG/cd3.mnt archive/CSRG/cd4.mnt \
	archive/FreeBSD-1.0.mnt archive/FreeBSD-1.1.mnt \
	archive/FreeBSD-1.1.5.1.mnt

DATA=archive/pdp7-unix archive/v1 archive/v2 archive/v3 archive/v4 \
	archive/v5 archive/v6 archive/v7 archive/v8 archive/v9 archive/v10 \
	archive/1bsd archive/2bsd archive/32v archive/3bsd \
	archive/CSRG/cd4.patched archive/386BSD-0.1 archive/386BSD-0.0 \
	archive/freebsd.git archive/freebsd-doc.git \
	archive/freebsd-early.git archive/FreeBSD-1.1.5 \
	archive/386BSD-0.1-patched $(MOUNTS)

# Author detail files
AU=$(wildcard *.au)

# Authorship files
AUPATH=$(wildcard author-path/*)

# Files to ignore when importing
IGNORE=$(wildcard ignore/*)

# Construct the Unix history repository in the import directory
import: $(DATA) $(AU) $(AUPATH) $(IGNORE)
	./import.sh

# Push the imported repository to GitHub
push: import empty
	./github-push.sh

# Clear files signifying mounted ISO images (e.g. after a reboot)
clear-mounts:
	rm -f archive/*.mnt archive/CSRG/*.mnt

mount: $(MOUNTS)

unmount:
	df | awk '/loop/{print $1}' | xargs -r -n 1 sudo umount

.SUFFIXES:.iso .mnt

# Mount an ISO filesystem (Linux-specific; tailor it for other systems)
.iso.mnt:
	# Ensure we do not run make mount with sudo
	test `id -u` != 0
	mkdir -p $(subst .iso,,$<)
	# Mount uses -o uid, because some directories have 750 permissions, e.g.
	# drwxr-x--- 2 root news  4096 Mar  9  1989 netns
	sudo mount -o loop -o uid=`id -u` -o gid=`id -g` $< $(subst .iso,,$<)
	touch $@

archive/pdp7-unix:
	(cd archive ; git clone --depth=1 https://github.com/DoctorWkt/pdp7-unix.git)
	sed -i '/"\*\*/d' $@/scans/*
	touch -d '1970-06-30 12:00' $@/scans/*

archive/v1:
	mkdir -p archive
	curl -s http://www.tuhs.org/Archive/Distributions/research/Dennis_v1/svntree-20081216.tar.gz | tar -C archive -xzf -
	mv archive/unix72 $@
	# Convert OCR to source code files
	(cd $@ && tools/rebuild >/dev/null)
	# Undo 2008 patches
	mkdir $@/sys
	cp $@/build/* $@/sys
	cd $@/sys/ && for i in *.orig ; do mv $$i `expr $$i : '\(.*\)\.orig'` ; done
	rm $@/sys/Makefile
	# Date based on the 6/20/72 mark on p. 2 of
	#http://bitsavers.informatik.uni-stuttgart.de/pdf/bellLabs/unix/PreliminaryUnixImplementationDocument_Jun72.pdf
	touch -d '1971-11-03 12:00' $@/sys/*

# The things remaining from V2 are formatted manual pages and a few fragments
archive/v2: newoldar arcv
	# Commands
	mkdir -p $@/cmd
	cd $@/cmd && \
		curl http://www.tuhs.org/Archive//Distributions/Research/1972_stuff/s1-fragments.tar.gz | \
		tar xzf - && \
		../../../tools/remake-v2.sh
	# C compiler
	mkdir -p $@/c
	curl http://minnie.tuhs.org/Archive/Applications/Early_C_Compilers/last1120c.tar.gz | tar --strip-components=1 -C $@/c -xzf -
	find $@/c -name \*.o | xargs rm
	rm $@/c/nc1/c1 $@/c/cvopt $@/c/nc $@/c/nc0/c0
	# C library
	mkdir -p $@/lib
	# Convert and unpack $@/c/rt/libc.sa
	( cd $@/lib && ../../../arcv ../c/rt/libc.sa && ../../../newoldar xo ../c/rt/libc.sa )
	rm -rf $@/c/rt

archive/v3:
	mkdir -p $@/man
	curl -s http://minnie.tuhs.org/Archive/Distributions/research/Dennis_v3/v3man.tar.gz | tar -C $@/man -xzf -
	mkdir -p $@/c
	curl -s http://minnie.tuhs.org/Archive/Applications/Early_C_Compilers/prestructc.tar.gz | tar --strip-components=1 -C $@/c -xzf -

archive/v4:
	mkdir -p $@/man
	curl -s http://www.tuhs.org/Archive/Distributions/research/Dennis_v4/v4man.tar.gz | tar -C $@/man -xzf -
	mkdir -p $@/sys
	curl -s http://www.tuhs.org/Archive/Distributions/research/Dennis_v3/nsys.tar.gz | tar -C $@/sys -xzf -

archive/v5:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/Distributions/research/Dennis_v5/v5root.tar.gz | tar -C $@ -xzf -

archive/v6:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/Distributions/research/Dennis_v6/v6root.tar.gz | tar -C $@ -xzf -
	curl -s http://www.tuhs.org/Archive/Distributions/research/Dennis_v6/v6src.tar.gz | tar -C archive/v6/usr/source -xzf -
	mkdir -p $@/usr/doc
	curl -s http://www.tuhs.org/Archive/Distributions/research/Dennis_v6/v6doc.tar.gz | tar -C $@/usr/doc -xzf -
	cp bits/v6-speak.c $@/usr/source/s2/speak.c
	cp bits/v6-speak.v $@/usr/source/s2/speak.v
	# Same date as vs.c
	touch -d 1974-11-27 $@/usr/source/s2/speak.?

archive/v7:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/Distributions/research/Henry_Spencer_v7/v7.tar.gz | tar -C $@ -xzf -
	mkdir v7-patch
	curl -s http://www.tuhs.org/Archive/Distributions/research/Henry_Spencer_v7/v7.patches.tar.gz | tar -C v7-patch -xzf -
	mv v7-patch/lpr $@/usr/src/cmd/
	mv v7-patch/lp.c $@/usr/sys/dev/
	mv v7-patch/lpd.8 $@/usr/man/man8/
	rm -rf v7-patch
	# Remove file epoch timestamp (it just printed the block size)
	rm $@/bs.c

archive/v8:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/Distributions/Research/Dan_Cross_v8/v8.tar.bz2 | bzip2 -dc | tar -C $@ -xf -

archive/v9:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/Distributions/Research/Norman_v9/batterpudding.tar.gz | tar -C $@ -xzf -

archive/v10:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/Distributions/Research/Dan_Cross_v10/v10src.tar.bz2 | bzip2 -dc | tar -C $@ -xf -

archive/1bsd: newoldar
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive//Distributions/UCB/1bsd.tar.gz | tar -C $@ -xzf -
	( AR=`pwd`/newoldar ; cd $@ && find . -name cont.a  | awk -F/ '{print $$2}' | while read d ; do ( cd $$d && $$AR xo cont.a && rm cont.a ) ; done)
	rm -f $@/TAPE

newoladar: newoldar.c

arcv: arcv.c ar.h

archive/2bsd:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive//Distributions/UCB/2bsd.tar.gz | tar -C $@ -xzf -
	rm -f $@/TAPE

archive/32v:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive//Distributions/USDL/32V/32v_usr.tar.gz | tar -C $@ -xzf -

archive/3bsd:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/4BSD/Distributions/3bsd.tar.gz | tar -C $@ -xzf - --exclude dev

archive/CSRG/cd1.iso archive/CSRG/cd2.iso \
archive/CSRG/cd3.iso archive/CSRG/cd4.iso:
	@echo Create the directory archive/CSRG, and save in it the ISO
	@echo images of the four CSRG CD-ROMs, with names cd[1-4].iso.
	@echo For availability see https://www.mckusick.com/csrg/
	@false

archive/386BSD-0.0:
	mkdir -p $@
	for i in `seq 1 8` ; do curl -s http://www.oldlinux.org/Linux.old/distributions/386BSD/386bsd-0.0/floppies/3in/src/floppy.$$i ; done | gzip -dc | tar -C $@ -xf -

archive/386BSD-0.1:
	mkdir -p $@
	for i in `perl -e 'print map {sprintf("%02d ", $$_)} 0..61'` ; do curl -s http://www.oldlinux.org/Linux.old/distributions/386BSD/0.1/386BSD/SRC01.$$i ; done | gzip -dc | (cd $@ ; cpio -imd)
	for i in `perl -e 'print map {sprintf("%02d ", $$_)} 0..56'` ; do curl -s http://www.oldlinux.org/Linux.old/distributions/386BSD/0.1/386BSD/BIN01.$$i ; done | gzip -dc | (cd $@ ; cpio -imd)
	for i in `perl -e 'print map {sprintf("%02d ", $$_)} 0..96'` ; do curl -s http://www.oldlinux.org/Linux.old/distributions/386BSD/0.1/386BSD/ETC01.$$i ; done | gzip -dc | (cd $@ ; cpio -imd)
	# cpio does not set the modification time of symbolic links
	# so we set it manually from the time recorded in the archive.
	find $@ -type l | xargs touch  -h -d 'Jun 8 1992'

archive/CSRG/cd4.patched: archive/CSRG/cd4.mnt
	mkdir -p $@
	tar -C $(subst .mnt,,$<) -cf - . | tar -C $@ -xf -
	(cd $@ ; curl -s https://raw.githubusercontent.com/jonathangray/csrg-git-patches/master/SCCS-fix.patch | patch -p 1)
	rm -f $@/local/ditroff/ditroff.old.okeeffe/driver/SCCS/s.ifontinfo.c-bad
	touch $@

# 386BSD0.1 patchkit
archive/386BSD-patchkit:
	(cd archive ; curl ftp://www.tuhs.org/BSD/386bsd-patchkits/pk023.tar.gz | tar xzf - ; curl ftp://www.tuhs.org/BSD/386bsd-patchkits/pk023024.tar.gz | tar xzf -)
	mv archive/patch $@
	( cd $@/inbound && gzip -d * && for i in *.tar ; do tar xf $$i && rm $$i ; done )

archive/386BSD-0.1-patched: archive/386BSD-patchkit archive/386BSD-0.1
	./patch2git.sh

archive/FreeBSD-1.0.iso:
	curl -s http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/i386/ISO-IMAGES/1.0/1.0-disc1.iso >$@

archive/FreeBSD-1.1.iso:
	curl -s http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/i386/ISO-IMAGES/FreeBSD-1.1-RELEASE/cd1.iso >$@

archive/FreeBSD-1.1.5.1.iso:
	curl -s http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/i386/ISO-IMAGES/FreeBSD-1.1.5.1/cd1.iso >$@

archive/freebsd.git:
	(cd archive ; git clone --mirror https://github.com/freebsd/freebsd)

archive/freebsd-doc.git:
	(cd archive ; git clone --mirror https://github.com/freebsd/freebsd-doc)

# Create an importable CVS repo from the one existing in archive/FreeBSD-1.1.5.1/cvs/386BSD/src
archive/freebsd1-cvs: archive/FreeBSD-1.1.5.1.mnt
	rm -rf $@
	# Keep only the FINAL_ symbols
	# For the rest there are cases where the same symbol is assigned
	# to multiple revisions, which cvs2git can't handle
	cp -r archive/FreeBSD-1.1.5.1/cvs/386BSD/src $@
	perl clean-cvs.pl archive/freebsd1-cvs/ 'FINAL_.*?'
	# Files here clash with live files and cvs2git can't handle that
	rm -rf $@/share/doc/ps1/Attic
	rm -rf $@/share/doc/smm/Attic
	rm -rf $@/share/doc/usd/Attic

# Convert early FreeBSD CVS repo into git
archive/freebsd-early.git: archive/freebsd1-cvs
	../../cvs2svn-2.4.0/cvs2git --options=cvs2svn-FreeBSD-1.options
	rm -rf $@
	mkdir $@
	(cd $@ && \
	git init && \
	cat ../../cvs2svn-tmp/git-blob.dat ../../cvs2svn-tmp/git-dump.dat | git fast-import && \
	git tag -d FreeBSD-release/1.0.2 )

archive/FreeBSD-1.1.5: archive/FreeBSD-1.1.5.1.mnt
	rm -rf $@
	( cd archive/FreeBSD-1.1.5.1/tarballs/srcdist && \
	mkdir ../../../../$@ && \
	EXTRACT_TARGET=../../../../$@ ./EXTRACT.sh )

# Empty repo for cleaning the existing one during updates
empty:
	mkdir empty && \
	cd empty && \
	cp ../../README.md . && \
	git init && \
	git add . && \
	git commit -m 'Add README.md in empty repo' && \
	git remote add origin git@github.com:dspinellis/unix-history-repo.git

clean:
	rm -rf archive/CSRG/cd4.patched archive/FreeBSD-1.0 \
		archive/FreeBSD-1.1 archive/FreeBSD-1.1.5.1 \
		archive/freebsd-early.git archive/FreeBSD-1.1.5
