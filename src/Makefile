all: archive/v1 archive/v3 archive/v4 archive/v5 archive/v6 archive/v7 archive/1bsd newoldar

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
	( AR=`pwd`/newoldar ; cd $@ && find . -name cont.a  | awk -F/ '{print $$2}' | while read d ; do ( cd $$d ; $$AR xo cont.a ) ; done)

newoladar: newoldar.c
