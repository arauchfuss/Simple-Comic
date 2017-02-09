#import "XADLibXADIOHandle.h"

// Implementation using the old xadIO code from libxad, emulated through XADLibXADIOHandle
// TODO: Re-implement these as cleaner code. Problem: no test cases.

@interface XADLZH2Handle:XADLibXADIOHandle {}
-(xadINT32)unpackData;
@end

@interface XADLZH3Handle:XADLibXADIOHandle {}
-(xadINT32)unpackData;
@end

@interface XADPMArc2Handle:XADLibXADIOHandle {}
-(xadINT32)unpackData;
@end
