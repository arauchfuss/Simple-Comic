#ifndef __LZW_H__
#define __LZW_H__

#include <stdint.h>

#define LZWNoError 0
#define LZWInvalidCodeError 1
#define LZWTooManyCodesError 2

typedef struct LZWTreeNode
{
	uint8_t chr;
	int parent;
} LZWTreeNode;

typedef struct LZW
{
	LZWTreeNode *nodes;
	int numsymbols,maxsymbols,reservedsymbols;
	int prevsymbol;
} LZW;

LZW *AllocLZW(int maxsymbols,int reservedsymbols);
void FreeLZW(LZW *self);
void ClearLZWTable(LZW *self);
int NextLZWSymbol(LZW *self,int symbol);
int LZWOutputLength(LZW *self);
int LZWOutputToBuffer(LZW *self,uint8_t *buffer);
int LZWReverseOutputToBuffer(LZW *self,uint8_t *buffer);
int LZWSymbolCount(LZW *self);
int LZWSymbolListFull(LZW *self);

#endif

