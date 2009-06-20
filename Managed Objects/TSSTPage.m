/*	
Copyright (c) 2007 Dancing Tortoise Software
 
	Permission is hereby granted, free of charge, to any person 
	obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without 
	restriction, including without limitation the rights to use, 
	copy, modify, merge, publish, distribute, sublicense, and/or 
	sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following 
	conditions:
 
	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.
 
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
	OTHER DEALINGS IN THE SOFTWARE.
 
    TSSTPage.m
 */



#import "TSSTPage.h"
#import <UniversalDetector/UniversalDetector.h>
#import "SimpleComicAppDelegate.h"
#import "TSSTImageUtilities.h"
#import "TSSTManagedGroup.h"
#import <XADMaster/XADArchive.h>
//#import <QuickTime/ImageCompression.h>
//#import <QuickTime/Movies.h>
//#import <QuickTime/QuickTimeComponents.h>


static NSMutableArray * TSSTComicImageTypes = nil;
static NSArray * TSSTComicTextTypes = nil;

@implementation TSSTPage

+ (NSArray *)imageExtensions
{
	if(!TSSTComicImageTypes)
	{
		TSSTComicImageTypes = [NSMutableArray arrayWithArray: [NSImage imageFileTypes]];
		[TSSTComicImageTypes removeObject: @"pdf"];
		[TSSTComicImageTypes removeObject: @"eps"];
		[TSSTComicImageTypes retain];
	}
	
	return TSSTComicImageTypes;
}

+ (NSArray *)textExtensions
{
	if(!TSSTComicTextTypes)
	{
		TSSTComicTextTypes = [[NSArray arrayWithObjects: @"txt", @"nfo", @"info", nil] retain];
	}
	
	return TSSTComicTextTypes;
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    thumbLock = [NSLock new];
    loaderLock = [NSLock new];
}



- (void)awakeFromFetch
{
    [super awakeFromFetch];
    thumbLock = [NSLock new];
    loaderLock = [NSLock new];
}



- (void)didTurnIntoFault
{
    [loaderLock release];
    [thumbLock release];
}



- (BOOL)hasAllowedAspectRatio
{   
	if([[self valueForKey: @"text"] boolValue])
	{
		return YES;
	}
	float defaultAspect = 1;
	float aspect = [[self valueForKey: @"aspectRatio"] floatValue];
	if(!aspect)
	{
        NSData * imageData = [self pageData];
		[self setOwnSizeInfoWithData: imageData];
		aspect = [[self valueForKey: @"aspectRatio"] floatValue];
	}
    
	return aspect != 0 ? aspect < defaultAspect : NO;
}


- (void)setOwnSizeInfoWithData:(NSData *)imageData
{
	float aspect;
//	GraphicsImportComponent quickTimeImporter = 0;
//	ImageDescriptionHandle imageParametersHandle = 0;
	NSSize imageSize;
//
//	if(imageData)
//	{
//		ComponentInstance dataHandler;
//		PointerDataRef dataref = (PointerDataRef)NewHandle(sizeof(PointerDataRefRecord));
//		(** dataref).data = (void *)[imageData bytes];
//		(** dataref).dataLength = [imageData length];
//		[loaderLock lock];
//		OpenADataHandler( (Handle)dataref, PointerDataHandlerSubType, NULL, (OSType)0, NULL, kDataHCanRead, &dataHandler);
//		GetGraphicsImporterForDataRef((Handle)dataref, PointerDataHandlerSubType, &quickTimeImporter);
//		GraphicsImportGetImageDescription(quickTimeImporter, &imageParametersHandle);
//		DisposeHandle((Handle)dataref);
//		[loaderLock unlock];
//	}
//	
//	if(imageParametersHandle)
//	{
//		imageSize = NSMakeSize((*imageParametersHandle)->width , (*imageParametersHandle)->height); 
//		CloseComponent(quickTimeImporter);
//		DisposeHandle((Handle)imageParametersHandle);
//	}
//	else
//	{
		NSBitmapImageRep * pageRep = [NSBitmapImageRep imageRepWithData: imageData];
		imageSize = NSMakeSize([pageRep pixelsWide], [pageRep pixelsHigh]);
//	}


	if(!NSEqualSizes(NSZeroSize, imageSize))
	{
		aspect = imageSize.width / imageSize.height;
		[self setValue: [NSNumber numberWithShort: imageSize.width] forKey: @"width"];
		[self setValue: [NSNumber numberWithShort: imageSize.height] forKey: @"height"];
		[self setValue: [NSNumber numberWithFloat: aspect] forKey: @"aspectRatio"];
	}	
}


- (NSString *)name
{
    return [[self valueForKey: @"imagePath"] lastPathComponent];
}


- (NSImage *)thumbnail
{
	NSImage * thumbnail = nil;
	NSData * thumbnailData = [self valueForKey: @"thumbnailData"];
	if(!thumbnailData)
	{
		thumbnailData = [self prepThumbnail];
		[self setValue: thumbnailData forKey: @"thumbnailData"];
		thumbnail = [[[NSImage alloc] initWithData: thumbnailData] autorelease];
	}
	else
	{
		thumbnail = [[[NSImage alloc] initWithData: thumbnailData] autorelease];
	}
	
    return thumbnail;
}


- (NSData *)prepThumbnail
{
	[thumbLock lock];
	NSImage * managedImage = [self pageImage];
	NSImage * thumbnail;
	NSSize pixelSize = [managedImage size];
	if(managedImage)
	{
		pixelSize = sizeConstrainedByDimension(pixelSize, 256);	
		NSImage * temp = [[NSImage alloc] initWithSize: pixelSize];
		[temp lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
		[managedImage drawInRect: NSMakeRect(0, 0, pixelSize.width, pixelSize.height) 
						fromRect: NSZeroRect 
					   operation: NSCompositeSourceOver 
						fraction: 1.0];
		[temp unlockFocus];
		thumbnail = temp;
	}
	[thumbLock unlock];
	
	return [[[thumbnail TIFFRepresentation] retain] autorelease];
}


- (NSImage *)pageImage
{
	if([[self valueForKey: @"text"] boolValue])
	{
		return [self textPage];
	}
	
    NSImage * imageFromData = nil;
    NSData * imageData = [self pageData];
	
    if(imageData)
    {
		[self setOwnSizeInfoWithData: imageData];
        imageFromData = [[NSImage alloc] initWithData: imageData];
    }
	
    NSSize imageSize =  NSMakeSize([[self valueForKey: @"width"] floatValue], [[self valueForKey: @"height"] floatValue]);
    
    if(!imageFromData || NSEqualSizes(NSZeroSize, imageSize))
    {
        imageFromData = nil;
    }
    else
    {
        [imageFromData setScalesWhenResized: YES];
        [imageFromData setCacheMode: NSImageCacheNever];
        
        [imageFromData setSize: imageSize];
        [imageFromData setCacheMode: NSImageCacheDefault];
    }
	
    return [imageFromData autorelease];
}


- (NSImage *)textPage
{
	NSImage * textImage = [[NSImage alloc] initWithSize: NSMakeSize(950, 1400)];
	NSData * textData = [[self valueForKeyPath: @"group"] dataForPageIndex: [[self valueForKey: @"index"] intValue]];
	UniversalDetector * encodingDetector = [UniversalDetector detector];
	[encodingDetector analyzeData: textData];
	NSString * text = [[NSString alloc] initWithData: textData encoding: [encodingDetector encoding]];
	[textImage lockFocus];
	[[NSColor whiteColor] set];
	NSRectFill(NSMakeRect(0, 0, 950, 1400));
	[text drawInRect: NSMakeRect(50, 50, 850, 1300)
	  withAttributes: [NSDictionary dictionaryWithObject:[NSFont fontWithName: @"Monaco" size: 18] forKey: NSFontAttributeName]];
	[textImage unlockFocus];
	[text release];
	
	return [textImage autorelease];
}


- (NSData *)pageData
{
	NSData * imageData = nil;
	TSSTManagedGroup * group = [self valueForKey: @"group"];
	if([self valueForKey: @"index"])
    {
		int entryIndex = [[self valueForKey: @"index"] intValue];
		imageData = [group dataForPageIndex: entryIndex];
	}
    else if([self valueForKey: @"imagePath"])
    {
        imageData = [NSData dataWithContentsOfFile: [self valueForKey: @"imagePath"]];
    }
    
	return [[imageData retain] autorelease];
}


@end

