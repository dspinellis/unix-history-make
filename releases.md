## 4.1a
The 4.1a distribution had the initial socket interface with a
prerelease of the BBN TCP/IP under it. There was wide distribution
of 4.1a.

## 4.1b
The 4.1b distribution had the fast filesystem added and
a more mature socket interface (notably the listen/accept model
added by Sam Leffler). There was very limited distribution of 4.1b.

## 4.1c
The 4.1c distribution had the finishing touches on the socket
interface and added the rename system call to the filesystem.
It also added the reliable signal interface. There was very wide
distribution of 4.1c as there was a 9-month delay in the distribution
of 4.2BSD while DARPA, BBN, and Berkeley debated whether the prerelease
of BBN's TCP/IP should be replaced with BBN's finished version. In
the end the TCP/IP was not replaced as it had had so much field
testing and improvement by the folks running the BSD releases that
it was deemed more performant and reliable. There had been a plan
to release 4.1d that would have the new virtual memory (mmap)
interface, but the delay in getting out 4.2BSD caused that addition
to be delayed for the 4.3BSD release.
