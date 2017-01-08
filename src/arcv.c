/*
 * Convert old to new archive format
*/

#include <endian.h>
#include <stdio.h>
#include <signal.h>
#include <stdint.h>
#include "ar.h"

#define	omag	0177555

/*
 * See:
 * http://www.tuhs.org/Archive/PDP-11/Distributions/research/1972_stuff/Readme
 * The epoch was determined so that the files in last1120c/rt/libc.sa would
 * not appear to be after the archive's creation date.
 * date -d '1971-01-01 00:00 UTC' +%s
 */
#define EPOCH_V2 31536000

struct	ar_hdr nh;
struct
{
	char	oname[8];
	uint32_t odate;
	char	ouid;
	char	omode;
	uint16_t siz;
} __attribute__((packed)) oh;

#if BYTE_ORDER == LITTLE_ENDIAN
#define PDPTOHL(x) (((x & 0xffff) << 16) | ((x & 0xffff0000) >> 16))
#define HTOPDPL(x) PDPTOHL(x)
#else
#define SWITCHWORD(x) (((x & 0xff) << 8) | ((x & 0xff00) >> 8))
#define PDPTOHL(x) \
		((SWITCHWORD(x & 0xffff) << 16) \
		 | SWITCHWORD((x & 0xffff0000) >> 16))
#define HTOPDPL(x) PDPTOHL(x)
#endif


char	*tmp;
char	*mktemp();
int	f;
int	tf;
union {
	char	buf[512];
	uint16_t	magic;
} b;

main(argc, argv)
char *argv[];
{
	register i;
	char template[] = "/tmp/arcXXXXXX";

	tmp = mktemp(template);
	for(i=1; i<4; i++)
		signal(i, SIG_IGN);
	for(i=1; i<argc; i++)
		conv(argv[i]);
	unlink(tmp);
}

conv(fil)
char *fil;
{
	register unsigned i, n;

	f = open(fil, 2);
	if(f < 0) {
		printf("arcv: cannot open %s\n", fil);
		return;
	}
	close(creat(tmp, 0600));
	tf = open(tmp, 2);
	if(tf < 0) {
		printf("arcv: cannot open temp\n");
		close(f);
		return;
	}
	b.magic = 0;
	read(f, (char *)&b.magic, sizeof(b.magic));
	if(b.magic != omag) {
		printf("arcv: %s not archive format (0%o != 0%o)\n", fil,
				b.magic, omag);
		close(tf);
		close(f);
		return;
	}
	b.magic = ARMAG;
	write(tf, (char *)&b.magic, sizeof(b.magic));
loop:
	i = read(f, (char *)&oh, sizeof(oh));
	if(i != sizeof(oh))
		goto out;
	for(i=0; i<8; i++)
		nh.ar_name[i] = oh.oname[i];
	/* Convert from 16 bit to 32 bit */
	nh.ar_size = HTOPDPL(oh.siz);
	nh.ar_uid = oh.ouid;
	nh.ar_gid = 1;
	nh.ar_mode = 0666;
	/* Adjust epoch and HZ */
	nh.ar_date = HTOPDPL(PDPTOHL(oh.odate) / 60 + EPOCH_V2);
	n = (oh.siz+1) & ~01;
	write(tf, (char *)&nh, sizeof(nh));
	while(n > 0) {
		i = 512;
		if(n < i)
			i = n;
		read(f, b.buf, i);
		write(tf, b.buf, i);
		n -= i;
	}
	goto loop;
out:
	lseek(f, 0L, 0);
	lseek(tf, 0L, 0);
	while((i=read(tf, b.buf, 512)) > 0)
		write(f, b.buf, i);
	close(f);
	close(tf);
}
