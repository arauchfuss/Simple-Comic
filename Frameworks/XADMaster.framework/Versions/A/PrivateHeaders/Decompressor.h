#ifndef __WINZIP_JPEG_DECOMPRESSOR_H__
#define __WINZIP_JPEG_DECOMPRESSOR_H__

#include "InputStream.h"
#include "ArithmeticDecoder.h"
#include "JPEG.h"

#include <stdint.h>
#include <stdbool.h>

#define WinZipJPEGNoError 0
#define WinZipJPEGEndOfStreamError 1
#define WinZipJPEGOutOfMemoryError 2
#define WinZipJPEGInvalidHeaderError 3
#define WinZipJPEGLZMAError 4
#define WinZipJPEGParseError 5

typedef struct WinZipJPEGDecompressor
{
	WinZipJPEGReadFunction *readfunc;
	void *inputcontext;

	uint32_t metadatalength;
	uint8_t *metadatabytes;

	bool isfirstbundle,reachedend;
	WinZipJPEGMetadata jpeg;

	bool slicesavailable;
	unsigned int slicevalue,sliceheight;
	unsigned int currheight,finishedrows;

	int predicted[4];

	uint64_t bitstring;
	unsigned int bitlength;
	bool needsstuffing;

	WinZipJPEGArithmeticDecoder decoder;

	WinZipJPEGContext eobbins[4][13][63]; // 321 in WinZip.
	WinZipJPEGContext zerobins[4][62][3][6]; // 1140 in WinZip.
	WinZipJPEGContext pivotbins[4][63][5][7]; // 2256 in WinZip.
	WinZipJPEGContext acmagnitudebins[4][3][9][9][9];
	WinZipJPEGContext acremainderbins[4][3][7][13];
	WinZipJPEGContext acsignbins[4][27][3][2];
	WinZipJPEGContext dcmagnitudebins[4][13][10]; // 1 in WinZip.
	WinZipJPEGContext dcremainderbins[4][13][14]; // 131 in WinZip.
	WinZipJPEGContext dcsignbins[4][2][2][2]; // 313 in WinZip.
	WinZipJPEGContext fixedcontext; // 0 in WinZip.

	WinZipJPEGBlock *blocks[4];

	WinZipJPEGBlock *currblock;
	bool mcusavailable;
	unsigned int mcurow,mcucol,mcucomp,mcux,mcuy,mcucoeff;
	unsigned int mcucounter,restartmarkerindex;
	bool writerestartmarker;
} WinZipJPEGDecompressor;

WinZipJPEGDecompressor *AllocWinZipJPEGDecompressor(WinZipJPEGReadFunction *readfunc,void *inputcontext);
void FreeWinZipJPEGDecompressor(WinZipJPEGDecompressor *self);

int ReadWinZipJPEGHeader(WinZipJPEGDecompressor *self);
int ReadNextWinZipJPEGBundle(WinZipJPEGDecompressor *self);
int ReadNextWinZipJPEGSlice(WinZipJPEGDecompressor *self);

size_t EncodeWinZipJPEGBlocksToBuffer(WinZipJPEGDecompressor *self,void *bytes,size_t length);

static inline bool IsFinalWinZipJPEGBundle(WinZipJPEGDecompressor *self)
{ return self->reachedend; }
static inline bool AreMoreWinZipJPEGSlicesAvailable(WinZipJPEGDecompressor *self)
{ return !self->reachedend && self->slicesavailable; }
static inline bool AreMoreWinZipJPEGBytesAvailable(WinZipJPEGDecompressor *self)
{ return self->mcusavailable || self->bitlength>=8 || self->needsstuffing || self->writerestartmarker; }

static inline uint32_t WinZipJPEGBundleMetadataLength(WinZipJPEGDecompressor *self) { return self->metadatalength; }
static inline uint8_t *WinZipJPEGBundleMetadataBytes(WinZipJPEGDecompressor *self) { return self->metadatabytes; }

#endif

