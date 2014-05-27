all: archive/v1 archive/v3 archive/v4 archive/v5 archive/v6 archive/v7 archive/1bsd newoldar

archive/v1:
	curl http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v1/svntree-20081216.tar.gz | tar -C archive -xzf -
	mv archive/unix72 archive/v1
	(cd archive/v1 && tools/rebuild)
	# Date based on the 6/20/72 mark on p. 2 of
	#http://bitsavers.informatik.uni-stuttgart.de/pdf/bellLabs/unix/PreliminaryUnixImplementationDocument_Jun72.pdf
	touch -d '1972-06-20 12:00' archive/v1/rebuilt/*

archive/v3:
	mkdir -p archive/v3/sys
	curl http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v3/nsys.tar.gz | tar -C archive/v3/sys -xzf -

archive/v4:
	mkdir -p $@/man
	curl http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v4/v4man.tar.gz | tar -C $@/man -xzf -

archive/v5:
	mkdir archive/v5
	(cd archive/v5 ; curl http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v5/v5root.tar.gz | tar xzf -)

archive/v6:
	mkdir archive/v6
	(cd archive/v6 ; curl http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v6/v6root.tar.gz | tar xzf -)
	(cd archive/v6/usr/source ; curl http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v6/v6src.tar.gz | tar xzf -)
	mkdir archive/v6/usr/doc
	(cd archive/v6/usr/doc ; curl http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v6/v6doc.tar.gz | tar xzf -)

archive/v7:
	mkdir archive/v7
	(cd archive/v7 ; curl http://www.tuhs.org/Archive/PDP-11/Distributions/research/Henry_Spencer_v7/v7.tar.gz | tar xzf -)
	mkdir v7-patch
	(cd v7-patch ; curl http://www.tuhs.org/Archive/PDP-11/Distributions/research/Henry_Spencer_v7/v7.patches.tar.gz | tar xzf -)
	mv v7-patch/lpr archive/v7/usr/src/cmd/
	mv v7-patch/lp.c archive/v7/usr/sys/dev/
	mv v7-patch/lpd.8 archive/v7/usr/man/man8/
	rm -rf v7-patch

archive/1bsd:
	mkdir archive/1bsd
	(cd archive/1bsd ; curl http://unixarchive.cn-k.de/PDP-11/Distributions/ucb/1bsd.tar.gz | tar xzf -)

newoladar: newoldar.c
