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
//	NSLog(@"base path %@",archivePath);
	NSData * imageData = nil;
	NSString * coverName = [UKXattrMetadataStore stringForKey: @"QCCoverName" atPath: archivePath traverseLink: NO];
//	NSLog(@"page name %@",coverName);
	NSString * coverRectString = [UKXattrMetadataStore stringForKey: @"QCCoverRect" atPath: archivePath traverseLink: NO];
//	NSLog(@"rect %@",coverRectString);
	CGRect cropRect = CGRectZero;
	int coverIndex;
	if(![coverName isEqualToString: @""])
	{
//		NSLog(@"has name");
		DTPartialArchiveParser * partialArchive = [[DTPartialArchiveParser alloc] initWithPath: archivePath searchString: coverName];
		if(![coverRectString isEqualToString: @""])
		{
			cropRect = NSRectToCGRect(NSRectFromString(coverRectString));
		}
		imageData = [[partialArchive searchResult] retain];
		[partialArchive release];
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
//		NSLog(@"has data");
		CGImageSourceRef pageSourceRef = CGImageSourceCreateWithData( (CFDataRef)imageData,  NULL);
        CGImageRef currentImage = CGImageSourceCreateImageAtIndex(pageSourceRef, 0, NULL);
        CFRelease(pageSourceRef);
		CGRect canvasRect;
		CGRect drawRect;
        if(CGRectEqualToRect(cropRect, CGRectZero))
		{
//			NSLog(@"no crop");
			canvasRect.size = fitSizeInSize(maxSize, CGSizeMake( CGImageGetWidth(currentImage), CGImageGetHeight(currentImage)));
			canvasRect.origin = CGPointZero;
			drawRect = canvasRect;
		}
		else
		{
//			NSLog(@"crop");
			canvasRect.size = fitSizeInSize(maxSize, cropRect.size);
			float vertScale = canvasRect.size.height / CGImageGetHeight(currentImage);
			float horScale = canvasRect.size.width / CGImageGetWidth(currentImage);
			drawRect.origin = CGPointMake(-(cropRect.origin.x), -(cropRect.origin.y));
			drawRect.size = CGSizeMake(cropRect.size.width / horScale, cropRect.size.height / vertScale);
		}
		
        CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, canvasRect.size, false, NULL);
        if(cgContext)
        {
//			NSLog(@"draw");
            CGContextDrawImage(cgContext, drawRect, currentImage);
        }

//		NSLog(@"release");
        CFRelease(currentImage);
        QLThumbnailRequestFlushContext(thumbnail, cgContext);
        CFRelease(cgContext);
		[imageData release];
	}
	
	
    [pool release];
    return noErr;
}


void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}


