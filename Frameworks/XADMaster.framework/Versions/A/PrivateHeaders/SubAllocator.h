#ifndef __PPMD_SUB_ALLOCATOR_H__
#define __PPMD_SUB_ALLOCATOR_H__

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>

typedef struct PPMdSubAllocator PPMdSubAllocator;

struct PPMdSubAllocator
{
	void (*Init)(PPMdSubAllocator *self);
	uint32_t (*AllocContext)(PPMdSubAllocator *self);
	uint32_t (*AllocUnits)(PPMdSubAllocator *self,int num);  // 1 unit == 12 bytes, NU <= 128
	uint32_t (*ExpandUnits)(PPMdSubAllocator *self,uint32_t oldoffs,int oldnum);
	uint32_t (*ShrinkUnits)(PPMdSubAllocator *self,uint32_t oldoffs,int oldnum,int newnum);
	void (*FreeUnits)(PPMdSubAllocator *self,uint32_t offs,int num);
};

static inline void InitSubAllocator(PPMdSubAllocator *self) { self->Init(self); };
static inline uint32_t AllocContext(PPMdSubAllocator *self) { return self->AllocContext(self); }
static inline uint32_t AllocUnits(PPMdSubAllocator *self,int num) { return self->AllocUnits(self,num); }
static inline uint32_t ExpandUnits(PPMdSubAllocator *self,uint32_t oldoffs,int oldnum) { return self->ExpandUnits(self,oldoffs,oldnum); }
static inline uint32_t ShrinkUnits(PPMdSubAllocator *self,uint32_t oldoffs,int oldnum,int newnum) { return self->ShrinkUnits(self,oldoffs,oldnum,newnum); }
static inline void FreeUnits(PPMdSubAllocator *self,uint32_t offs,int num) { return self->FreeUnits(self,offs,num); }

// TODO: Keep pointers as pointers on 32 bit, and offsets on 64 bit.

static inline void *OffsetToPointer(void *base,uint32_t offset)
{
	if(!offset) return NULL;
	return ((uint8_t *)base)+offset;
}

static inline uint32_t PointerToOffset(void *base,void *pointer)
{
	if(!pointer) return 0;
	return (uint32_t)(((uintptr_t)pointer)-(uintptr_t)base);
}

#endif
