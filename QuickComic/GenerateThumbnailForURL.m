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
	@autoreleasepool {
	
	NSString * archivePath = [(__bridge NSURL *)url path];
//	NSLog(@"base path %@",archivePath);
	NSData * imageData = nil;
	NSString * coverName = [UKXattrMetadataStore stringForKey: @"QCCoverName" atPath: archivePath traverseLink: NO error: nil] ?: @"";
//	NSLog(@"page name %@",coverName);
	NSString * coverRectString = [UKXattrMetadataStore stringForKey: @"QCCoverRect" atPath: archivePath traverseLink: NO error: nil] ?: @"";
//	NSLog(@"rect %@",coverRectString);
	CGRect cropRect = CGRectZero;
	NSInteger coverIndex;
	if(![coverName isEqualToString: @""])
	{
//		NSLog(@"has name");
		DTPartialArchiveParser * partialArchive = [[DTPartialArchiveParser alloc] initWithPath: archivePath searchString: coverName];
		if(![coverRectString isEqualToString: @""])
		{
			cropRect = NSRectToCGRect(NSRectFromString(coverRectString));
		}
		imageData = [partialArchive searchResult];
	}
	else
    {
		XADArchive * archive = [[XADArchive alloc] initWithFile: archivePath];
		NSMutableArray * fileList = fileListForArchive(archive);
		
		if([fileList count] > 0)
		{
			[fileList sortUsingDescriptors: fileSort()];
			coverName = [fileList.firstObject valueForKey: @"rawName"];
			coverIndex = [[fileList.firstObject valueForKey: @"index"] integerValue];
			[UKXattrMetadataStore setString: coverName forKey: @"QCCoverName" atPath: archivePath traverseLink: NO error: nil];
			imageData = [archive contentsOfEntry: coverIndex];
		}
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
		CGContextRelease(cgContext);
	}
	
	
	}
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
