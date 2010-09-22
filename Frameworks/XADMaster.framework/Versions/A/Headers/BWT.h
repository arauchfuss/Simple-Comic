#ifndef __BWT_H__
#define __BWT_H__

#include <stdint.h>

void CalculateInverseBWT(uint32_t *transform,uint8_t *block,int blocklen);
void UnsortBWT(uint8_t *dest,uint8_t *src,int blocklen,int firstindex,uint32_t *transformbuf);

void UnsortST4(uint8_t *dest,uint8_t *src,int blocklen,int firstindex,uint32_t *transformbuf);

typedef struct MTFState
{
	int table[256];
} MTFState;

void ResetMTFDecoder(MTFState *self);
int DecodeMTF(MTFState *self,int symbol);
void DecodeMTFBlock(uint8_t *block,int blocklen);
void DecodeM1FFNBlock(uint8_t *block,int blocklen,int order);

#endif
