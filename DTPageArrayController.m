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
#import "DTManagedPage.h"
#import "Constants.h"
#import "Convenience.h"

@implementation DTPageArrayController


@synthesize twoPage, leftToRight;
@dynamic firstPage;
@dynamic secondPage;


+ (NSSet *)keyPathsForValuesAffectingFirstPage
{
	return [NSSet setWithObjects: @"selectionIndex", nil];
}


+ (NSSet *)keyPathsForValuesAffectingSecondPage
{
	return [NSSet setWithObjects: @"selectionIndex", nil];
}


- (DTManagedPage *)firstPage
{
	return [[self selectedObjects] objectAtIndex: 0];
}


/* This controls whether or not a second page is provided
 to the page view. */
- (DTManagedPage *)secondPage
{
    if(!self.twoPage)
    {
        return nil;
    }
    
    NSInteger count = [[self arrangedObjects] count];
    NSInteger index = [self selectionIndex];
    DTManagedPage * pageOne = [[self arrangedObjects] objectAtIndex: index];
    DTManagedPage * pageTwo = (index + 1) < count ? [[self arrangedObjects] objectAtIndex: (index + 1)] : nil;
	BOOL firstAlone = pageOne.displayAlone || 
	(index == 0 && [Convenience lonelyFirstPage]);
    
    if(firstAlone || pageTwo.displayAlone)
	{
		pageTwo = nil;
	}
	
	return pageTwo;
}


- (void)selectNext:(id)sender
{
	if(!self.twoPage)
    {
        [super selectNext: sender];
        return;
    }
    
    NSInteger numberOfImages = [[self content] count];
	NSInteger index = [self selectionIndex];
	
	if((index + 1) >= numberOfImages)
	{
		return;
	}

    
    DTManagedPage * currentPage = [[self arrangedObjects] objectAtIndex: index];
	BOOL currentAlone = currentPage.displayAlone || 
	(index == 0 && [Convenience lonelyFirstPage]);
    
    DTManagedPage * nextPage = [[self arrangedObjects] objectAtIndex: (index + 1)];
	BOOL nextAlone = nextPage.displayAlone;
	
	if((currentAlone || nextAlone) && ((index + 1) < numberOfImages))
	{
		[self setSelectionIndex: (index + 1)];
	}
	else if((index + 2) < numberOfImages)
	{
		[self setSelectionIndex: (index + 2)];
	}
	else if(((index + 1) < numberOfImages) && nextAlone)
	{
		[self setSelectionIndex: (index + 1)];
	}
}


- (void)selectPrevious:(id)sender
{
	if(!self.twoPage)
    {
        [super selectPrevious: sender];
        return;
    }
    
	NSInteger index = [self selectionIndex];
    
	if((index - 2) >= 0)
	{
        DTManagedPage * previousPage = [[self arrangedObjects] objectAtIndex: (index - 1)];
        BOOL previousAlone = previousPage.displayAlone;
        DTManagedPage * pageBeforeLast = [[self arrangedObjects] objectAtIndex: (index - 2)];
		BOOL beforeLastAlone = pageBeforeLast.displayAlone && 
		((index - 2) == 0 && [Convenience lonelyFirstPage]);	
        
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
	if(!self.twoPage)
    {
        return [super canSelectNext];
    }
    
	NSInteger numberOfPages = [[self content] count];
	NSInteger index = [self selectionIndex];
	
	if((index + 1) >= numberOfPages)
	{
		return NO;
	}
    
    DTManagedPage * currentPage = [[self arrangedObjects] objectAtIndex: index];
	BOOL currentAlone = currentPage.displayAlone && 
	(index == 0 && [Convenience lonelyFirstPage]);
    
    DTManagedPage * nextPage = [[self arrangedObjects] objectAtIndex: (index + 1)];
	BOOL nextAlone = nextPage.displayAlone;
	
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



- (BOOL)canSelectPrevious
{
	return ([self selectionIndex] >= 1) ? YES : NO;
}



- (BOOL)canSelectLeft
{
    if(self.leftToRight)
    {
        return [self canSelectPrevious];
    }
    else
    {
        return [self canSelectNext];
    }
	
	return NO;
}



- (BOOL)canSelectRight
{
	if(self.leftToRight)
    {
        return [self canSelectNext];
    }
    else
    {
        return [self canSelectPrevious];
    }
	
	return NO;
}


#pragma mark -
#pragma mark Page Navigation


/*! Method flips the page to the right calling nextPage or previousPage
 depending on the prefered page ordering.
 */
- (IBAction)pageRight:(id)sender
{
    if(self.leftToRight)
    {
        [self selectNext: sender];
    }
    else
    {
        [self selectPrevious: sender];
    }
}


/*! Method flips the page to the left calling nextPage or previousPage
 depending on the prefered page ordering.
 */
- (IBAction)pageLeft:(id)sender
{
    if(self.leftToRight)
    {
        [self selectPrevious: sender];
    }
    else
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
    if(self.leftToRight)
    {
        [super selectNext: sender];
    }
    else
    {
        [super selectPrevious: sender];
    }
}


- (IBAction)shiftPageLeft:(id)sender
{
    if(self.leftToRight)
    {
        [super selectPrevious: sender];
    }
    else
    {
        [super selectNext: sender];
    }
}


- (IBAction)skipRight:(id)sender
{
    NSInteger index = [self selectionIndex];
    NSInteger possibleIndex;
    if(self.leftToRight)
    {
        possibleIndex = index + 10;
        index = possibleIndex < [[self content] count] ? possibleIndex : [[self content] count] - 1;
    }
    else
    {
        index = index > 10 ? index - 10 : 0;
    }
    
    [self setSelectionIndex: index];
}


- (IBAction)skipLeft:(id)sender
{
    NSUInteger index = [self selectionIndex];
    NSUInteger possibleIndex;

    if(!self.leftToRight)
    {
        possibleIndex = index + 10;
        index = possibleIndex < [[self content] count] ? possibleIndex : [[self content] count] - 1;
    }
    else
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
