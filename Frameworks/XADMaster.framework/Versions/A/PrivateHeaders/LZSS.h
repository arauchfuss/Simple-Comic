#ifndef __LZSS_H__
#define __LZSS_H__

#include <stdint.h>
#include <stdbool.h>

typedef struct LZSS
{
	uint8_t *window;
	int mask;
	int64_t position;
} LZSS;



bool InitializeLZSS(LZSS *self,int windowsize);
void CleanupLZSS(LZSS *self);
void RestartLZSS(LZSS *self);



static inline int64_t LZSSPosition(LZSS *self) { return self->position; }

static inline int LZSSWindowMask(LZSS *self) { return self->mask; }

static inline int LZSSWindowSize(LZSS *self)  { return self->mask+1; }

static inline uint8_t *LZSSWindowPointer(LZSS *self)  { return self->window; }

static inline int LZSSWindowOffsetForPosition(LZSS *self,int64_t pos) { return pos&self->mask; }

static inline uint8_t *LZSSWindowPointerForPosition(LZSS *self,int64_t pos)  { return &self->window[LZSSWindowOffsetForPosition(self,pos)]; }

static inline int CurrentLZSSWindowOffset(LZSS *self) { return LZSSWindowOffsetForPosition(self,self->position); }

static inline uint8_t *CurrentLZSSWindowPointer(LZSS *self) { return LZSSWindowPointerForPosition(self,self->position); }

static inline int64_t NextLZSSWindowEdgeAfterPosition(LZSS *self,int64_t pos) { return (pos+LZSSWindowSize(self))&~(int64_t)LZSSWindowMask(self); }

static inline int64_t NextLZSSWindowEdge(LZSS *self) { return NextLZSSWindowEdgeAfterPosition(self,self->position); }




static inline uint8_t GetByteFromLZSSWindow(LZSS *self,int64_t pos)
{
	return *LZSSWindowPointerForPosition(self,pos);
}

void CopyBytesFromLZSSWindow(LZSS *self,uint8_t *buffer,int64_t startpos,int length);




static inline void EmitLZSSLiteral(LZSS *self,uint8_t literal)
{
	*CurrentLZSSWindowPointer(self)=literal;
//	self->window[(self->position)&self->mask]=literal;
	self->position++;
}

static inline void EmitLZSSMatch(LZSS *self,int offset,int length)
{
	int windowoffs=CurrentLZSSWindowOffset(self);

	for(int i=0;i<length;i++)
	{
		self->window[(windowoffs+i)&LZSSWindowMask(self)]=
		self->window[(windowoffs+i-offset)&LZSSWindowMask(self)];
	}

	self->position+=length;
}

#endif

