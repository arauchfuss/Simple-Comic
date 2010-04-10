#import <Foundation/Foundation.h>

@interface NSDate (XAD)

+(NSDate *)XADDateWithTimeIntervalSince1904:(NSTimeInterval)interval;
+(NSDate *)XADDateWithTimeIntervalSince1601:(NSTimeInterval)interval;
+(NSDate *)XADDateWithMSDOSDate:(uint16_t)date time:(uint16_t)time;
+(NSDate *)XADDateWithMSDOSDateTime:(uint32_t)msdos;
+(NSDate *)XADDateWithWindowsFileTime:(uint64_t)filetime;
+(NSDate *)XADDateWithWindowsFileTimeLow:(uint32_t)low high:(uint32_t)high;

@end
