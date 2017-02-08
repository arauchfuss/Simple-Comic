#ifndef __PPMD_VARIANT_G_H__
#define __PPMD_VARIANT_G_H__

#include "Context.h"

// PPMd Variant G. Used (slightly modified) by StuffIt X.

typedef struct PPMdModelVariantG
{
	PPMdCoreModel core;

	PPMdContext *MinContext,*MedContext,*MaxContext;
	int MaxOrder;
	bool Brimstone;
	SEE2Context SEE2Cont[43][8],DummySEE2Cont;
	uint8_t NS2BSIndx[256],NS2Indx[256];
	uint16_t BinSumm[128][16]; // binary SEE-contexts
} PPMdModelVariantG;

void StartPPMdModelVariantG(PPMdModelVariantG *self,
PPMdReadFunction *readfunc,void *inputcontext,
PPMdSubAllocator *alloc,int maxorder,bool brimstone);
int NextPPMdVariantGByte(PPMdModelVariantG *self);

#endif
