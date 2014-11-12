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
 
 TSSTManagedGroup.h
*/


#import <Cocoa/Cocoa.h>



@interface TSSTManagedGroup : NSManagedObject
{
    id instance;
    NSLock * groupLock;
}

@property (readonly, strong) id instance;

@property (copy) NSString *path;

- (NSData *)dataForPageIndex:(NSInteger)index;
- (NSData *)dataForPageName:(NSString *)name;
@property (readonly, strong) NSManagedObject *topLevelGroup;
@property (readonly, copy) NSSet *nestedImages;

- (void)nestedFolderContents;

@end

@interface TSSTManagedArchive : TSSTManagedGroup
{

}

+ (NSArray *)archiveExtensions;
+ (NSArray *)quicklookExtensions;
/*  Recurses through archives looking for archives and images */
- (void)nestedArchiveContents;
@property (readonly) BOOL quicklookCompatible;

@end

@interface TSSTManagedPDF : TSSTManagedGroup
{
    
}

/*  Parses PDFs into something Simple Comic can use */
- (void)pdfContents;

@end

