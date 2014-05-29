# Unix History Repository

The goal of this project is to create a git repository representing the Unix source code history, starting from the 1970s and ending in the modern time.  To fulfill this goal the project brings data from early snapshots, repositories, and primary research.  The project aims to put in the repository as much metadata as possible, allowing the automated analysis of Unix history.  The following table illustrates the type of material that can be gathered and integrated into the repository.

             |Snapshot | Repository | Primary Research
-------------|---------|------------|-----------------
Source Code  |    X    |      X     |
Time         |    X    |      X     |
Contributors |         |      X     |       X
Branches     |         |      X     |       X

Two repositories are associated with the project:
* [unix-history-repo](https://github.com/dspinellis/unix-history-repo) is
  a repository representing a
  reconstructed version of the Unix history, based on the currently
  available data. This repository will be often automatically regenerated from
  scratch, so this is not a place to make contributions.
* [unix-history-make](https://github.com/dspinellis/unix-history-make) is
  a repository containing code and metadata used to build the above repository.
  Contributions to this repository are welcomed.

The first phase of the project will be to create a single timeline from the First Edition of Unix until the present.

## Project status
Currently, the project is maturing with the creation of a repository containing snapshots of V1, V3, V4, V5, V6, and V7 Research Edition, Unix/32V, 1BSD, 2BSD, and 3BSD.    The files appear to be added in the repository in chronological order according to their modification time, and some part part of the source code has been attributed to its actual authors.  Commands like `git blame` and (sometimes) `git log` produce the expected results.

The repository contains the first two-way merge (3BSD merged from Unix/32V and Research Edition 6), and blame is apportioned appropriately.

Future plans involve the integration of further BSD snapshots, the BSD SCCS repository, and the FreeBSD repository.

## Branches and tags
The following branches are included in the `unix-history-repo`.
* Research-Release
* Research-Development-V1
* Research-Development-V3
* Research-Development-V4
* Research-Development-V5
* Research-Development-V6
* Research-Development-V7
* Bell-Release
* Bell-Development-32V
* BSD-Release
* BSD-Development-1
* BSD-Development-2
* BSD-Development-3

The -Development branches contain a commit for every file that was added during the development of the corresponding system. The `*-Release` branches have each development cycle merged into them.
In addition, the following tags mark specific releases, listed in chronological order.
* Epoch
* Research-V1
* Research-V3
* Research-V4
* Research-V5
* Research-V6
* BSD-1
* BSD-2
* Research-V7
* Bell-32V
* BSD-3

## Cool things you can do
Run
```sh
git clone https://github.com/dspinellis/unix-history-repo
git checkout BSD-Release
```
to get a local copy of the Unix history repository.
### View log across releases
Running
```sh
git log --reverse --date-order
```
will give you commits like the following

```
commit 94a21182365ebb258eeee2aa41c5fbcb1f7fd566
Author: Ken Thompson and Dennis Ritchie <research!{ken,dmr}>
Date:   Tue Jun 20 04:00:00 1972 -0500

    Research V1 development

    Work on file u5.s
[...]
commit b7b2640b9e27415d453a8fbe975a87902a01849d
Author: Ken Thompson <research!ken>
Date:   Tue Nov 26 18:13:21 1974 -0500

    Research V5 development

    Work on file usr/sys/ken/slp.c
[...]
commit 3d19667a65d35a411d911282ed8b87e32a56a349
Author: Dennis Ritchie <research!dmr>
Date:   Mon Dec 2 18:18:02 1974 -0500

    Research V5 development

    Work on file usr/sys/dmr/kl.c
[...]
commit 171931a3f6f28ce4d196c20fdec6a4413a843f89
Author: Brian W. Kernighan <research!bwk>
Date:   Tue May 13 19:43:47 1975 -0500

    Research V6 development

    Work on file rat/r.g
[...]
commit ac4b13bca433a44a97689af10247970118834696
Author: S. R. Bourne <research!srb>
Date:   Fri Jan 12 02:17:45 1979 -0500

    Research V7 development

    Work on file usr/src/cmd/sh/blok.c
[...]
Author: Eric Schmidt <x-ees@ucbvax.Berkeley.EDU>
Date:   Sat Jan 5 22:49:18 1980 -0800

    BSD 3 development

    Work on file usr/src/cmd/net/sub.c
```
### View changes to a specific file
Run
```sh
git checkout Research-Release
git log --follow --simplify-merges usr/src/cmd/c/c00.c
```
to see dates on which the C compiler was modified.
### Annotate lines in a specific file by their version
Run
```
git blame -C -C usr/sys/sys/pipe.c
```
to see how the Unix pipe functionality evolved over the years.
```
3cc1108b usr/sys/ken/pipe.c     (Ken Thompson 1974-11-26 18:13:21 -0500  53) 	rf->f_flag = FREAD|FPIPE;
3cc1108b usr/sys/ken/pipe.c     (Ken Thompson 1974-11-26 18:13:21 -0500  54) 	rf->f_inode = ip;
3cc1108b usr/sys/ken/pipe.c     (Ken Thompson 1974-11-26 18:13:21 -0500  55) 	ip->i_count = 2;
[...]
1f183be2 usr/sys/sys/pipe.c     (Ken Thompson 1979-01-10 15:19:35 -0500 122) 	register struct inode *ip;
1f183be2 usr/sys/sys/pipe.c     (Ken Thompson 1979-01-10 15:19:35 -0500 123) 
1f183be2 usr/sys/sys/pipe.c     (Ken Thompson 1979-01-10 15:19:35 -0500 124) 	ip = fp->f_inode;
1f183be2 usr/sys/sys/pipe.c     (Ken Thompson 1979-01-10 15:19:35 -0500 125) 	c = u.u_count;
1f183be2 usr/sys/sys/pipe.c     (Ken Thompson 1979-01-10 15:19:35 -0500 126) 
1f183be2 usr/sys/sys/pipe.c     (Ken Thompson 1979-01-10 15:19:35 -0500 127) loop:
1f183be2 usr/sys/sys/pipe.c     (Ken Thompson 1979-01-10 15:19:35 -0500 128) 
1f183be2 usr/sys/sys/pipe.c     (Ken Thompson 1979-01-10 15:19:35 -0500 129) 	/*
9a9f6b22 usr/src/sys/sys/pipe.c (Bill Joy     1980-01-05 05:51:18 -0800 130) 	 * If error or all done, return.
9a9f6b22 usr/src/sys/sys/pipe.c (Bill Joy     1980-01-05 05:51:18 -0800 131) 	 */
9a9f6b22 usr/src/sys/sys/pipe.c (Bill Joy     1980-01-05 05:51:18 -0800 132) 
9a9f6b22 usr/src/sys/sys/pipe.c (Bill Joy     1980-01-05 05:51:18 -0800 133) 	if (u.u_error)
9a9f6b22 usr/src/sys/sys/pipe.c (Bill Joy     1980-01-05 05:51:18 -0800 134) 		return;
6d632e85 usr/sys/ken/pipe.c     (Ken Thompson 1975-07-17 10:33:37 -0500 135) 	plock(ip);
6d632e85 usr/sys/ken/pipe.c     (Ken Thompson 1975-07-17 10:33:37 -0500 136) 	if(c == 0) {
6d632e85 usr/sys/ken/pipe.c     (Ken Thompson 1975-07-17 10:33:37 -0500 137) 		prele(ip);
6d632e85 usr/sys/ken/pipe.c     (Ken Thompson 1975-07-17 10:33:37 -0500 138) 		u.u_count = 0;
6d632e85 usr/sys/ken/pipe.c     (Ken Thompson 1975-07-17 10:33:37 -0500 139) 		return;
6d632e85 usr/sys/ken/pipe.c     (Ken Thompson 1975-07-17 10:33:37 -0500 140) 	}
```
## How you can help
You can help if you were there at the time, or if you can locate a
source that contains information that is currently missing.
* Look for errors and omissions in the
  [files that map file paths to authors](https://github.com/dspinellis/unix-history-make/blob/master/src/author-path).
* Look for parts of the system that have not yet been attributed
  [in these files](https://github.com/dspinellis/unix-history-make/blob/master/src/unmatched)
  and propose suitable attributions.
  Keep in mind that attributions for parts that were developed in one place
  and modified elsewhere (e.g. developed at Bell Labs and modified at Berkeley)
  should be for the person who did the modification, not the original author.
* Look for authors whose identifier starts with ```x-``` in the
  author id to name map files for
  [Bell Labs](https://github.com/dspinellis/unix-history-make/blob/master/src/bell.au),
  and
  [Berkeley](https://github.com/dspinellis/unix-history-make/blob/master/src/berkeley.au),
  and provide or confirm their actual login identifier.
  (The one used is a guess.)
* Contribute a path regular expression to contributor map file
  (see [v7.map](https://github.com/dspinellis/unix-history-make/blob/master/src/author-path/v7)) for
  [4.2BSD](http://www.tuhs.org/Archive/4BSD/Distributions/4.2BSD/),
  [4.3BSD](http://www.tuhs.org/Archive/4BSD/Distributions/4.3BSD/),
  [4.3BSD-Reno](http://www.tuhs.org/Archive/4BSD/Distributions/4.3BSD-Reno/),
  [4.3BSD-Tahoe](http://www.tuhs.org/Archive/4BSD/Distributions/4.3BSD-Tahoe/),
  [4.3BSD-Alpha](http://www.tuhs.org/Archive/4BSD/Distributions/4.3BSD-Alpha/), and
  [Net2](http://www.tuhs.org/Archive/4BSD/Distributions/Net2/).

## Acknowledgements
* The following people helped with Bell Labs login identifiers.
 * Arnold D. Robbins
 * Brian W. Kernighan
 * Doug McIlroy
* The following people helped with BSD login identifiers.
 * Anatole Shaw
 * Era Eriksson
