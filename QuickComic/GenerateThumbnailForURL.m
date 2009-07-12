#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>
#include <XADMaster/XADArchive.h>
#import "DTQuickComicCommon.h"
#import "UKXattrMetadataStore.h"
#import "TSSTImageUtilities.h"
//#import "DTPartialArchiveParser.h"


/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */
OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
	
	NSString * archivePath = [(NSURL *)url path];
	NSData * imageData = nil;
	NSData * coverIndexData = [UKXattrMetadataStore dataForKey: @"QCCoverIndex" atPath: archivePath traverseLink: NO];
	int coverIndex;
	XADArchive * archive = [[XADArchive alloc] initWithFile: archivePath];
	if(coverIndexData)
	{
		coverIndex = [[NSUnarchiver unarchiveObjectWithData: coverIndexData] intValue];
		imageData = [archive contentsOfEntry: coverIndex];
//		DTPartialArchiveParser * partialArchive = [[DTPartialArchiveParser alloc] initWithPath: archivePath searchIndex: coverIndex];
//		imageData = [partialArchive searchResult];
//		[DTPartialArchiveParser release];
	}
	else
    {
		NSMutableArray * fileList = fileListForArchive(archive);
		if([fileList count] > 0)
		{
			[fileList sortUsingDescriptors: fileSort()];
			coverIndex = [[[fileList objectAtIndex: 0] valueForKey: @"index"] intValue];
			coverIndexData = [NSArchiver archivedDataWithRootObject: [NSNumber numberWithInt: coverIndex]];
			[UKXattrMetadataStore setData: coverIndexData forKey: @"QCCoverIndex" atPath: archivePath traverseLink: NO];
			
			imageData = [archive contentsOfEntry: coverIndex];
		}
    }
	[archive release];

	if(imageData)
	{
		CGImageSourceRef pageSourceRef = CGImageSourceCreateWithData( (CFDataRef)imageData,  NULL);
        CGImageRef currentImage = CGImageSourceCreateImageAtIndex(pageSourceRef, 0, NULL);
        CFRelease(pageSourceRef);
        
		CGSize canvasSize = fitSizeInSize(maxSize, CGSizeMake( CGImageGetWidth(currentImage), CGImageGetHeight(currentImage)));
        CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, canvasSize, false, NULL);
		CGRect canvasRect = CGRectMake(0, 0, canvasSize.width, canvasSize.height);
        if(cgContext)
        {
            CGContextDrawImage(cgContext, canvasRect, currentImage);
        }

        CFRelease(currentImage);
        QLThumbnailRequestFlushContext(thumbnail, cgContext);
        CFRelease(cgContext);
	}
	
    [pool release];
    return noErr;
}


void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}


