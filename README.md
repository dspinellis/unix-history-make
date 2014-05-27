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
Currently, the project has finished the concept demonstration stage with the creation of a repository containing the V5, V6, and V7 Research Edition Unix snapshots.  The files appear to be added in the repository in chronological order according to their modification time, and some part part of the source code has been attributed to its actual authors.  Commands like `git blame` and `git log` produce the expected results.

Future plans involve the integration of BSD snapshots, the BSD SCCS repository, and the FreeBSD repository.

## Branches and tags
The following branches are included in the `unix-history-repo`.
* Research-Development-V5
* Research-Development-V6
* Research-Development-V7
* Research-Release

The -Development branches contain a commit for every file that was added during the development of the corresponding system. The `Research-Release` branch has each development cycle merged into it.
In addition, the following tags mark specific releases.
* Epoch
* Research-V5
* Research-V6
* Research-V7

## Cool things you can do
Run
```sh
git clone https://github.com/dspinellis/unix-history-repo
git checkout Research-Release
```
to get a local copy of the Unix history repository.
### View log across releases
Running
```sh
git log --reverse --date-order
```
will give you commits like the following

```
commit b7b2640b9e27415d453a8fbe975a87902a01849d
Author: Ken Thompson <research!ken>
Date:   Tue Nov 26 18:13:21 1974 -0500

    Research V5 development

    Add file usr/sys/ken/slp.c
[...]
commit 3d19667a65d35a411d911282ed8b87e32a56a349
Author: Dennis Ritchie <research!dmr>
Date:   Mon Dec 2 18:18:02 1974 -0500

    Research V5 development

    Add file usr/sys/dmr/kl.c
[...]
commit 171931a3f6f28ce4d196c20fdec6a4413a843f89
Author: Brian W. Kernighan <research!bwk>
Date:   Tue May 13 19:43:47 1975 -0500

    Research V6 development

    Add file rat/r.g
[...]
commit ac4b13bca433a44a97689af10247970118834696
Author: S. R. Bourne <research!srb>
Date:   Fri Jan 12 02:17:45 1979 -0500

    Research V7 development

    Add file usr/src/cmd/sh/blok.c
```
### View changes to a specific file
Run
```sh
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
abaf72cd usr/sys/sys/pipe.c (Ken Thompson 1979-01-10 15:19:35 -0500  39) 	r = u.u_r.r_val1;
5161b35e usr/sys/ken/pipe.c (Ken Thompson 1975-07-17 10:33:37 -0500  40) 	wf = falloc();
5161b35e usr/sys/ken/pipe.c (Ken Thompson 1975-07-17 10:33:37 -0500  41) 	if(wf == NULL) {
5161b35e usr/sys/ken/pipe.c (Ken Thompson 1975-07-17 10:33:37 -0500  42) 		rf->f_count = 0;
5161b35e usr/sys/ken/pipe.c (Ken Thompson 1975-07-17 10:33:37 -0500  43) 		u.u_ofile[r] = NULL;
5161b35e usr/sys/ken/pipe.c (Ken Thompson 1975-07-17 10:33:37 -0500  44) 		iput(ip);
5161b35e usr/sys/ken/pipe.c (Ken Thompson 1975-07-17 10:33:37 -0500  45) 		return;
5161b35e usr/sys/ken/pipe.c (Ken Thompson 1975-07-17 10:33:37 -0500  46) 	}
abaf72cd usr/sys/sys/pipe.c (Ken Thompson 1979-01-10 15:19:35 -0500  47) 	u.u_r.r_val2 = u.u_r.r_val1;
abaf72cd usr/sys/sys/pipe.c (Ken Thompson 1979-01-10 15:19:35 -0500  48) 	u.u_r.r_val1 = r;
7aa93549 usr/sys/ken/pipe.c (Ken Thompson 1974-11-26 18:13:21 -0500  49) 	wf->f_flag = FWRITE|FPIPE;
7aa93549 usr/sys/ken/pipe.c (Ken Thompson 1974-11-26 18:13:21 -0500  50) 	wf->f_inode = ip;
7aa93549 usr/sys/ken/pipe.c (Ken Thompson 1974-11-26 18:13:21 -0500  51) 	rf->f_flag = FREAD|FPIPE;
```
## How you can help
You can help if you were there at the time, or if you can locate a
source that contains information that is currently missing.
* Look for errors and omissions in the files that map file paths to
  authors for the
  [5th](https://github.com/dspinellis/unix-history-make/blob/master/src/v5.map),
  [6th](https://github.com/dspinellis/unix-history-make/blob/master/src/v6.map), and
  [7th](https://github.com/dspinellis/unix-history-make/blob/master/src/v7.map)
  Edition Unix.
* Look for parts of the system that have not yet been attributed in the
  [5th](https://github.com/dspinellis/unix-history-make/blob/master/src/v5.unmatched),
  [6th](https://github.com/dspinellis/unix-history-make/blob/master/src/v6.unmatched), and
  [7th](https://github.com/dspinellis/unix-history-make/blob/master/src/v7.unmatched)
  Edition Unix, and propose suitable attributions.
* Look for authors whose identifier starts with ```x-``` in the
  [author id to name map file](https://github.com/dspinellis/unix-history-make/blob/master/src/bell.au),
  and provide or confirm their actual login identifier.
  (The one used is a guess.)
* Contribute a path regular expression to contributor map file 
  ( see [v7.map](https://github.com/dspinellis/unix-history-make/blob/master/src/v7.map)) for
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
