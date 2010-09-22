#import <Foundation/Foundation.h>
#import <sys/time.h>

#ifdef __MINGW32__
#include <windows.h>
#endif

@interface NSDate (XAD)

+(NSDate *)XADDateWithTimeIntervalSince1904:(NSTimeInterval)interval;
+(NSDate *)XADDateWithTimeIntervalSince1601:(NSTimeInterval)interval;
+(NSDate *)XADDateWithMSDOSDate:(uint16_t)date time:(uint16_t)time;
+(NSDate *)XADDateWithMSDOSDateTime:(uint32_t)msdos;
+(NSDate *)XADDateWithWindowsFileTime:(uint64_t)filetime;
+(NSDate *)XADDateWithWindowsFileTimeLow:(uint32_t)low high:(uint32_t)high;

#ifndef __MINGW32__
-(struct timeval)timevalStruct;
#endif

#ifdef __APPLE__
-(UTCDateTime)UTCDateTime;
#endif

#ifdef __MINGW32__
-(FILETIME)FILETIME;
#endif

@end
