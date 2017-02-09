#ifndef __WINZIP_JPEG_ARITHMETIC_DECODER_H__
#define __WINZIP_JPEG_ARITHMETIC_DECODER_H__

#include "InputStream.h"

#include <stdint.h>
#include <stdbool.h>

typedef struct WinZipJPEGArithmeticDecoder
{
	WinZipJPEGReadFunction *readfunc;
	void *inputcontext;

	bool eof;

	uint8_t currbyte,lastbyte;

	uint8_t kmin2; // LPS count for reduction of Q by 4
	uint8_t kmin1; // LPS count for reduction of Q by 2
	uint8_t kmin; // largest LSP[sic] count for smaller Q
	//uint8_t kavg; // expected average LPS count
	uint8_t kmax; // smallest LPS count for larger Q
	uint32_t x; // finite pricesion window on code stream
	int32_t lp; // minus log p --- used only for testing
	int32_t lr; // minus log of the range
	int32_t lrm; // maximum lr before change index
	int32_t lx; // decoder - log x
	uint32_t dx; // antilog of lr -- used only for testing
} WinZipJPEGArithmeticDecoder;

typedef struct WinZipJPEGContext
{
	int i;
	int32_t dlrm; // difference between lrm and lr
	uint8_t mps; // most probable symbol value - 0 or 1
	uint8_t k; // least probable symbol count
} WinZipJPEGContext;

void InitializeWinZipJPEGArithmeticDecoder(WinZipJPEGArithmeticDecoder *self,WinZipJPEGReadFunction *readfunc, void *inputcontext);
void InitializeWinZipJPEGContext(WinZipJPEGContext *self);
void InitializeWinZipJPEGContexts(WinZipJPEGContext *first,size_t bytes);
void InitializeFixedWinZipJPEGContext(WinZipJPEGContext *self);

int NextBitFromWinZipJPEGArithmeticDecoder(WinZipJPEGArithmeticDecoder *self,WinZipJPEGContext *context);

void FlushWinZipJPEGArithmeticDecoder(WinZipJPEGArithmeticDecoder *self);

static inline bool WinZipJPEGArithmeticDecoderEncounteredEOF(WinZipJPEGArithmeticDecoder *self) { return self->eof; }

#endif

