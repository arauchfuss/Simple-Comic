#ifndef __DES_H__
#define __DES_H__

#include <stdint.h>

typedef struct DES_key_schedule
{
	struct DES_key_stage
	{
		uint32_t h, l;
	} KS[16];
} DES_key_schedule;

void DES_set_key(const uint8_t key[8],DES_key_schedule *ks);
void DES_encrypt(uint8_t block[8],int decrypt,DES_key_schedule *ks);

#endif
