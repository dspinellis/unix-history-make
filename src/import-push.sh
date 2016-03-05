#!/bin/sh
OUT="out/$(date +%FT%T)"
mkdir $OUT
nohup sh -c "
  nice ./import.sh >$OUT/import.out 2>$OUT/import.err &&
  nice ./github-push.sh 2>$OUT/github-push.err >$OUT/github-push.out
" >/dev/null 2>&1
