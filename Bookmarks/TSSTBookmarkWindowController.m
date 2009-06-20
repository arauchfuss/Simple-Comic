//
//  TSSTBookmarkWindowController.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TSSTBookmarkWindowController.h"
#import "SimpleComicAppDelegate.h"
#import "TSSTSortDescriptor.h"
#import "TSSTManagedGroup.h"



@implementation TSSTBookmarkWindowController


@synthesize searchPredicate, search;


- (void)awakeFromNib
{
	[bookmarkTableView setDoubleAction: @selector(openBookmark:)];
	[bookmarkTableView setTarget: self];
	[[self window] setContentBorderThickness: 33 forEdge: NSMinYEdge];
}



- (void) dealloc
{
	[search release];
	[searchPredicate release];
	[super dealloc];
}



- (NSString *)windowNibName
{
    return @"TSSTBookmarkWindow";
}



- (NSManagedObjectContext *)managedObjectContext
{
    return [[NSApp delegate] managedObjectContext];
}



- (void)setSearch:(NSString *)new
{
	[search release];
	search = [new retain];
	if(search)
	{
		NSString * attributeKey = @"name";
		self.searchPredicate = [NSPredicate predicateWithFormat: @"%K contains[ci] %@", attributeKey, search];
	}
	else
	{
		self.searchPredicate = nil;
	}
}



- (IBAction)showBookmarks:(id)sender
{
	[[self window] makeKeyAndOrderFront: self];
}



- (IBAction)openBookmark:(id)sender
{
	NSManagedObject * bookmark = [[bookmarkController selectedObjects] objectAtIndex: 0];
	[self openBookmarkWithManagedObject: bookmark];
}


- (void)openBookmarkWithManagedObject:(NSManagedObject *)object
{
	NSFileManager * manager = [NSFileManager defaultManager];
	
	if(![manager fileExistsAtPath: [object valueForKey: @"filePath"]])
	{
		return;
	}
	
	TSSTManagedSession * sessionDescription = [NSEntityDescription insertNewObjectForEntityForName: @"Session" inManagedObjectContext: [self managedObjectContext]];
    NSDictionary * defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
    
    [sessionDescription setValue: [defaults valueForKey: TSSTPageScaleOptions] forKey: TSSTPageScaleOptions];
    [sessionDescription setValue: [defaults valueForKey: TSSTPageOrder] forKey: TSSTPageOrder];
    [sessionDescription setValue: [defaults valueForKey: TSSTTwoPageSpread] forKey: TSSTTwoPageSpread];
		
	TSSTManagedGroup * newGroup = [[NSApp delegate] groupForFile: [object valueForKey: @"filePath"] nested: nil];
	
	[newGroup setValue: sessionDescription forKey: @"session"];
	
	if([object valueForKey: @"pageName"])
	{
		NSArray * images = [[sessionDescription valueForKey: @"images"] allObjects];
		TSSTSortDescriptor * fileNameSort = [[TSSTSortDescriptor alloc] initWithKey: @"imagePath" ascending: YES];
		TSSTSortDescriptor * archivePathSort = [[TSSTSortDescriptor alloc] initWithKey: @"group.name" ascending: YES];
		NSArray * imageSort = [NSArray arrayWithObjects: archivePathSort, fileNameSort, nil];
		[fileNameSort release];
		
		images = [images sortedArrayUsingDescriptors: imageSort];
		NSArray * pageIdentifiers = [images valueForKey: @"deconflictionName"];
		int index = [pageIdentifiers indexOfObject: [object valueForKey: @"pageName"]];

		[sessionDescription setValue: [NSNumber numberWithInt: index] forKey: @"selection"];
	}
	else
	{
		[sessionDescription setValue: 0 forKey: @"selection"];
	}

	
	[[NSApp delegate] windowForSession: sessionDescription];
}



#pragma mark -
#pragma mark Drag and Drop



- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
	return NO;
}


- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	return NSDragOperationNone;
}


- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items
{
	return nil;
}



#pragma mark -
#pragma mark Split View Delegates


//- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
//{
//	NSRect gripRect = NSZeroRect;
//	
//	if(dividerIndex == 0)
//	{
//		float borderHeight = [[self window] contentBorderThicknessForEdge: NSMinYEdge];
//		NSRect subviewRect = [[[splitView subviews] objectAtIndex: 0] frame];
//		gripRect = NSMakeRect(NSMaxX(subviewRect) - borderHeight, NSMaxY(subviewRect) - borderHeight, borderHeight, borderHeight);
//	}
//	
//	return gripRect;
//}


- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	NSRect sidebarRect = [[[[aNotification object] subviews] objectAtIndex: 0] frame];
	NSRect coverRect = [bookmarkCover frame];
	NSRect groupRect = [bookmarkGroupScrollView frame];
	
	coverRect.size.height = NSWidth(coverRect);
	coverRect.origin.y = 33;
	groupRect.origin.y = NSMaxY(coverRect);
	groupRect.size.height = NSHeight(sidebarRect) - NSMaxY(coverRect);
	
	[bookmarkCover setFrame: coverRect];
	[bookmarkGroupScrollView setFrame: groupRect];
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	return 384;
}


- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	return 128;
}


- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect sidebarRect = [[[sender subviews] objectAtIndex: 0] frame];
	NSRect mainRect = [[[sender subviews] objectAtIndex: 1] frame];

	
	float dividerWidth = [sender dividerThickness];
	sidebarRect.size.height = NSHeight([sender frame]);
	
	mainRect.size.height = sidebarRect.size.height;
	mainRect.origin.x = NSMaxX(sidebarRect) + dividerWidth;
	mainRect.size.width = NSWidth([sender frame]) - NSWidth(sidebarRect) - dividerWidth;
	
	[[[sender subviews] objectAtIndex: 0] setFrame: sidebarRect];
	[[[sender subviews] objectAtIndex: 1] setFrame: mainRect];
}



- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect
	   forDrawnRect:(NSRect)drawnRect 
   ofDividerAtIndex:(NSInteger)dividerIndex
{
	proposedEffectiveRect.size.height -= [[self window] contentBorderThicknessForEdge: NSMinYEdge];
	proposedEffectiveRect.origin.x = proposedEffectiveRect.origin.x - NSWidth(proposedEffectiveRect) / 2;
	proposedEffectiveRect.size.width = NSWidth(proposedEffectiveRect) * 2;
	
	return proposedEffectiveRect;
}



@end
