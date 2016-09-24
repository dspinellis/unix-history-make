# Research Editions
## Research-PDP7
The PDP-7 Unix (sometime in mid 1970) is the earliest available
version of Unix.
It consists of a kernel and user commands,
all written in PDP-7 assembly code.
It was recovered by scanning assembly language listings of the system's
source code;
see https://github.com/DoctorWkt/pdp7-unix.

## Research-V1
The 1st Edition (November 3, 1971) contains
only the kernel; the 60 user commands that came with it are no longer
available. Even the kernel, written in PDP-11 assembly language, has not
survived in electronic form. It was derived from a group effort that
took a scanned June 1972 280-page printout of 1st Edition UNIX source
code and documentation, and restored it to an incomplete but running
system.

## Research-V2 (missing?)
The 2nd Edition (June 12, 1972) source code has only survived in the
form of fragments. These were manually restored by Warren Toomey,
who pieced together data from a subset of a disk dump’s DECtapes,
that were extracted by Dennis Ritchie. The fragments comprise
the source code for some of the system’s utilities. In addition,
this edition’s manual survives as a printed document.

## Research-V3
The 3rd Edition (February 1973) contains
only the Unix kernel: 7609 lines of which just 768 are written in
PDP-11 assembly and the rest are written in C. This was the first
Unix version to support pipes.

## Research-V4
The 4th Edition (November 1973) contains
only source markup for the manual pages: 18975 lines of
*troff* code.

## Research-V5
The 5th Edition (June 1974) is missing
the source markup of the manual pages. This edition was officially
made available to universities for educational use.

## Research-V6
The 6th Edition (May 1975), is the first that
appears in the repository in complete form, and the first that became
widely available outside Bell Labs through licenses to commercial and
government users. It was also the last bearing the names of Thompson and
Ritchie on the manuals’ title page. The 6th Edition is the one John
Lions used for teaching two operating systems courses at the University
of New South Wales in Australia. In 1977 Lions produced a booklet with
an indexed 9073-line listing of the entire Unix kernel with an equal
amount of commentary explaining its structure. Although this was
initially sold by mail order, a year afterwards it was no longer
available. Nevertheless, for the next two decades it circulated as
multiple-generation *samizdat* photocopies, until in late
1995 the lawyers of Santa Cruz Operation, Inc. gave permission for its
official publication.

## Research-V7
The 7th Edition (January 1979), includes many
new influential commands, such as *awk*, *expr*, *find*, *lex*, *lint*, *m4*, *make*,
*refer*, *sed*, *tar*, *uucp*, and the Bourne shell. It also supports larger
file systems and more user accounts. It is the version that was widely
ported to other architectures.

## Bell-32V
*Unix 32V* (or *32/V*) is the port of the 7th Edition Unix to the
DEC/VAX architecture. It was created by John Raiser and Tom London,
managed by Charlier Roberts, at Bell Labs in Holmdel in 1978. There seem
to be two reasons why the port was not implemented by the original team.
First, DEC’s refusal to support Unix, favouring VMS instead, and,
second, the complexity of the VAX instruction set, which apparently went
against the values of the Unix patriarchs. The port took about three
months to complete by treating the VAX as a large PDP-11 — keeping the
existing swapping mechanism and ignoring the VAX’s hardware paging
capability. In the fall of 1978 *Bell-32V* was sent to the
University of California at Berkeley under a “special research
agreement”.

*BSD–X* tags correspond to 15 snapshots released from
Berkeley. Their contents are summarized in the following paragraphs,
based on published descriptions and the manual examination of their
contents. The first Berkeley Software Distribution () (tagged
<span>BSD-1</span>), released in early 1978, contained the Unix Pascal
System the *ex* line editor, and a number of tools. The
Second Berkeley Software Distribution (2BSD, tagged <span>BSD-2</span>),
included the full screen editor *vi*, the associated
terminal capability database and management library
*termcap*, and many more tools, such as the
*csh* shell. The 3BSD release (tagged <span>BSD-3</span>),
released in late 1979, extended *Unix 32V* with support for
virtual memory and the 2BSD additions. Subsequent releases included in
the repository are marked with the following tags.

# Berkeley Releases
## BSD-4
4BSD (October 1980) was developed by the newly
established Computer Systems Research Group (CSRG) working on a
contract for the Defense Advanced Research Projects Agency (DARPA).
The contract aimed at standardizing at the operating system level
through the adoption of Unix the computing environment used by
DARPA’s research centers. The release included a 1k block file
system, support for VAX-11/750, enhanced email, job control, and
reliable signals.

## BSD-4\_1\_snap
4.1BSD (December 1982) a snapshot of
4.1, probably before 4.1a, included performance improvements and
auto-configuration support. This release was named 4.1BSD rather
than 5BSD in response to objections by  lawyers who feared the 5BSD
name might be confused with ’s commercial Unix *System V* release.
Subsequent BSD releases followed this numbering scheme.

## BSD-4.1a (not included in the repository)
The 4.1a distribution had the initial socket interface with a
prerelease of the BBN TCP/IP under it. There was wide distribution
of 4.1a.

## BSD-4.1b (not included in the repository)
The 4.1b distribution had the fast filesystem added and
a more mature socket interface (notably the listen/accept model
added by Sam Leffler). There was very limited distribution of 4.1b.

## BSD-4.1c (not included in the repository)
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

## BSD-4\_1c\_2
4.1c2BSD (April 1983) was the last
intermediary release preceding 4.2. It was used by many hardware
vendors to start their 4.2BSD porting efforts. It included TCP/IP
networking, networking tools (*ftp*,
*netstat*, *rlogin*,
*routed*, *rsh* , *rwho*,
*telnet*, *tftp*) from 4.1a, and
filesystem improvements, such as symbolic links, from 4.1b. Sadly,
4.1aBSD and 4.1bBSD are not included in the CSRG CD set, which was
used for obtaining the BSD snapshots for this work.

## BSD-4\_2
4.2BSD (September 1983) was a major release
of features tested in 4.1aBSD to 4.1c. Compared to the preceding
releases it improved networking support and added new signal
facilities and disk quotas.

## BSD-4\_3
4.3BSD (June 1986) came with performance
improvements, a directory name cache, and the BIND internet domain
name system server.

## BSD-4\_3\_Tahoe
4.3BSD Tahoe (June 1988) split the
kernel into machine-dependent and machine-independent parts in order
to include support for the CCI Power 6/32 minicomputer (code-named
*Tahoe*). It also included improved TCP algorithms.

## BSD-4\_3\_Net\_1
4.3BSD Networking Release
(November 1988) is a subset of the code that does not include
material requiring an  license. It was released to help vendors
create standalone networking products, without incurring the  binary
license costs. It included the BSD networking kernel code and
supporting utilities.

## BSD-4\_3\_Reno
4.3BSD Reno (June 1990) supported
virtual file system implementations through the *vnode*
interface, Hewlett-Packard 9000/300 workstations, and OSI
networking. It also incorporated a new virtual memory system adapted
from Carnegie-Mellon’s MACH operating system, a Network File
System (NFS) implementation done at the University of Guelph, and an
automounter daemon. Considerable material in this release was
copyrighted by Berkeley with a license allowing the easy
redistribution and reuse of those parts.

## BSD-4\_3\_Net\_2
4.3BSD Networking Release 2 (June 1991)
came with (what is now called) an open source reimplementation
of almost all important utilities and libraries that used to require
an  license. It also included a kernel that had been cleaned from
 source code, requiring just six additional files to make a
fully-functioning system. This was the version used by Bill Jolitz
to create a compiled bootable Unix system for the 386-based PCs.

## BSD-4\_4\_Lite1
4.4BSD Lite (June 1994) was released
following two years of litigation and settlement talks regarding the
alleged use of proprietary  material between a) Unix System
Laboratories (USL — a wholly owned subsidiary of  that developed and
marketed Unix) and (later) USL’s new owner, Novell and b) Berkeley
Software Design Incorporated (BSDI — a developer of commercially
supported version of BSD Unix) and the University of California. As
a result this release removed three files that were included in the
*Net/2* release, added USL copyrights to about 70
files, and made minor changes to a few others. With these changes
and according to the settlement’s terms USL could not sue third
parties basing their code on this release. Consequently, efforts
such as  and NetBSD rebased their work on this code base. The
release also included additional work done on the system, such as
support for the portal filesystem.

## BSD-4\_4
4.4BSD, released at the same time as 4.4BSD Lite, was
an “encumbered” version of 4.4-Lite that included the files
requiring an  license.

## BSD-4\_4\_Lite2
4.4-Lite Release 2 (June 1995) was
the last release made by CSRG before the group was disbanded. It
included bug fixes and enhancements integrated through funding
obtained from the distribution of 4.4.

# 386/BSD

## 386BSD–0.0
386/BSD 0.0 (March 1992)
is a derivative of the BSD Networking 2
Release developed by Lynne and William Jolitz, who wrote the six missing
kernel files targetting the Intel 386 architecture.
A description of this system was published as a series of 18 articles in the
*Dr.  Dobb’s Journal*.

## 386BSD–0.1
386/BSD 0.1 (July 1992) is the second release of 386/BSD.

## 386BSD–0.1-patchkit
The 386BSD-0.1-patchkit branch (29 June 1992 to 20 June 1993)
contains 171 commits associated with patches made to 386BSD 0.1
by a group of volunteers from mid-1992 to mid-1993.
Patches contain their changes in Unix “context diff”
format, and can therefore be applied automatically to the 386BSD
distribution. Each patch is accompanied by a metadata file listing its
title, author, description, and prerequisites.

# FreeBSD–release/
The *FreeBSD–release/X* tags and branches mark 69 releases
derived from the FreeBSD Project. The names of tags and branches to be imported
are obtained by excluding from the corresponding  set names matching one
of the following patterns: `projects/`, `user/`, `master`, or `svn\_head`.
The  FreeBSD Project started in early 1993 to address difficulties in
maintaining 386/BSD through patches and working with its author to secure
the future of 386/BSD.
The focus of the project was to support the PC architecture appealing to a
large, not necessarily highly technically sophisticated audience. For
legal reasons associated with the settlement of the USL case, while
versions up to 1.1.5.1 were derived from the BSD Networking 2 Release,
later ones were derived from the 4.4-Lite Release 2 with 386/BSD
additions.
