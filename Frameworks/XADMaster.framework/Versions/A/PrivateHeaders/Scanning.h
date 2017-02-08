#import "CSHandle.h"

typedef int (*CSByteMatchingFunctionPointer)(const uint8_t *bytes,int available,off_t offset,void *state);

@interface CSHandle (Scanning)

-(BOOL)scanForByteString:(uint8_t *)bytes length:(int)length;
-(int)scanUsingMatchingFunction:(CSByteMatchingFunctionPointer)function
maximumLength:(int)maximumlength;
-(int)scanUsingMatchingFunction:(CSByteMatchingFunctionPointer)function
maximumLength:(int)maximumlength context:(void *)contextptr;

@end
