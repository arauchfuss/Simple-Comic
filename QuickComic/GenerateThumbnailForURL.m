#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>
#include <XADMaster/XADArchive.h>
#import "DTQuickComicCommon.h"
#import "UKXattrMetadataStore.h"
#import "TSSTImageUtilities.h"
#import "DTPartialArchiveParser.h"


/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */
OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
	
	NSString * archivePath = [(NSURL *)url path];
	NSData * imageData = nil;
	NSString * coverName = [UKXattrMetadataStore stringForKey: @"QCCoverName" atPath: archivePath traverseLink: NO];
	NSString * coverRectString = [UKXattrMetadataStore stringForKey: @"QCCoverRect" atPath: archivePath traverseLink: NO];
	CGRect cropRect = CGRectZero;
	int coverIndex;
	if(![coverName isEqualToString: @""])
	{
		DTPartialArchiveParser * partialArchive = [[DTPartialArchiveParser alloc] initWithPath: archivePath searchString: coverName];
		imageData = [partialArchive searchResult];
		if(![coverRectString isEqualToString: @""])
		{
			cropRect = NSRectToCGRect(NSRectFromString(coverRectString));
		}
		[DTPartialArchiveParser release];
	}
	else
    {
		XADArchive * archive = [[XADArchive alloc] initWithFile: archivePath];
		NSMutableArray * fileList = fileListForArchive(archive);
		
		if([fileList count] > 0)
		{
			[fileList sortUsingDescriptors: fileSort()];
			coverName = [[fileList objectAtIndex: 0] valueForKey: @"rawName"];
			coverIndex = [[[fileList objectAtIndex: 0] valueForKey: @"index"] intValue];
			[UKXattrMetadataStore setString: coverName forKey: @"QCCoverName" atPath: archivePath traverseLink: NO];
			imageData = [archive contentsOfEntry: coverIndex];
		}
		[archive release];

    }

	if(imageData)
	{
//		NSImage * coverImage = [[NSImage alloc] initWithData: imageData];
		CGImageSourceRef pageSourceRef = CGImageSourceCreateWithData( (CFDataRef)imageData,  NULL);
        CGImageRef currentImage = CGImageSourceCreateImageAtIndex(pageSourceRef, 0, NULL);
        CFRelease(pageSourceRef);
		CGRect canvasRect;
		CGRect drawRect;
        if(CGRectEqualToRect(cropRect, CGRectZero))
		{
			canvasRect.size = fitSizeInSize(maxSize, CGSizeMake( CGImageGetWidth(currentImage), CGImageGetHeight(currentImage)));
			canvasRect.origin = CGPointZero;
			drawRect = canvasRect;
		}
		else
		{
			canvasRect.size = fitSizeInSize(maxSize, cropRect.size);
			float vertScale = canvasRect.size.height / CGImageGetHeight(currentImage);
			float horScale = canvasRect.size.width / CGImageGetWidth(currentImage);
			drawRect.origin = CGPointMake(-(cropRect.origin.x), -(cropRect.origin.y));
			drawRect.size = CGSizeMake(cropRect.size.width / horScale, cropRect.size.height / vertScale);
		}
        CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, canvasRect.size, false, NULL);
        if(cgContext)
        {
            CGContextDrawImage(cgContext, drawRect, currentImage);
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


