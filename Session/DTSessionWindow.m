//
//  DTSessionWindow.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 4/15/17.
//
//

#import "DTSessionWindow.h"
#import "TSSTManagedSession.h"
#import "SimpleComicAppDelegate.h"
#import "DTPageArrayController.h"
#import "DTConstants.h"
#import "TSSTSortDescriptor.h"
#import "TSSTPage.h"
#import "TSSTImageUtilities.h"
#import <Quartz/Quartz.h>

@interface DTSessionWindow ()

@end

@implementation DTSessionWindow


- (id)initWithSession:(TSSTManagedSession *)newSession {
    if(newSession == nil) return nil; // If no session stop the initialization from the get go.
    self = [super init];
    if (self != nil) {
        _session = newSession;
    }
    
    return self;
}


- (void)dealloc {
    [_pageSortDescriptor release];
    [pageController removeObserver: self forKeyPath: @"selectionIndex"];
    [firstPage dealloc];
    [secondPage dealloc];
    [super dealloc];
}


- (NSString *)windowNibName
{
    return @"DTSessionWindow";
}


/* Initial setup for observers and page layout.
 */
- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.styleMask |= NSWindowStyleMaskFullSizeContentView;
    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
    pageController.pageOrder = LeftRight;
    pageController.pageLayout = SinglePage;
    TSSTSortDescriptor * fileNameSort = [[TSSTSortDescriptor alloc] initWithKey: @"imagePath" ascending: YES];
    TSSTSortDescriptor * archivePathSort = [[TSSTSortDescriptor alloc] initWithKey: @"group.path" ascending: YES];
    self.pageSortDescriptor = @[archivePathSort, fileNameSort];
    [pageController addObserver: self forKeyPath: @"selectionIndex" options: 0 context: nil];
    [self setupPageLayers];
    [pageController setSelectionIndex: 0];
    [self updatePages];
}


- (BOOL)windowShouldClose:(id)sender {
    return YES;
}


- (NSManagedObjectContext *)managedObjectContext
{
    return [(SimpleComicAppDelegate *)[NSApp delegate] managedObjectContext];
}


- (void)setupPageLayers {
    [pageView setWantsLayer: YES];
    CALayer * rootLayer = pageView.layer;
    rootLayer.delegate = self;
    rootLayer.backgroundColor = [[NSColor whiteColor] CGColor];
    firstPage = [CALayer new];
    secondPage = [CALayer new];
    
    firstPage.shadowRadius = 5.0;
    firstPage.shadowOffset = CGSizeMake(5, -5);
    firstPage.shadowOpacity = .3;
}

- (void)updateSessionObject {
    // Stub
}


/*  Observes changes to the page controller.  Changes are reflected by the
 page view.  */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    [self updatePages];
}


- (void)updatePages {
    TSSTPage * firstPageObject = pageController.firstPage;
    if(nil != firstPageObject) {
        firstPage.contents = firstPageObject.pageImage;
        firstPageSize = CGSizeMake([[firstPageObject valueForKey: @"width"] floatValue],
                               [[firstPageObject valueForKey: @"height"] floatValue]);
        if(![pageView.layer.sublayers containsObject: firstPage]) {
            [pageView.layer addSublayer: firstPage];
        }
        [self layoutSublayersOfLayer: pageView.layer];
    }else {
        [firstPage removeFromSuperlayer];
    }
}


- (void)layoutSublayersOfLayer:(CALayer *)layer {
    CGSize imageSize = CGSizeZero;
    CGSize insetSize = CGSizeZero;
    if([pageView.layer.sublayers containsObject: firstPage]) {
        insetSize = CGSizeMake(pageView.frame.size.width - 20., pageView.frame.size.height - 20.);
        imageSize = sizeConstraindedBySize(firstPageSize, insetSize);
        firstPage.bounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
        firstPage.position = CGPointMake(pageView.bounds.size.width / 2,
                                         pageView.bounds.size.height / 2);
    }
}


- (void)keyDown:(NSEvent *)event
{
    NSNumber * charNumber = @([[event charactersIgnoringModifiers] characterAtIndex: 0]);
    
    switch ([charNumber unsignedIntValue])
    {
        case NSUpArrowFunctionKey:
            [pageController selectNext: self];
            break;
        case NSDownArrowFunctionKey:
            [pageController selectPrevious: self];
            break;
        case NSLeftArrowFunctionKey:
            [pageController pageLeft: self];
            break;
        case NSRightArrowFunctionKey:
            [pageController pageRight: self];
            break;
        default:
            [super keyDown: event];
            break;
    }
}


@end
