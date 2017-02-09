#import "CSMemoryHandle.h"
#import "CSInputBuffer.h"

typedef int8_t xadINT8;
typedef int16_t xadINT16;
typedef int32_t xadINT32;
typedef uint8_t xadUINT8;
typedef uint16_t xadUINT16;
typedef uint32_t xadUINT32;

typedef int64_t xadSignedSize;
typedef uint64_t xadSize;

typedef int xadERROR;
typedef char xadSTRING;
typedef xadSTRING *xadSTRPTR;
typedef void *xadPTR;

typedef xadUINT32 xadTag;

struct TagItem {
	xadTag  ti_Tag;
	xadSize ti_Data;
};

typedef const struct TagItem *xadTAGPTR;

#define XIDBUFSIZE 10240


struct xadArchiveInfo {}; // dummy definitions
struct xadMasterBase {};

struct xadInOut {
  struct xadArchiveInfo * xio_ArchiveInfo;   /* filled by xadIOAlloc */
  struct xadMasterBase *  xio_xadMasterBase; /* filled by xadIOAlloc */
  xadERROR                xio_Error;         /* cleared */
  xadUINT32               xio_Flags;         /* filled by xadIOAlloc, functions or user */

  /* xio_GetFunc and xio_PutFunc are filled by xadIOAlloc or user */
  xadUINT8 (*xio_GetFunc)(struct xadInOut *);
  xadPTR                  xio_GetFuncPrivate;
  xadUINT8 (*xio_PutFunc)(struct xadInOut *, xadUINT8);
  xadPTR                  xio_PutFuncPrivate;

  void (*xio_InFunc)(struct xadInOut *, xadUINT32);
  xadPTR                  xio_InFuncPrivate;
  xadSize                 xio_InSize;
  xadSize                 xio_InBufferSize;
  xadSize                 xio_InBufferPos;
  xadUINT8 *              xio_InBuffer;
  xadUINT32               xio_BitBuf;        /* for xadIOGetBits functions */
  xadUINT16               xio_BitNum;        /* for xadIOGetBits functions */

  xadUINT16               xio_CRC16;         /* crc16 from output functions */
  xadUINT32               xio_CRC32;         /* crc32 from output functions */

  void (*xio_OutFunc)(struct xadInOut *, xadUINT32);
  xadPTR                  xio_OutFuncPrivate;
  xadSize                 xio_OutSize;
  xadSize                 xio_OutBufferSize;
  xadSize                 xio_OutBufferPos;
  xadUINT8 *              xio_OutBuffer;

  /* These 3 can be reused. Algorithms should be prepared to find this
     initialized! The window, alloc always has to use xadAllocVec. */
  xadSize                 xio_WindowSize;
  xadSize                 xio_WindowPos;
  xadUINT8 *              xio_Window;

  /* If the algorithms need to remember additional data for next run, this
     should be passed as argument structure of type (void **) and allocated
     by the algorithms themself using xadAllocVec(). */

	// Extra fields for use by the xadIO emulation
	CSHandle *inputhandle;
	NSMutableData *outputdata;
};

/* setting BufferPos to buffer size activates first time read! */

#define XADIOF_ALLOCINBUFFER    (1<<0)  /* allocate input buffer */
#define XADIOF_ALLOCOUTBUFFER   (1<<1)  /* allocate output buffer */
#define XADIOF_NOINENDERR       (1<<2)  /* xadIOGetChar does not produce err at buffer end */
#define XADIOF_NOOUTENDERR      (1<<3)  /* xadIOPutChar does not check out size */
#define XADIOF_LASTINBYTE       (1<<4)  /* last byte was read, set by xadIOGetChar */
#define XADIOF_LASTOUTBYTE      (1<<5)  /* output length was reached, set by xadIOPutChar */
#define XADIOF_ERROR            (1<<6)  /* an error occured */
#define XADIOF_NOCRC16          (1<<7)  /* calculate no CRC16 */
#define XADIOF_NOCRC32          (1<<8)  /* calculate no CRC32 */
#define XADIOF_COMPLETEOUTFUNC  (1<<9)  /* outfunc completely replaces write stuff */

/* allocates the xadInOut structure and the buffers */
struct xadInOut *xadIOAlloc(xadUINT32 flags,
struct xadArchiveInfo *ai, struct xadMasterBase *xadMasterBase);

/* writes the buffer out */
xadERROR xadIOWriteBuf(struct xadInOut *io);

#define xadIOGetChar(io)   (*((io)->xio_GetFunc))((io))      /* reads one byte */
#define xadIOPutChar(io,a) (*((io)->xio_PutFunc))((io), (a)) /* stores one byte */

/* This skips any left bits and rounds up the whole to next byte boundary. */
/* Sometimes needed for block-based algorithms, where there blocks are byte aligned. */
#define xadIOByteBoundary(io) ((io)->xio_BitNum = 0)

/* The read bits function only read the bits without flushing from buffer. This is
done by DropBits. Some compressors need this method, as the flush different amount
of data than they read in. Normally the GetBits functions are used.
When including the source file directly, do not forget to set the correct defines
to include the necessary functions. */

/* new bytes inserted from left, get bits from right end, max 32 bits, no checks */
xadUINT32 xadIOGetBitsLow(struct xadInOut *io, xadUINT8 bits);
/* new bytes inserted from left, get bits from right end, max 32 bits, no checks, bits reversed */
xadUINT32 xadIOGetBitsLowR(struct xadInOut *io, xadUINT8 bits);

xadUINT32 xadIOReadBitsLow(struct xadInOut *io, xadUINT8 bits);
void xadIODropBitsLow(struct xadInOut *io, xadUINT8 bits);

/* new bytes inserted from right, get bits from left end, max 32 bits, no checks */
xadUINT32 xadIOGetBitsHigh(struct xadInOut *io, xadUINT8 bits);

xadUINT32 xadIOReadBitsHigh(struct xadInOut *io, xadUINT8 bits);
void xadIODropBitsHigh(struct xadInOut *io, xadUINT8 bits);




@interface XADLibXADIOHandle:CSMemoryHandle
{
	CSHandle *parent;
	BOOL unpacked;

	off_t inlen,outlen;
	uint8_t inbuf[XIDBUFSIZE],outbuf[XIDBUFSIZE];
	struct xadInOut iostruct;
}

-(id)initWithHandle:(CSHandle *)handle;
-(id)initWithHandle:(CSHandle *)handle length:(off_t)outlength;
-(void)dealloc;

-(off_t)fileSize;
-(off_t)offsetInFile;
-(BOOL)atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
//-(void)pushBackByte:(int)byte;
-(int)readAtMost:(int)num toBuffer:(void *)buffer;
-(void)writeBytes:(int)num fromBuffer:(const void *)buffer;

-(NSData *)fileContents;
-(NSData *)remainingFileContents;
-(NSData *)readDataOfLength:(int)length;
-(NSData *)readDataOfLengthAtMost:(int)length;
-(NSData *)copyDataOfLength:(int)length;
-(NSData *)copyDataOfLengthAtMost:(int)length;

-(void)runUnpacker;
-(struct xadInOut *)ioStructWithFlags:(xadUINT32)flags;
-(xadINT32)unpackData;

@end




#define XADERR_OK               0x0000 /* no error */
#define XADERR_UNKNOWN          0x0001 /* unknown error */
#define XADERR_INPUT            0x0002 /* input data buffers border exceeded */
#define XADERR_OUTPUT           0x0003 /* output data buffers border exceeded */
#define XADERR_BADPARAMS        0x0004 /* function called with illegal parameters */
#define XADERR_NOMEMORY         0x0005 /* not enough memory available */
#define XADERR_ILLEGALDATA      0x0006 /* data is corrupted */
#define XADERR_NOTSUPPORTED     0x0007 /* command is not supported */
#define XADERR_RESOURCE         0x0008 /* required resource missing */
#define XADERR_DECRUNCH         0x0009 /* error on decrunching */
#define XADERR_FILETYPE         0x000A /* unknown file type */
#define XADERR_OPENFILE         0x000B /* opening file failed */
#define XADERR_SKIP             0x000C /* file, disk has been skipped */
#define XADERR_BREAK            0x000D /* user break in progress hook */
#define XADERR_FILEEXISTS       0x000E /* file already exists */
#define XADERR_PASSWORD         0x000F /* missing or wrong password */
#define XADERR_MAKEDIR          0x0010 /* could not create directory */
#define XADERR_CHECKSUM         0x0011 /* wrong checksum */
#define XADERR_VERIFY           0x0012 /* verify failed (disk hook) */
#define XADERR_GEOMETRY         0x0013 /* wrong drive geometry */
#define XADERR_DATAFORMAT       0x0014 /* unknown data format */
#define XADERR_EMPTY            0x0015 /* source contains no files */
#define XADERR_FILESYSTEM       0x0016 /* unknown filesystem */
#define XADERR_FILEDIR          0x0017 /* name of file exists as directory */
#define XADERR_SHORTBUFFER      0x0018 /* buffer was too short */
#define XADERR_ENCODING         0x0019 /* text encoding was defective */

#define XADM
#define XADMEMF_ANY     (0)
#define XADMEMF_CLEAR   (1L << 16)
#define XADMEMF_PUBLIC  (1L << 0)

static inline xadPTR xadAllocVec(xadSize size, xadUINT32 flags) { return calloc(size,1); }
static inline void xadFreeObject(xadPTR object,xadTag tag, ...) { free(object); }
static inline void xadFreeObjectA(xadPTR object,xadTAGPTR tags) { free(object); }
static inline void xadCopyMem(const void *s,xadPTR d,xadSize size) { memmove(d,s,(size_t)size); }

