#ifndef __WINZIP_JPEG_LZMA_H__
#define __WINZIP_JPEG_LZMA_H__

#if !__LP64__
#define _LZMA_UINT32_IS_ULONG
#endif

#define Byte LzmaByte
#include "../../Other/lzma/LzmaDec.h"
#undef Byte

#endif

