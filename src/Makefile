all: archive/v1 archive/v3 archive/v4 archive/v5 archive/v6 archive/v7 \
	archive/1bsd newoldar archive/2bsd archive/32v archive/3bsd \
	archive/CSRG/cd1.mnt archive/CSRG/cd2.mnt \
	archive/CSRG/cd3.mnt archive/CSRG/cd4.mnt archive/CSRG/cd4.patched \
	archive/386BSD-0.1 archive/386BSD-0.0 archive/FreeBSD-1.0.mnt \
	archive/FreeBSD-1.1.mnt archive/FreeBSD-1.1.5.1.mnt \
	archive/freebsd.git archive/freebsd-doc.git \
	archive/freebsd-early.git archive/FreeBSD-1.1.5 empty

.SUFFIXES:.iso .mnt

.iso.mnt:
	mkdir -p $(subst .iso,,$<)
	# Mount uses -o uid, because some directories have 750 permissions, e.g.
	# drwxr-x--- 2 root news  4096 Mar  9  1989 netns
	sudo mount -o loop -o uid=`id -u` $< $(subst .iso,,$<)
	touch $@

archive/v1:
	mkdir -p archive
	curl -s http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v1/svntree-20081216.tar.gz | tar -C archive -xzf -
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
	touch -d '1972-06-20 12:00' $@/sys/*

# The only thing remaining from V2 are formatted manual pages

archive/v3:
	mkdir -p $@/sys
	curl -s http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v3/nsys.tar.gz | tar -C $@/sys -xzf -

archive/v4:
	mkdir -p $@/man
	curl -s http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v4/v4man.tar.gz | tar -C $@/man -xzf -

archive/v5:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v5/v5root.tar.gz | tar -C $@ -xzf -

archive/v6:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v6/v6root.tar.gz | tar -C $@ -xzf -
	curl -s http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v6/v6src.tar.gz | tar -C archive/v6/usr/source -xzf -
	mkdir -p $@/usr/doc
	curl -s http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v6/v6doc.tar.gz | tar -C $@/usr/doc -xzf -

archive/v7:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/PDP-11/Distributions/research/Henry_Spencer_v7/v7.tar.gz | tar -C $@ -xzf -
	mkdir v7-patch
	curl -s http://www.tuhs.org/Archive/PDP-11/Distributions/research/Henry_Spencer_v7/v7.patches.tar.gz | tar -C v7-patch -xzf -
	mv v7-patch/lpr $@/usr/src/cmd/
	mv v7-patch/lp.c $@/usr/sys/dev/
	mv v7-patch/lpd.8 $@/usr/man/man8/
	rm -rf v7-patch

archive/1bsd: newoldar
	mkdir -p $@
	curl -s http://unixarchive.cn-k.de/PDP-11/Distributions/ucb/1bsd.tar.gz | tar -C $@ -xzf -
	( AR=`pwd`/newoldar ; cd $@ && find . -name cont.a  | awk -F/ '{print $$2}' | while read d ; do ( cd $$d && $$AR xo cont.a && rm cont.a ) ; done)

newoladar: newoldar.c

archive/2bsd:
	mkdir -p $@
	curl -s http://unixarchive.cn-k.de/PDP-11/Distributions/ucb/2bsd.tar.gz | tar -C $@ -xzf -

archive/32v:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/VAX/Distributions/32V/32v_usr.tar.gz | tar -C $@ -xzf -

archive/3bsd:
	mkdir -p $@
	curl -s http://www.tuhs.org/Archive/4BSD/Distributions/3bsd.tar.gz | tar -C $@ -xzf - --exclude dev

archive/CSRG/cd1.iso:
	@echo Create the directory archive/CSRG, and save in it the ISO
	@echo images of the four CSRG CD-ROMs, with names cd[1-4].iso.
	@echo For availability see https://www.mckusick.com/csrg/

archive/CSRG/cd1/4.3/usr/src/ucb/compress/compress.c: archive/CSRG/cd1.mnt

# Compile from source, because Debian's version can't handle 16 bits
uncompress: archive/CSRG/cd1/4.3/usr/src/ucb/compress/compress.c
	cc -o $@ $<

archive/386BSD-0.0: uncompress
	mkdir -p $@
	for i in `seq 1 8` ; do curl -s http://www.oldlinux.org/Linux.old/distributions/386BSD/386bsd-0.0/floppies/3in/src/floppy.$$i ; done | ./uncompress | tar -C $@ -xf -

archive/386BSD-0.1: uncompress
	mkdir -p $@
	for i in `perl -e 'print map {sprintf("%02d ", $$_)} 0..61'` ; do curl -s http://www.oldlinux.org/Linux.old/distributions/386BSD/0.1/386BSD/SRC01.$$i ; done | ./uncompress | (cd $@ ; cpio -imd)

archive/CSRG/cd4.patched: archive/CSRG/cd4.mnt
	mkdir -p $@
	tar -C $(subst .mnt,,$<) -cf - . | tar -C $@ -xf -
	(cd $@ ; curl -s https://raw.githubusercontent.com/jonathangray/csrg-git-patches/master/SCCS-fix.patch | patch -p 1)
	touch $@

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
	git commit -m 'Add README.md in empty repo'
