#ifndef __PPMD_SUB_ALLOCATOR_VARIANT_G_H__
#define __PPMD_SUB_ALLOCATOR_VARIANT_G_H__

#include "SubAllocator.h"

typedef struct PPMdSubAllocatorVariantG
{
	PPMdSubAllocator core;

	uint32_t SubAllocatorSize;
	uint8_t Index2Units[38],Units2Index[128];
	uint8_t *LowUnit,*HighUnit,*LastBreath;
	struct PPMAllocatorNodeVariantG { struct PPMAllocatorNodeVariantG *next; } FreeList[38];
	uint8_t HeapStart[0];
} PPMdSubAllocatorVariantG;

PPMdSubAllocatorVariantG *CreateSubAllocatorVariantG(int size);
void FreeSubAllocatorVariantG(PPMdSubAllocatorVariantG *self);

#endif
