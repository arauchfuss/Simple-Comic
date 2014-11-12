#import <Foundation/Foundation.h>

typedef NS_ENUM(int, XADError) {
	XADNoError =			0x0000, /* no error */
	XADUnknownError =		0x0001, /* unknown error */
	XADInputError =			0x0002, /* input data buffers border exceeded */
	XADOutputError =		0x0003, /* failed to write to file */
	XADBadParametersError =	0x0004, /* function called with illegal parameters */
	XADOutOfMemoryError =	0x0005, /* not enough memory available */
	XADIllegalDataError =	0x0006, /* data is corrupted */
	XADNotSupportedError =	0x0007, /* file not fully supported */
	XADResourceError =		0x0008, /* required resource missing */
	XADDecrunchError =		0x0009, /* error on decrunching */
	XADFiletypeError =		0x000A, /* unknown file type */
	XADOpenFileError =		0x000B, /* opening file failed */
	XADSkipError =			0x000C, /* file, disk has been skipped */
	XADBreakError =			0x000D, /* user break in progress hook */
	XADFileExistsError =	0x000E, /* file already exists */
	XADPasswordError =		0x000F, /* missing or wrong password */
	XADMakeDirectoryError =	0x0010, /* could not create directory */
	XADChecksumError =		0x0011, /* wrong checksum */
	XADVerifyError =		0x0012, /* verify failed (disk hook) */
	XADGeometryError =		0x0013, /* wrong drive geometry */
	XADDataFormatError =	0x0014, /* unknown data format */
	XADEmptyError =			0x0015, /* source contains no files */
	XADFileSystemError =	0x0016, /* unknown filesystem */
	XADFileDirectoryError =	0x0017, /* name of file exists as directory */
	XADShortBufferError =	0x0018, /* buffer was too short */
	XADEncodingError =		0x0019, /* text encoding was defective */
	XADLinkError =			0x001a, /* could not create link */

	XADSubArchiveError = 0x10000
};

#ifndef CLANG_ANALYZER_NORETURN
	#ifdef __clang__
		#if __has_feature(attribute_analyzer_noreturn)
			#define CLANG_ANALYZER_NORETURN __attribute__((analyzer_noreturn))
		#else
			#define CLANG_ANALYZER_NORETURN
		#endif
	#else
		#define CLANG_ANALYZER_NORETURN
	#endif
#endif

extern NSString *XADExceptionName;

@interface XADException:NSObject
{
}

+(void)raiseUnknownException CLANG_ANALYZER_NORETURN;
+(void)raiseInputException CLANG_ANALYZER_NORETURN;
+(void)raiseOutputException CLANG_ANALYZER_NORETURN;
+(void)raiseIllegalDataException CLANG_ANALYZER_NORETURN;
+(void)raiseNotSupportedException CLANG_ANALYZER_NORETURN;
+(void)raiseDecrunchException CLANG_ANALYZER_NORETURN;
+(void)raisePasswordException CLANG_ANALYZER_NORETURN;
+(void)raiseChecksumException CLANG_ANALYZER_NORETURN;
+(void)raiseDataFormatException CLANG_ANALYZER_NORETURN;
+(void)raiseOutOfMemoryException CLANG_ANALYZER_NORETURN;
+(void)raiseExceptionWithXADError:(XADError)errnum CLANG_ANALYZER_NORETURN;

+(XADError)parseException:(id)exception;
+(NSString *)describeXADError:(XADError)errnum;

@end
