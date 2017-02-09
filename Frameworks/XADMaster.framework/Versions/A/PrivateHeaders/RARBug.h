#ifndef __RARBUG_H__
#define __RARBUG_H__

#include "../../Crypto/sha.h"

void SHA1_Update_WithRARBug(SHA_CTX *ctx,void *bytes,unsigned long length,int bug);

#endif
