//
//  DTPageViewController.m
//  Simple Comic 2
//
//  Created by Alexander Rauchfuss on 11/26/11.
//  Copyright (c) 2011 Dancing Tortoise Software. All rights reserved.
//

#import "DTPageViewController.h"
#import <Quartz/Quartz.h>
#import "DTPageView.h"
#import "DTImageView.h"
#import "DTPageArrayController.h"
#import "DTManagedPage.h"
#import "Constants.h"
#import "Convenience.h"
#import "DTPageSortDescriptor.h"

@implementation DTPageViewController
@synthesize pageOne, pageTwo, pageSort, zoomMode;


- (void)awakeFromNib
{
    
    DTPageSortDescriptor * fileNameSort = [[DTPageSortDescriptor alloc] initWithKey: @"path" ascending: YES];
    self.pageSort = [NSArray arrayWithObjects: fileNameSort, nil];
    zoomMode = NO;
    pageTurn = YES;
    [[self.view enclosingScrollView] setNextResponder: self.nextResponder];
    [[self.view enclosingScrollView] setHorizontalScrollElasticity: NSScrollElasticityNone];
    [[self.view enclosingScrollView] setVerticalScrollElasticity: NSScrollElasticityNone];

	[self.view setWantsLayer: YES];
    CALayer * rootLayer = self.view.layer;
    
    rootLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
//    CGColorRef background = [Convenience CGColorFromNSColor: [NSColor greenColor]];
//    rootLayer.backgroundColor = background;
//    CGColorRelease(background);
    
	[rootLayer setDelegate: self];
	[rootLayer setLayoutManager: self];
	[rootLayer setMasksToBounds: NO];
    
    self.pageOne = [CALayer layer];
	pageOne.contentsGravity = kCAGravityResizeAspect;
    
	[pageOne setDelegate: self];

    [rootLayer addSublayer: pageOne];

    
    self.pageTwo = [CALayer layer];
	pageTwo.contentsGravity = kCAGravityResizeAspect;
    
	[pageTwo setDelegate: self];
    

    
	[[self view] setPostsFrameChangedNotifications: YES];
    
    NSUserDefaultsController * defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [pageController bind: @"leftToRight" 
                toObject: defaults withKeyPath: @"values.leftToRight" options: nil];
    [pageController bind: @"twoPage"
                toObject: defaults withKeyPath: @"values.twoPageSpread" options: nil];
    
    
	[pageController addObserver: self forKeyPath: @"selectionIndex" options: 0 context: 0];
    [pageController addObserver: self forKeyPath: @"leftToRight" options: 0 context: 0];
    [defaults addObserver:self forKeyPath: @"values.pageScaling" options: 0 context: 0];

    [pageController setSelectionIndex: 0];
    [[[self view] layer] layoutSublayers];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
    if([keyPath isEqualToString: @"selectionIndex"])
    {
        pageTurn = YES;
        self.zoomMode = NO;
    }
    [[[self view] layer] layoutSublayers];
}


- (void)refreshPages
{
    [[[[self view] layer] sublayers] makeObjectsPerformSelector: @selector(setNeedsDisplay)];
}


- (void)layoutSublayersOfLayer:(CALayer *)layer
{

	if([[self view] layer] != layer)
	{
		return;
	}
    
    NSInteger scaling = [[[NSUserDefaults standardUserDefaults] valueForKey: DTPageScaling] integerValue];
	DTManagedPage * pageOneRef = [pageController firstPage];
	DTManagedPage * pageTwoRef = [pageController secondPage];
	NSRect centeredRect;
    NSSize pageOneSize = pageOneRef.size;
    if(pageTwoRef)
    {
        [[self view].layer addSublayer: pageTwo];
        NSSize pageTwoSize = pageTwoRef.size;
        NSSize combinedSize;
        if( pageOneSize.height > pageTwoSize.height )
        {
            pageTwoSize = NSMakeSize(pageTwoSize.width * (pageTwoSize.height / pageOneSize.height), pageOneSize.height);
        }
        else
        {
            pageOneSize = NSMakeSize(pageOneSize.width * (pageOneSize.height / pageTwoSize.height), pageTwoSize.height);
        }
        
        combinedSize = NSMakeSize(pageOneSize.width + pageTwoSize.width, pageOneSize.height);
        
        if (scaling == DTScalingNo)
        {
            [self.view setFrameSize: combinedSize];
        }
        else if(scaling == DTScalingFit)
        {
            [self.view setFrameSize: [[self.view enclosingScrollView] visibleRect].size];
        }
        else if(scaling == DTScalingHorizontalFit)
        {
            NSLog(@"not implemented");
        }
        
        centeredRect = [Convenience rectWithSize: combinedSize centeredInRect: [[self view] bounds]];
        pageOneSize = [Convenience scale: NSHeight(centeredRect) / pageOneSize.height size: pageOneSize];
        pageTwoSize = [Convenience scale: NSHeight(centeredRect) / pageTwoSize.height size: pageTwoSize];
        
        centeredRect.origin.y = centeredRect.origin.y;
        
        if ([[pageController valueForKey: @"leftToRight"] boolValue])
        {
            pageOne.frame = CGRectMake(centeredRect.origin.x, centeredRect.origin.y, pageOneSize.width, pageOneSize.height);
            pageTwo.frame = CGRectMake(centeredRect.origin.x + pageOneSize.width, centeredRect.origin.y, pageTwoSize.width, pageTwoSize.height);
        }
        else
        {
            pageTwo.frame = CGRectMake(centeredRect.origin.x, centeredRect.origin.y, pageTwoSize.width, pageTwoSize.height);
            pageOne.frame = CGRectMake(centeredRect.origin.x + pageTwoSize.width, centeredRect.origin.y, pageOneSize.width, pageOneSize.height);
        }
        

        if (pageTurn == YES)
        {
            [pageOne setNeedsDisplay];
            [pageTwo setNeedsDisplay];
            pageTurn = NO;
            
        }
    }
    else
    {
        [pageTwo removeFromSuperlayer];
        if (scaling == DTScalingNo)
        {
            [self.view setFrameSize: pageOneSize];
        }
        else if(scaling == DTScalingFit)
        {
            [self.view setFrameSize: [[self.view enclosingScrollView] visibleRect].size];
        }
        else if(scaling == DTScalingHorizontalFit)
        {
            NSLog(@"not implemented");
        }
        centeredRect = [Convenience rectWithSize: pageOneSize centeredInRect: [[self view] bounds]];
        pageOne.frame = NSRectToCGRect(centeredRect);
        if (pageTurn == YES)
        {
            [pageOne setNeedsDisplay];
            pageTurn = NO;
            
        }
    }
}


- (void)displayLayer:(CALayer *)layer
{
    DTManagedPage * page;
    CGImageRef pageImageRef;
	if(layer == pageOne)
	{
        page = [pageController firstPage];
        
        pageImageRef = [Convenience createCGImageRefWithData: page.pageData];
        pageOne.contents = (__bridge_transfer id)pageImageRef;
	}
    else if(layer == pageTwo)
    {
        page = [pageController secondPage];
        
        pageImageRef = [Convenience createCGImageRefWithData: page.pageData];
        pageTwo.contents = (__bridge_transfer id)pageImageRef;
    }
}


- (id<CAAction>)actionForLayer:(CALayer *)theLayer
                        forKey:(NSString *)theKey
{
    if ([[[self view] window] inLiveResize] && ([theKey isEqualToString: @"bounds"] || [theKey isEqualToString: @"position"]))
    {
		return (id<CAAction>)[NSNull null];
    }
	
    return nil;
}



@end
