
#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>
#include <XADMaster/XADArchive.h>
#import "DTQuickComicCommon.h"


/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
	NSString * archivePath = [(NSURL *)url path];
	
	XADArchive * archive = [[XADArchive alloc] initWithFile: archivePath];
    NSMutableArray * fileList = fileListForArchive(archive);

    if([fileList count] > 0)
    {
        [fileList sortUsingDescriptors: fileSort()];
        int index;
        CGImageSourceRef pageSourceRef;
        CGImageRef currentImage;
        CGRect canvasRect;
        // Preview will be drawn in a vectorized context
        CGContextRef cgContext = QLPreviewRequestCreatePDFContext(preview, NULL, NULL, NULL);
        if(cgContext)
        {
            int counter = 0;
            int count = [fileList count];
//            count = count < 20 ? count : 20;
			NSDate * pageRenderStartTime = [NSDate date];
			NSDate * currentTime = nil;
            do
            {
                index = [[[fileList objectAtIndex: counter] valueForKey: @"index"] intValue];
                pageSourceRef = CGImageSourceCreateWithData( (CFDataRef)[archive contentsOfEntry: index],  NULL);
                currentImage = CGImageSourceCreateImageAtIndex(pageSourceRef, 0, NULL);
                canvasRect = CGRectMake(0, 0, CGImageGetWidth(currentImage), CGImageGetHeight(currentImage));
				
                CGContextBeginPage(cgContext, &canvasRect);
                CGContextDrawImage(cgContext, canvasRect, currentImage);
                CGContextEndPage(cgContext);
				
                CFRelease(currentImage);
                CFRelease(pageSourceRef);
				currentTime = [NSDate date];
				counter ++;
            }while(1 > [currentTime timeIntervalSinceDate: pageRenderStartTime] && counter < count);
            
            QLPreviewRequestFlushContext(preview, cgContext);
            CFRelease(cgContext);
        }
    }
    [archive release];
    [pool release];
    return noErr;
}


void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}


