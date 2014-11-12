#import <Foundation/Foundation.h>

#import "XADSWFGeometry.h"

#import "CSHandle.h"

#define SWFEndTag 0
#define SWFShowFrameTag 1
#define SWFDefineShapeTag 2
#define SWFPlaceObjectTag 4
#define SWFRemoveObjectTag 5
#define SWFDefineBitsJPEGTag 6
#define SWFJPEGTables 8
#define SWFDefineTextTag 11
#define SWFDefineFontInfoTag 13
#define SWFDefineSoundTag 14
#define SWFSoundStreamHeadTag 18
#define SWFSoundStreamBlockTag 19
#define SWFDefineBitsLosslessTag 20
#define SWFDefineBitsJPEG2Tag 21
#define SWFPlaceObject2Tag 26
#define SWFRemoveObject2Tag 28
#define SWFDefineText2Tag 33
#define SWFDefineBitsJPEG3Tag 35
#define SWFDefineBitsLossless2Tag 36
#define SWFDefineSpriteTag 39
#define SWFSoundStreamHead2Tag 45
#define SWFDefineFont2Tag 48
#define SWFPlaceObject3Tag 70
#define SWFDefineFont3Tag 75
#define SWFDefineBitsJPEG4Tag 90

extern NSString *SWFWrongMagicException;
extern NSString *SWFNoMoreTagsException;

@interface XADSWFTagParser:NSObject
{
	CSHandle *fh;
	off_t nexttag,nextsubtag;

	int totallen,version;
	BOOL compressed;
	SWFRect rect;
	int frames,fps;

	int currtag,currlen;
	int currframe;

	int spriteid,subframes;
	int subtag,sublen;
	int subframe;
}

+(XADSWFTagParser *)parserWithHandle:(CSHandle *)handle;
+(XADSWFTagParser *)parserForPath:(NSString *)path;

-(instancetype)initWithHandle:(CSHandle *)handle NS_DESIGNATED_INITIALIZER;
-(void)dealloc;

-(void)parseHeader;

@property (NS_NONATOMIC_IOSONLY, readonly) int version;
@property (NS_NONATOMIC_IOSONLY, getter=isCompressed, readonly) BOOL compressed;
@property (NS_NONATOMIC_IOSONLY, readonly) SWFRect rect;
@property (NS_NONATOMIC_IOSONLY, readonly) int frames;
@property (NS_NONATOMIC_IOSONLY, readonly) int framesPerSecond;

@property (NS_NONATOMIC_IOSONLY, readonly) int nextTag;

@property (NS_NONATOMIC_IOSONLY, readonly) int tag;
@property (NS_NONATOMIC_IOSONLY, readonly) int tagLength;
@property (NS_NONATOMIC_IOSONLY, readonly) int tagBytesLeft;
@property (NS_NONATOMIC_IOSONLY, readonly) int frame;
@property (NS_NONATOMIC_IOSONLY, readonly) double time;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADHandle *handle;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADHandle *tagHandle;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *tagContents;

-(void)parseDefineSpriteTag;

@property (NS_NONATOMIC_IOSONLY, readonly) int spriteID;
@property (NS_NONATOMIC_IOSONLY, readonly) int subFrames;

@property (NS_NONATOMIC_IOSONLY, readonly) int nextSubTag;
@property (NS_NONATOMIC_IOSONLY, readonly) int subTag;
@property (NS_NONATOMIC_IOSONLY, readonly) int subTagLength;
@property (NS_NONATOMIC_IOSONLY, readonly) int subTagBytesLeft;
@property (NS_NONATOMIC_IOSONLY, readonly) int subFrame;
@property (NS_NONATOMIC_IOSONLY, readonly) double subTime;

@end
