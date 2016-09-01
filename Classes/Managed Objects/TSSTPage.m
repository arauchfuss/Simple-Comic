/*	
Copyright (c) 2006-2009 Dancing Tortoise Software
 
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


static NSDictionary * TSSTInfoPageAttributes = nil;
static NSSize monospaceCharacterSize;

@implementation TSSTPage

+ (NSArray *)imageExtensions
{
	static NSArray * imageTypes = nil;
	if(!imageTypes)
	{
		NSMutableArray *aimageTypes = [[NSMutableArray alloc] initWithArray: [NSImage imageFileTypes]];
		//Get rid of OSTypes/File Types
		[aimageTypes filterUsingPredicate:[NSPredicate predicateWithFormat:@"!(SELF like %@)" argumentArray:@[@"'????'"]]];
		// Remove PDF and eps files
		[aimageTypes filterUsingPredicate:[NSPredicate predicateWithFormat:@"!(SELF like[c] %@)" argumentArray:@[@"pdf", @"eps"]]];
		imageTypes = [[NSArray alloc] initWithArray:aimageTypes];
	}
	
	return imageTypes;
}

+ (NSArray *)textExtensions
{
	static NSArray * textTypes = nil;

	if(!textTypes)
	{
		textTypes = @[@"txt", @"nfo", @"info"];
	}
	
	return textTypes;
}


+ (void)initialize
{
	/* Figure out the size of a single monospace character to set the tab stops */
	NSDictionary * fontAttributes = @{NSFontAttributeName: [NSFont fontWithName: @"Monaco" size: 14]};
	monospaceCharacterSize = [@"A" boundingRectWithSize: NSZeroSize options: 0 attributes: fontAttributes].size;
	
	NSTextTab * tabStop;
	NSMutableArray * tabStops = [NSMutableArray array];
	NSInteger tabSize;
	CGFloat tabLocation;
	/* Loop through the tab stops */
	for (tabSize = 8; tabSize < 120; tabSize+=8)
	{
		tabLocation = tabSize * monospaceCharacterSize.width;
		tabStop = [[NSTextTab alloc] initWithType: NSLeftTabStopType location: tabLocation];
		[tabStops addObject: tabStop];
	}
	
	NSMutableParagraphStyle * style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setTabStops: tabStops];
	
	TSSTInfoPageAttributes = @{NSFontAttributeName: [NSFont fontWithName: @"Monaco" size: 14],
							  NSParagraphStyleAttributeName: style};
	
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
	loaderLock = nil;
	thumbLock = nil;
}



- (BOOL)shouldDisplayAlone
{   
	if([[self valueForKey: @"text"] boolValue])
	{
		return YES;
	}
	
	CGFloat defaultAspect = 1;
	CGFloat aspect = [[self valueForKey: @"aspectRatio"] doubleValue];
	if(!aspect)
	{
        NSData * imageData = [self pageData];
		[self setOwnSizeInfoWithData: imageData];
		aspect = [[self valueForKey: @"aspectRatio"] doubleValue];
	}
    
	return aspect != 0 ? aspect > defaultAspect : YES;
}


- (void)setOwnSizeInfoWithData:(NSData *)imageData
{
	CGFloat aspect;
	NSSize imageSize;
	NSBitmapImageRep * pageRep = [NSBitmapImageRep imageRepWithData: imageData];
	imageSize = NSMakeSize([pageRep pixelsWide], [pageRep pixelsHigh]);

	if(!NSEqualSizes(NSZeroSize, imageSize))
	{
		aspect = imageSize.width / imageSize.height;
		[self setValue: @(imageSize.width) forKey: @"width"];
		[self setValue: @(imageSize.height) forKey: @"height"];
		[self setValue: @(aspect) forKey: @"aspectRatio"];
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
		thumbnail = [[NSImage alloc] initWithData: thumbnailData];
	}
	else
	{
		thumbnail = [[NSImage alloc] initWithData: thumbnailData];
	}
	
    return thumbnail;
}


- (NSData *)prepThumbnail
{
	[thumbLock lock];
	NSImage * managedImage = [self pageImage];
	NSData * thumbnailData = nil;
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
		thumbnailData = [temp TIFFRepresentation];
	}
	[thumbLock unlock];
	
	return thumbnailData;
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
	
    NSSize imageSize =  NSMakeSize([[self valueForKey: @"width"] doubleValue], [[self valueForKey: @"height"] doubleValue]);
    
    if(!imageFromData || NSEqualSizes(NSZeroSize, imageSize))
    {
        imageFromData = nil;
    }
    else
    {
        [imageFromData setCacheMode: NSImageCacheNever];
        
        [imageFromData setSize: imageSize];
        [imageFromData setCacheMode: NSImageCacheBySize];
    }
	
    return imageFromData;
}


- (NSImage *)textPage
{
	NSData * textData;
	if([self valueForKey: @"index"])
	{
		textData = [[self valueForKeyPath: @"group"] dataForPageIndex: [[self valueForKey: @"index"] integerValue]];
	}
	else
	{
		textData = [NSData dataWithContentsOfFile: [self valueForKey: @"imagePath"]];
	}
	
	UniversalDetector * encodingDetector = [UniversalDetector detector];
	[encodingDetector analyzeData: textData];
	NSString * text = [[NSString alloc] initWithData: textData encoding: [encodingDetector encoding]];
//	int lineCount = 0;
	NSRect lineRect;
	NSRect pageRect = NSZeroRect;
	
	NSUInteger index = 0;
	NSUInteger textLength = [text length];
	NSRange lineRange;
	NSString * singleLine;
	while(index < textLength)
	{
		lineRange = [text lineRangeForRange: NSMakeRange(index, 0)];
		index = NSMaxRange(lineRange);
		singleLine = [text substringWithRange: lineRange];
		lineRect = [singleLine boundingRectWithSize: NSMakeSize(800, 800) options: NSStringDrawingUsesLineFragmentOrigin attributes: TSSTInfoPageAttributes];
		if(NSWidth(lineRect) > NSWidth(pageRect))
		{
			pageRect.size.width = lineRect.size.width;
		}
		
		pageRect.size.height += (NSHeight(lineRect) - 19);

	}
	pageRect.size.width += 10;
	pageRect.size.height += 10;
	pageRect.size.height = NSHeight(pageRect) < 500 ? 500 : NSHeight(pageRect);
	
	NSImage * textImage = [[NSImage alloc] initWithSize: pageRect.size];

	[textImage lockFocus];
	[[NSColor whiteColor] set];
	NSRectFill(pageRect);
	[text drawWithRect: NSInsetRect( pageRect, 5, 5) options: NSStringDrawingUsesLineFragmentOrigin attributes: TSSTInfoPageAttributes];
	[textImage unlockFocus];
	
	return textImage;
}


- (NSData *)pageData
{
	NSData * imageData = nil;
	TSSTManagedGroup * group = [self valueForKey: @"group"];
	if([self valueForKey: @"index"])
    {
		NSInteger entryIndex = [[self valueForKey: @"index"] integerValue];
		imageData = [group dataForPageIndex: entryIndex];
	}
    else if([self valueForKey: @"imagePath"])
    {
        imageData = [NSData dataWithContentsOfFile: [self valueForKey: @"imagePath"]];
    }
    
	return imageData;
}


@end

