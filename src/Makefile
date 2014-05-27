archive/v1:
	curl http://www.tuhs.org/Archive/PDP-11/Distributions/research/Dennis_v1/svntree-20081216.tar.gz | tar -C archive -xzf -
	mv archive/unix72 archive/v1
	(cd archive/v1 && tools/rebuild)
	# Date based on the 6/20/72 mark on p. 2 of
	#http://bitsavers.informatik.uni-stuttgart.de/pdf/bellLabs/unix/PreliminaryUnixImplementationDocument_Jun72.pdf
	touch -d '1972-06-20 12:00' archive/v1/rebuilt/*
