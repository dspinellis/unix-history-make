#include <stdint.h>

#define	ARMAG	0177545
struct	ar_hdr {
	char	ar_name[14];
	uint32_t ar_date;
	char	ar_uid;
	char	ar_gid;
	int16_t	ar_mode;
	int32_t	ar_size;
}__attribute__((packed));
