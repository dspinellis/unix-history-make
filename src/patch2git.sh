#!/bin/bash
#
# Convert the 386BSD patchkit into a series of Git commits
#
# Copyright 2016 Diomidis Spinellis
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if [ "$1" = -d ] ; then
  DEBUG=1
fi

# Unix history make source directory
SRCDIR=$(pwd)

# Directory where patches will be imported as Git
PATCHED=$SRCDIR/archive/386BSD-0.1-patched

# A work copy of the patchkit
WORK=$SRCDIR/archive/386BSD-patchkit.work

# Script to restore relative symbolic links
RESTORE_LINKS=/tmp/$$.restore-links

# Commit message
MESSAGE=/tmp/$$.message

# All inbound patches
INBOUND=$SRCDIR/archive/386BSD-patchkit/inbound/

# Convert absolute symbolic links to relative keeping a backup
# These are required in order to apply patches referring to linked files
relative_links()
{
  echo Making symlinks relative
  # Create restore script
  cd $PATCHED &&
  find . -lname '/*' |
  while read l ; do
    echo ln -snf $(readlink $l) $l
  done >$RESTORE_LINKS &&
  # Convert links
  find . -lname '/*' |
  while read l ; do
    echo ln -snf $(echo $(echo $l | sed 's|/[^/]*|/..|g')$(readlink $l) | sed 's/.....//') $l
  done |
  sh
  cd $SRCDIR
}

absolute_links()
{
  echo Restoring synlinks
  cd $PATCHED &&
  sh $RESTORE_LINKS
  cd $SRCDIR
}


# Create working copies
sudo rm -rf $PATCHED &&
  mkdir $PATCHED &&
  tar -C archive/386BSD-0.1 -cf - . | tar -C $PATCHED -xpf -
chmod -R u+w $PATCHED
sudo rm -rf $WORK && cp -r archive/386BSD-patchkit $WORK

# Remove non-source files
mv $PATCHED/dev/MAKEDEV /tmp/MAKEDEV.$$
cd $PATCHED &&
  grep -v '^#' $SRCDIR/ignore/386BSD-0.1 | xargs rm -rf

# Reinstate stuff required by various patches
mv /tmp/MAKEDEV.$$ $PATCHED/dev/MAKEDEV
mkdir -p $PATCHED/usr/bin
mkdir -p $PATCHED/usr/share/man/cat1 $PATCHED/usr/share/misc
mkdir -p $PATCHED/var $PATCHED/dev

# Quickly verify patches
if [ -n "$DEBUG" ] ; then
  relative_links

  git()
  {
    :
  }
  relative_links()
  {
    :
  }
  absolute_links()
  {
    :
  }
fi

# Initialize Git repo
cd $PATCHED &&
  git init &&
  git add . &&
  GIT_AUTHOR_NAME='William F. Jolitz and Lynne Greer Jolitz' \
  GIT_AUTHOR_EMAIL='{wjolitz@soda.berkeley.edu,ljolitz@cardio.ucsf.edu}' \
  GIT_AUTHOR_DATE=$(date +%FT%TZ -d 'Jul 14 1992 20:32:23 -0800') \
  GIT_COMMITTER_NAME='William F. Jolitz and Lynne Greer Jolitz' \
  GIT_COMMITTER_EMAIL='{wjolitz@soda.berkeley.edu,ljolitz@cardio.ucsf.edu}' \
  GIT_COMMITTER_DATE=$(date +%FT%TZ -d 'Jul 14 1992 20:32:23 -0800') \
  git commit -m '386BSD 0.1 before patchkit commits'
  cd $SRCDIR

# Commit patches
(cd $INBOUND && ls -d patch* | grep -v patch90) |
while read patch ; do
  echo $patch

  # Patch
  relative_links
  chmod -R u+w $PATCHED
  PATH=patch:$PATH $SRCDIR/patch-386bsd.sh $PATCHED $WORK $patch || break
  absolute_links

  # Commit
  export GIT_AUTHOR_NAME=$(awk -F$'\t' '$1 == "'$patch'" {print $2; exit}' author-path/386bsd-patch)
  export GIT_AUTHOR_EMAIL=$(awk -F: '$1 == "'"$GIT_AUTHOR_NAME"'" {print $2}' 386bsd-patch.au)
  export GIT_AUTHOR_DATE=$(date +%FT00:00Z -d "$(awk -F: '$1 == "'$patch'" {print $2}' 386bsd-patch.date)")
  export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME
  export GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL
  export GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE

  # Synopsis
  sed -n 's/^PATCH:[ \t]*//p' $INBOUND/$patch/PATCH >$MESSAGE
  echo >>$MESSAGE
  # Description
  sed -n '/^DESCRIPTION:/,/^%%/ {/^DESCRIPTION:/d; /^%%/d; p; }' $INBOUND/$patch/PATCH >>$MESSAGE
  echo >>$MESSAGE
  grep '^AUTHOR:' $INBOUND/$patch/PATCH >>$MESSAGE
  echo "386BSD-Patchkit: $patch" >>$MESSAGE

  (
    cd $PATCHED &&
      git add . &&
      git commit -a -F $MESSAGE
  )
done

cd $PATCHED &&
  git branch -m master 386BSD-0.1-patchkit &&
  cd $SRC

if [ -z "$DEBUG" ] ; then
  rm -rf $WORK $RESTORE_LINKS $MESSAGE
fi
