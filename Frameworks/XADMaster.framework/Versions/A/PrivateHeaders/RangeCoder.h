#ifndef __PPMD_RANGE_CODER_H__
#define __PPMD_RANGE_CODER_H__

#include <stdint.h>
#include <stdbool.h>

typedef int PPMdReadFunction(void *context);

typedef struct PPMdRangeCoder
{
	PPMdReadFunction *readfunc;
	void *inputcontext;

	uint32_t low,code,range,bottom;
	bool uselow;
} PPMdRangeCoder;

void InitializePPMdRangeCoder(PPMdRangeCoder *self,
PPMdReadFunction *readfunc,void *inputcontext,
bool uselow,int bottom);

uint32_t PPMdRangeCoderCurrentCount(PPMdRangeCoder *self,uint32_t scale);
void RemovePPMdRangeCoderSubRange(PPMdRangeCoder *self,uint32_t lowcount,uint32_t highcount);

int NextWeightedBitFromPPMdRangeCoder(PPMdRangeCoder *self,int weight,int size);

int NextWeightedBitFromPPMdRangeCoder2(PPMdRangeCoder *self,int weight,int shift);

void NormalizePPMdRangeCoder(PPMdRangeCoder *self);

#endif
