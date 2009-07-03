#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>
#include <XADMaster/XADArchive.h>
#import "DTQuickComicCommon.h"
#import "UKXattrMetadataStore.h"
#import "TSSTImageUtilities.h"


/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */



OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
	
	NSString * archivePath = [(NSURL *)url path];
	XADArchive * archive = [[XADArchive alloc] initWithFile: archivePath];
	NSData * imageData = nil;
	NSData * coverIndexData = [UKXattrMetadataStore dataForKey: @"QCCoverIndex" atPath: archivePath traverseLink: NO];
	int coverIndex;
	
	if(coverIndexData)
	{
		coverIndex = [[NSUnarchiver unarchiveObjectWithData: coverIndexData] intValue];
		imageData = [archive contentsOfEntry: coverIndex];
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
	
	if(imageData)
	{
//		NSString * test = @"CBR";
		CGImageSourceRef pageSourceRef = CGImageSourceCreateWithData( (CFDataRef)imageData,  NULL);
        CGImageRef currentImage = CGImageSourceCreateImageAtIndex(pageSourceRef, 0, NULL);
        CFRelease(pageSourceRef);
        
		CGSize canvasSize = fitSizeInSize(maxSize, CGSizeMake( CGImageGetWidth(currentImage), CGImageGetHeight(currentImage)));
        CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, canvasSize, false, NULL);
		CGRect canvasRect = CGRectMake(0, 0, canvasSize.width, canvasSize.height);
//		NSLog(NSStringFromSize(NSSizeFromCGSize(canvasSize)));
        if(cgContext)
        {
            CGContextDrawImage(cgContext, canvasRect, currentImage);
        }
		
        NSGraphicsContext * context = [NSGraphicsContext graphicsContextWithGraphicsPort: cgContext flipped: NO];
		NSRect borderRect = NSRectFromCGRect(canvasRect);
		[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext: context];
//		[[NSColor colorWithCalibratedWhite: 1 alpha: 0.1] set];
//		NSRectFill(borderRect);
		NSAffineTransform * iconTransform = [NSAffineTransform transform];
		float scaleFactor = borderRect.size.height / 512;
		[iconTransform scaleBy: scaleFactor];
		[iconTransform concat];
		[[NSColor colorWithCalibratedWhite: 1 alpha: 0.6] set];
		[NSBezierPath setDefaultLineJoinStyle: NSRoundLineJoinStyle];
		[NSBezierPath setDefaultLineWidth: 4];
		borderRect.size.width /= scaleFactor;
		borderRect.size.height /= scaleFactor;
		[NSBezierPath strokeRect: borderRect];
		[NSGraphicsContext restoreGraphicsState];
		
//		NSRectFill(extensionRect);
//		[[NSColor blackColor] set];
//		NSDictionary * fontAttributes = [NSDictionary dictionaryWithObject: [NSFont systemFontOfSize: 14] forKey: NSFontAttributeName];
//		NSSize extensionBadgeSize = [test sizeWithAttributes: fontAttributes];
//		[badgeTransform scaleBy: scaleFactor];
//		float badgeXCoord = canvasSize.width / 2 - extensionBadgeSize.width / 2;
//		badgeXCoord /= scaleFactor;
//		NSLog(@"tw:%f", canvasSize.width);
//		NSLog(@"x:%f", badgeXCoord);
//		[test drawAtPoint: NSMakePoint(badgeXCoord, 0) withAttributes: fontAttributes];
        CFRelease(currentImage);
        QLThumbnailRequestFlushContext(thumbnail, cgContext);
        CFRelease(cgContext);
	}
	
	[archive release];
    [pool release];
    return noErr;
}


void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}


