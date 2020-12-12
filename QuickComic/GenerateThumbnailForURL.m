#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import <XADMaster/XADArchive.h>
#import "DTQuickComicCommon.h"
#import "UKXattrMetadataStore.h"
#import "TSSTImageUtilities.h"
#import "DTPartialArchiveParser.h"
#include "main.h"
#import <WebPMac/TSSTWebPImageRep.h>

#ifdef NON_APPSTORE
extern const CFStringRef kQLThumbnailPropertyIconFlavorKey;

typedef NS_ENUM(NSInteger, QLThumbnailIconFlavor)
{
	kQLThumbnailIconShadowFlavor = 1,
};
#endif

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	@autoreleasepool {
		if (![NSImageRep imageRepClassForType:@"org.webmproject.webp"]) {
			[NSImageRep registerImageRepClass:[TSSTWebPImageRep class]];
		}
		NSURL *archiveURL = (__bridge NSURL *)url;
		NSString * archivePath = [archiveURL path];
//	NSLog(@"base path %@",archivePath);
		NSData * imageData = nil;
		NSString * coverName = [UKXattrMetadataStore stringForKey: SCQuickLookCoverName atPath: archivePath traverseLink: NO error: nil] ?: @"";
//	NSLog(@"page name %@",coverName);
		NSString * coverRectString = [UKXattrMetadataStore stringForKey: SCQuickLookCoverRect atPath: archivePath traverseLink: NO error: nil] ?: @"";
//	NSLog(@"rect %@",coverRectString);
		CGRect cropRect = CGRectZero;
		NSInteger coverIndex;
		if(![coverName isEqualToString: @""])
		{
//		NSLog(@"has name");
			DTPartialArchiveParser * partialArchive = [[DTPartialArchiveParser alloc] initWithURL: archiveURL searchString: coverName];
			if(![coverRectString isEqualToString: @""])
			{
				cropRect = NSRectToCGRect(NSRectFromString(coverRectString));
			}
			imageData = [partialArchive searchResult];
		}
		else
		{
			XADArchive * archive = [[XADArchive alloc] initWithFileURL: archiveURL delegate: nil error: NULL];
			NSMutableArray * fileList = fileListForArchive(archive);
			
			if([fileList count] > 0)
			{
				[fileList sortUsingDescriptors: fileSort()];
				coverName = [fileList.firstObject valueForKey: @"rawName"];
				coverIndex = [[fileList.firstObject valueForKey: @"index"] integerValue];
				[UKXattrMetadataStore setString: coverName forKey: SCQuickLookCoverName atPath: archivePath traverseLink: NO error: nil];
				imageData = [archive contentsOfEntry: coverIndex];
			}
		}
	
		if (QLThumbnailRequestIsCancelled(thumbnail)) {
			return kQLReturnNoError;
		}
		
		if(imageData)
		{
//		NSLog(@"has data");
			CGImageSourceRef pageSourceRef = CGImageSourceCreateWithData( (CFDataRef)imageData,  NULL);
			if (!pageSourceRef) {
				// If CoreGraphics failed, use NSImage
				NSImage *img = [[NSImage alloc] initWithData:imageData];
				NSData *imgData = img.TIFFRepresentation;
				pageSourceRef = CGImageSourceCreateWithData((CFDataRef)imgData, NULL);
			}
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
				CGFloat vertScale = canvasRect.size.height / CGImageGetHeight(currentImage);
				CGFloat horScale = canvasRect.size.width / CGImageGetWidth(currentImage);
				drawRect.origin = CGPointMake(-(cropRect.origin.x), -(cropRect.origin.y));
				drawRect.size = CGSizeMake(cropRect.size.width / horScale, cropRect.size.height / vertScale);
			}
			
			if (QLThumbnailRequestIsCancelled(thumbnail)) {
				CFRelease(currentImage);
				return kQLReturnNoError;
			}
			
#ifdef NON_APPSTORE
			NSDictionary *properties = @{(__bridge NSString *)kQLThumbnailPropertyIconFlavorKey: @(kQLThumbnailIconShadowFlavor)};
#else
			NSDictionary *properties = @{};
#endif
			CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, canvasRect.size, false, (__bridge CFDictionaryRef)(properties));
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
