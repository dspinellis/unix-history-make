#!/bin/sh
#
# Rename the Second Edition fragments into files
# Based on the file Fraglist and the binary timestamps of
# http://www.tuhs.org/Archive/PDP-11/Distributions/research/1972_stuff/Readme
#

# Epoch specified in modern Epoch units
EPOCH=$(date +'%s' -d '1972/01/01 00:00 UTC')

# Default timestamp (max + min) / 2
DEFAULT=1041055444

# Establish the specified command from the specified fragment
# Third argument is 1/60th second units from 1/1/1972
est()
{
  FROM=$1
  TO=$2
  TS=$3
  mv $1 $2
  touch -d @$(expr $TS / 60 + $EPOCH) $TO
}


rm Fraglist
rm frag0			# Asm, starts with dska as an operand
est frag1 glob.c 29812654  	# global command
est frag2 init.s 2081988977 	# process control initialization
est frag3 ldx.s 937319472  	# link editor
est frag4 ld2.s 937319472  	# link editor
est frag5 df.s 1689030995  	# find free space
est frag6 dusg.s $DEFAULT	# summarize disk usage
est frag7 fc.c 761966733	# fortran command 
est frag8 fstrip.s $DEFAULT	# remove fortran internal symbols
rm frag9			# Asm, starts with f'n allocate (here to allocate a new block)
est frag10 colon.s $DEFAULT 	# do nothing
est frag11 acct.s $DEFAULT 	# time accounting
rm frag12			# Asm, starts with .globl getchar, fns length, position, getword
est frag13 bas1.s 86819408  	# compile
est frag14 bas0.s 86819408  	# basic
est frag15 getty.s 501264829  	#  get name and tty mode
est frag16 ld1.s 937319472  	# link editor
rm frag17			# Asm, routine div3 to divide the two centennial numbers
rm frag18			# Asm, routine add3 to add the two centennial numbers
est frag19 ls.s 86809182  	# list file or directory
est frag20 login.s 454317684  	#  enter new user
est frag21 date.s 570186721  	# get/set date
est frag22 as9.s 936962166   	# PDP-11 assembler pass 2
est frag23 cmp.s 86808947 	# compare files
est frag24 as8.s 936962166   	# PDP-11 assembler pass 2
est frag25 cat.s 86808907 	# concatinate files
est frag26 dsw.s 86819407 	# delete from tty
est frag27 a7.s 936955268  	# pdp-11 assembler
est frag28 ln.s 86809162 	# link command
est frag29 a6.s 936962166   	# pdp-11 assembler pass 2
est frag30 chown.s 1689737545 	# change owner
est frag31 as25.s 936955268  	# part of as?, says it is empty
est frag32 ar.s 133346922 	# archive/library
est frag33 a4.s 936962166   	# pdp-11 assembler pass 2
est frag34 a3.s 936962166   	# pdp-11 assembler pass 2
est frag35 a2.s 936962166   	# pdp-11 assembler pass 2
est frag36 a21.s 936962166   	# pdp-11 assembler pass 2
est frag37 a9.s 936955268  	# pdp-11 assembler pass 1
est frag38 a8.s 936955268  	# pdp-11 assembler pass 1
est frag39 a7.s 936955268  	# pdp-11 assembler pass 1
est frag40 a6.s 936955268  	# pdp-11 assembler pass 1
est frag41 a5.s 936955268  	# pdp-11 assembler pass 1
est frag42 db4.s 454616955  	# debugger
est frag43 db3.s 454616955  	# debugger
est frag44 db2.s 454616955  	# debugger
est frag45 a4.s 936955268  	# pdp-11 assembler pass1
est frag46 a3.s 936955268  	# pdp-11 assembler pass 1
est frag47 a2.s 936955268  	# pdp-11 assembler pass 1
est frag48 a1.s 936955268  	# pdp-11 assembler pass 1
est frag49 db1.s 454616955 	# debugger
est frag50 chmod.s 86808926 	# change mode
est frag51 if.c 86819396 	# if command
est frag52 cc.c 937848855 	# C command
rm frag53			# Asm, part of form letter form.s, starts with testing = 0
est frag54 cp.c 86808966 	# copy command
rm frag55			# Asm, starts with lots of globals, e.g .globl b1
rm frag56			# Asm, starts with lots of globals, e.g .globl b1, see also frag9
rm frag57			# C code, starts with int	offset	0;
rm frag58			# Asm, starts with scan f'n and /	scan
rm frag59			# Asm, starts with esub f'n and /	esub
rm frag60			# Asm, starts with accept f'n and rti = 2
rm frag61			# Asm, command interpreter for form letter editor, starts with testing = 0
rm frag62			# Asm, remove a file from memory, starts with :	</bin/ed\0>
rm frag63			# C, /* exit -- end runcom */
rm frag64			# C code, no idea, starts with char b[242];
rm frag65			# Asm, no idea, starts with rti = 2
rm frag66			# Asm, no idea, starts with :
rm frag67			# Asm, no idea, starts with br	1b
rm frag68			# No idea, starts with tc/init
rm frag69			# No idea, starts with seek error
