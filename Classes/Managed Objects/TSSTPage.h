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
    
    TSSTPage.h
 */


#import <Cocoa/Cocoa.h>

@interface TSSTPage : NSManagedObject 
{
    NSLock * thumbLock;
    NSLock * loaderLock;
}

+ (NSArray<NSString*> *)imageExtensions;
+ (NSArray<NSString*> *)textExtensions;
@property (readonly, copy) NSString *name;
//- (NSString *)deconflictionName;
   
@property (readonly) BOOL shouldDisplayAlone;
- (void)setOwnSizeInfoWithData:(NSData *)imageData;
@property (readonly, copy) NSImage *thumbnail;
@property (readonly, copy) NSData *prepThumbnail;
@property (readonly, copy) NSData *pageData;
@property (readonly, copy) NSImage *textPage;
@property (readonly, copy) NSImage *pageImage;

@end
