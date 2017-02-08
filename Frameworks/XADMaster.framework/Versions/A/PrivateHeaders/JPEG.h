#ifndef __WINZIP_JPEG_JPEG_H__
#define __WINZIP_JPEG_JPEG_H__

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>

#define WinZipJPEGMetadataFoundStartOfScan 1
#define WinZipJPEGMetadataFoundEndOfImage 2
#define WinZipJPEGMetadataParsingFailed 3

typedef struct WinZipJPEGBlock
{
	int16_t c[64];
	uint8_t eob;
} WinZipJPEGBlock;

typedef struct WinZipJPEGQuantizationTable
{
	int16_t c[64];
} WinZipJPEGQuantizationTable;

typedef struct WinZipJPEGHuffmanCode
{
	unsigned int code,length;
} WinZipJPEGHuffmanCode;

typedef struct WinZipJPEGHuffmanTable
{
	WinZipJPEGHuffmanCode codes[256];
} WinZipJPEGHuffmanTable;

typedef struct WinZipJPEGComponent
{
	unsigned int identifier;
	unsigned int horizontalfactor,verticalfactor;
	WinZipJPEGQuantizationTable *quantizationtable;
} WinZipJPEGComponent;

typedef struct WinZipJPEGScanComponent
{
	WinZipJPEGComponent *component;
	WinZipJPEGHuffmanTable *dctable,*actable;
} WinZipJPEGScanComponent;

typedef struct WinZipJPEGMetadata
{
	unsigned int width,height,bits;
	unsigned int restartinterval;

	unsigned int maxhorizontalfactor,maxverticalfactor;
	unsigned int horizontalmcus,verticalmcus;

	unsigned int numcomponents;
	WinZipJPEGComponent components[4];

	unsigned int numscancomponents;
	WinZipJPEGScanComponent scancomponents[4];

	WinZipJPEGQuantizationTable quantizationtables[4];
	WinZipJPEGHuffmanTable huffmantables[2][4];
} WinZipJPEGMetadata;

const void *FindStartOfWinZipJPEGImage(const void *bytes,size_t length);

void InitializeWinZipJPEGMetadata(WinZipJPEGMetadata *self);
int ParseWinZipJPEGMetadata(WinZipJPEGMetadata *self,const void *bytes,size_t length);

#endif
