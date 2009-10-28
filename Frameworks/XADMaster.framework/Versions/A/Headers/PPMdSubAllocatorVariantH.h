#import "PPMdSubAllocator.h"

typedef struct PPMdSubAllocatorVariantH
{
	PPMdSubAllocator core;

	long SubAllocatorSize;
	uint8_t Index2Units[38],Units2Index[128],GlueCount;
	uint8_t *pText,*UnitsStart,*LowUnit,*HighUnit;
	struct PPMAllocatorNodeVariantH { struct PPMAllocatorNodeVariantH *next; } FreeList[38];
	uint8_t HeapStart[0];
} PPMdSubAllocatorVariantH;

PPMdSubAllocatorVariantH *CreateSubAllocatorVariantH(int size);
void FreeSubAllocatorVariantH(PPMdSubAllocatorVariantH *self);
