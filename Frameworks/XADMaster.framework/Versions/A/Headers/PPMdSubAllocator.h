#import <Foundation/Foundation.h>

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

static inline void *OffsetToPointer(PPMdSubAllocator *self,uint32_t offset)
{
	if(!offset) return NULL;
	return ((uint8_t *)self)+offset;
}

static inline uint32_t PointerToOffset(PPMdSubAllocator *self,void *pointer)
{
	if(!pointer) return 0;
	return ((uintptr_t)pointer)-(uintptr_t)self;
}
