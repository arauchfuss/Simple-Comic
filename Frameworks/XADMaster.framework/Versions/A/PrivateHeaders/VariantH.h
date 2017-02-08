#ifndef __PPMD_VARIANT_H_H__
#define __PPMD_VARIANT_H_H__

#include "Context.h"
#include "SubAllocatorVariantH.h"

// PPMd Variant H. Used by RAR and 7-Zip.

typedef struct PPMdModelVariantH
{
	PPMdCoreModel core;

	PPMdSubAllocatorVariantH *alloc;

	PPMdContext *MinContext,*MaxContext;
	int MaxOrder,HiBitsFlag;
	bool SevenZip;
	SEE2Context SEE2Cont[25][16],DummySEE2Cont;
	uint8_t NS2BSIndx[256],HB2Flag[256],NS2Indx[256];
	uint16_t BinSumm[128][64]; // binary SEE-contexts
} PPMdModelVariantH;

void StartPPMdModelVariantH(PPMdModelVariantH *self,
PPMdReadFunction *readfunc,void *inputcontext,
PPMdSubAllocatorVariantH *alloc,int maxorder,bool sevenzip);
void RestartPPMdVariantHRangeCoder(PPMdModelVariantH *self,
PPMdReadFunction *readfunc,void *inputcontext,
bool sevenzip);
int NextPPMdVariantHByte(PPMdModelVariantH *self);

#endif
