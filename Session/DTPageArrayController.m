//
//  DTPageArrayController.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/11/08.
//  Copyright 2008 Dancing Tortoise Softwar. All rights reserved.
//

/* Controls all of the page turn and two page layout logic.
 */

#import "DTPageArrayController.h"
#import "TSSTPage.h"
#import "DTConstants.h"


@implementation DTPageArrayController


@dynamic firstPage;
@dynamic secondPage;
@dynamic visiblePages;


//+ (NSSet *)keyPathsForValuesAffectingFirstPage
//{
//	return [NSSet setWithObjects: @"selectionIndex", @"pageLayout", nil];
//}
//
//
//+ (NSSet *)keyPathsForValuesAffectingSecondPage
//{
//	return [NSSet setWithObjects: @"selectionIndex", @"pageLayout", nil];
//}


- (TSSTPage *)firstPage {
	return self.selectedObjects[0];
}


- (void)setPageLayout:(NSUInteger)pageLayout {
    [self willChangeValueForKey: @"secondPage"];
    _pageLayout = pageLayout;
    [self didChangeValueForKey: @"secondPage"];

}


/* This controls whether or not a second page is provided
 to the page view. */
- (TSSTPage *)secondPage {
    NSInteger count = [self.arrangedObjects count];
    NSInteger index = self.selectionIndex;
    if((index + 1) >= count) { // check if second page is out of range
        return nil;
    }
    
    TSSTPage * pageOne = self.arrangedObjects[index];
    TSSTPage * pageTwo = self.arrangedObjects[index + 1];
    
    if(TwoPage != self.pageLayout ||    // session layout prefs
       0 == index ||                    // first page always displays alone
       pageOne.shouldDisplayAlone ||          // page has wide aspect ratio
       pageTwo.shouldDisplayAlone) {
        return nil;
    }
    
    
	return self.arrangedObjects[(index + 1)];
}


- (NSArray *)visiblePages {
    return nil;
}


- (IBAction)selectNext:(id)sender
{
    // Uses the default array controller
    // select next if in single page mode
	if(SinglePage == self.pageLayout)
    {
        [super selectNext: sender];
        return;
    }
    
    NSInteger numberOfImages = [[self content] count];
	NSInteger index = [self selectionIndex];
	
    // Makes sure that the next page is not out of range
	if((index + 1) >= numberOfImages)
	{
		return;
	}

    TSSTPage * currentPage = self.arrangedObjects[index];
	BOOL currentAlone = currentPage.shouldDisplayAlone || (index == 0);
    
    TSSTPage * nextPage = self.arrangedObjects[(index + 1)];
	BOOL nextAlone = nextPage.shouldDisplayAlone;
	
	if((currentAlone || nextAlone) && ((index + 1) < numberOfImages))
	{
		[self setSelectionIndex: (index + 1)];
	}
	else if((index + 2) < numberOfImages)
	{
		[self setSelectionIndex: (index + 2)];
	}
}


- (IBAction)selectPrevious:(id)sender
{
    if(SinglePage == self.pageLayout)
    {
        [super selectPrevious: sender];
        return;
    }
    
	NSInteger index = [self selectionIndex];
    
	if((index - 2) >= 0)
	{
        TSSTPage * previousPage = self.arrangedObjects[(index - 1)];
        BOOL previousAlone = previousPage.shouldDisplayAlone;
        TSSTPage * pageBeforeLast = self.arrangedObjects[(index - 2)];
		BOOL beforeLastAlone = pageBeforeLast.shouldDisplayAlone &&
		((index - 2) == 0);
        
        if(previousAlone || beforeLastAlone)
		{
			[self setSelectionIndex: (index - 1)];
			return;
		}
		
		[self setSelectionIndex: (index - 2)];
		return;
	}
	
	if((index - 1) >= 0)
	{
		[self setSelectionIndex: (index - 1)];
	}
}


- (BOOL)canSelectNext
{
    if(SinglePage == self.pageLayout)
    {
        return [super canSelectNext];
    }
    
	NSInteger numberOfPages = [[self content] count];
	NSInteger index = [self selectionIndex];
	
	if((index + 1) >= numberOfPages)
	{
		return NO;
	}
    
    TSSTPage * currentPage = self.arrangedObjects[index];
	BOOL currentAlone = currentPage.shouldDisplayAlone &&
	(index == 0);
    
    TSSTPage * nextPage = [self.arrangedObjects objectAtIndex: (index + 1)];
	BOOL nextAlone = nextPage.shouldDisplayAlone;
	
	if(((currentAlone || nextAlone) && ((index + 1) < numberOfPages)) ||
	   ((index + 2) < numberOfPages) ||
	   (((index + 1) < numberOfPages) && nextAlone))
	{
		return YES;
	}
	else
	{
		return NO;
	}
}


// TODO: make logic more detailed
- (BOOL)canSelectPrevious
{
	return ([self selectionIndex] >= 1) ? YES : NO;
}



- (BOOL)canSelectLeft
{
    BOOL enable = YES;
    switch (self.pageOrder) {
        case LeftRight:
            enable = [self canSelectPrevious];
            break;
        case RightLeft:
            enable = [self canSelectNext];
        default:
            enable = YES; // defaults to YES so controls are not disabled inadvertantly
            break;
    }
	
	return enable;
}



- (BOOL)canSelectRight
{
    BOOL enable = YES;
    switch (self.pageOrder) {
        case LeftRight:
            enable = [self canSelectNext];
            break;
        case RightLeft:
            enable = [self canSelectPrevious];
        default:
            enable = YES; // defaults to YES so controls are not disabled inadvertantly
            break;
    }
    
    return enable;
}


#pragma mark -
#pragma mark Page Navigation


/*! Method flips the page to the right calling nextPage or previousPage
 depending on the prefered page ordering.
 */
- (IBAction)pageRight:(id)sender
{
    if(LeftRight == self.pageOrder)
    {
        [self selectNext: sender];
    }
    else if(RightLeft == self.pageOrder)
    {
        [self selectPrevious: sender];
    }
}


/*! Method flips the page to the left calling nextPage or previousPage
 depending on the prefered page ordering.
 */
- (IBAction)pageLeft:(id)sender
{
    if(LeftRight == self.pageOrder)
    {
        [self selectPrevious: sender];
    }
    else if(RightLeft == self.pageOrder)
    {
        [self selectNext: sender];
    }
}


- (IBAction)pageTurn:(id)sender
{
    NSInteger tag = [[sender cell] tagForSegment: [sender selectedSegment]];
    if(tag == 1)
    {
        [self pageRight: sender];
    }
    else
    {
        [self pageLeft: sender];
    }
}


- (IBAction)shiftPageRight:(id)sender
{
    if(LeftRight == self.pageOrder)
    {
        [super selectNext: sender];
    }
    else if(RightLeft == self.pageOrder)
    {
        [super selectPrevious: sender];
    }
}


- (IBAction)shiftPageLeft:(id)sender
{
    if(LeftRight == self.pageOrder)
    {
        [super selectPrevious: sender];
    }
    else if(RightLeft == self.pageOrder)
    {
        [super selectNext: sender];
    }
}


- (IBAction)skipRight:(id)sender
{
    NSInteger index = [self selectionIndex];
    NSInteger possibleIndex;
    if(LeftRight == self.pageOrder)
    {
        possibleIndex = index + 10;
        index = possibleIndex < [[self content] count] ? possibleIndex : [[self content] count] - 1;
    }
    else if(RightLeft == self.pageOrder)
    {
        index = index > 10 ? index - 10 : 0;
    }
    
    [self setSelectionIndex: index];
}


- (IBAction)skipLeft:(id)sender
{
    NSUInteger index = [self selectionIndex];
    NSUInteger possibleIndex;

    if(RightLeft == self.pageOrder)
    {
        possibleIndex = index + 10;
        index = possibleIndex < [[self content] count] ? possibleIndex : [[self content] count] - 1;
    }
    else if(LeftRight == self.pageOrder)
    {
        index = index > 10 ? index - 10 : 0;
    }

    [self setSelectionIndex: index];
}


- (void)selectFirst
{
	[self setSelectionIndex: 0];
}


- (void)selectLast
{
	[self setSelectionIndex: [[self content] count] - 1];
}




@end
