#import <Foundation/Foundation.h>

@interface UniversalDetector:NSObject

+(UniversalDetector *)detector;
+(NSArray *)possibleMIMECharsets;

-(instancetype)init NS_DESIGNATED_INITIALIZER;

-(void)analyzeData:(NSData *)data;
-(void)analyzeBytes:(const char *)data length:(int)len;
-(void)reset;

@property (readonly, getter=isDone) BOOL done;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *MIMECharset;
@property (NS_NONATOMIC_IOSONLY, readonly) float confidence;

#ifdef __APPLE__
@property (NS_NONATOMIC_IOSONLY, readonly) NSStringEncoding encoding;
#endif

@end
