#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import <XADMaster/XADArchive.h>
#import "DTQuickComicCommon.h"
#include "main.h"
#import <WebPMac/TSSTWebPImageRep.h>

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	@autoreleasepool {
		// TODO: implement kQLReturnHasMore somehow
		if (![NSImageRep imageRepClassForType:@"public.webp"]) {
			[NSImageRep registerImageRepClass:[TSSTWebPImageRep class]];
		}

		XADArchive * archive = [[XADArchive alloc] initWithFileURL: (__bridge NSURL *)url delegate: nil error: NULL];
		NSMutableArray<NSDictionary<NSString*,id>*> * fileList = fileListForArchive(archive);

		if (QLPreviewRequestIsCancelled(preview)) {
			return kQLReturnNoError;
		}

		if([fileList count] > 0)
		{
			[fileList sortUsingDescriptors: fileSort()];
			NSInteger index;
			CGImageSourceRef pageSourceRef;
			CGImageRef currentImage;
			CGRect canvasRect;
			// Preview will be drawn in a vectorized context
			CGContextRef cgContext = QLPreviewRequestCreatePDFContext(preview, NULL, NULL, NULL);
			if(cgContext)
			{
				NSInteger counter = 0;
				NSInteger count = [fileList count];
				//count = count < 20 ? count : 20;
				NSDate * pageRenderStartTime = [NSDate date];
				NSDate * currentTime = nil;
				do
				{
					index = [[fileList[counter] valueForKey: @"index"] integerValue];
					NSData *fileData = [archive contentsOfEntry: index];;
					pageSourceRef = CGImageSourceCreateWithData((CFDataRef)fileData, NULL);
					if (!pageSourceRef) {
						// If CoreGraphics failed, use NSImage
						NSImage *img = [[NSImage alloc] initWithData:fileData];
						NSData *imgData = img.TIFFRepresentation;
						pageSourceRef = CGImageSourceCreateWithData((CFDataRef)imgData, NULL);
					}
					currentImage = CGImageSourceCreateImageAtIndex(pageSourceRef, 0, NULL);
					canvasRect = CGRectMake(0, 0, CGImageGetWidth(currentImage), CGImageGetHeight(currentImage));
					
					CGContextBeginPage(cgContext, &canvasRect);
					CGContextDrawImage(cgContext, canvasRect, currentImage);
					CGContextEndPage(cgContext);
					
					CFRelease(currentImage);
					CFRelease(pageSourceRef);
					currentTime = [NSDate date];
					counter ++;
					if (QLPreviewRequestIsCancelled(preview)) {
						CFRelease(cgContext);
						return kQLReturnNoError;
					}
				}while(1 > [currentTime timeIntervalSinceDate: pageRenderStartTime] && counter < count);
				
				QLPreviewRequestFlushContext(preview, cgContext);
				CFRelease(cgContext);
			}
		}
		return noErr;
	}
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
