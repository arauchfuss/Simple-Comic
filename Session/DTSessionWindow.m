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
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver: self forKeyPath: TSSTBackgroundColor];
    [pageController removeObserver: self forKeyPath: @"selectionIndex"];
    [pageController unbind: @"pageOrder"];
    [firstPage dealloc];
    [secondPage dealloc];
    [_pageSortDescriptor release];
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
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver: self forKeyPath: TSSTBackgroundColor options: 0 context: nil];

    [pageController addObserver: self forKeyPath: @"selectionIndex" options: 0 context: nil];

    [pageController bind: @"pageOrder"
                toObject: self.session
             withKeyPath: TSSTPageOrder
                 options: nil];
    
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
    
    NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       [NSNull null], @"position",
                                       [NSNull null], @"contents",
                                       [NSNull null], @"bounds",
                                       nil];
    firstPage.actions = newActions;
    [newActions release];
    firstPage.shadowRadius = 5.0;
    firstPage.shadowOffset = CGSizeMake(5, -5);
    firstPage.shadowOpacity = .3;
}


- (void)updateSessionObject {
    // Stub
}


/*  Observes changes to the page controller and defaults.  
    Changes are reflected by the page view.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if ([keyPath isEqualToString: @"selectionIndex"]) {
        [self updatePages];
    }
    else if([keyPath isEqualToString: TSSTBackgroundColor])
    {
        NSColor * color = [NSUnarchiver unarchiveObjectWithData: [defaults valueForKey: TSSTBackgroundColor]];
        pageView.layer.backgroundColor = [color CGColor];
    }
    
    
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

#pragma mark -
#pragma mark Event Handlers



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



#pragma mark -
#pragma mark Actions



- (IBAction)changeTwoPage:(id)sender
{
    BOOL spread = ![[self.session valueForKey: TSSTTwoPageSpread] boolValue];
    [self.session setValue: @(spread) forKey: TSSTTwoPageSpread];
}


- (IBAction)changePageOrder:(id)sender
{
    BOOL pageOrder = ![[self.session valueForKey: TSSTPageOrder] boolValue];
    [self.session setValue: @(pageOrder) forKey: TSSTPageOrder];
}


- (IBAction)pageRight:(id)sender
{
    [pageController pageRight: sender];
}


- (IBAction)pageLeft:(id)sender
{
    [pageController pageLeft: sender];
}


- (IBAction)shiftPageRight:(id)sender
{
    [pageController shiftPageRight: sender];
}


- (IBAction)shiftPageLeft:(id)sender
{
    [pageController shiftPageLeft: sender];
}


- (IBAction)skipRight:(id)sender
{
    [pageController skipRight: sender];
}


- (IBAction)skipLeft:(id)sender
{
    [pageController skipLeft: sender];
}


- (IBAction)firstPage:(id)sender
{
    [pageController setSelectionIndex: 0];
}


- (IBAction)lastPage:(id)sender
{
    [pageController setSelectionIndex: [[pageController content] count] - 1];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    
    BOOL valid = YES;
    int state;
    
    if([menuItem action] == @selector(changeTwoPage:))
    {
        state = [[self.session valueForKey: TSSTTwoPageSpread] boolValue] ? NSOnState : NSOffState;
        [menuItem setState: state];
    }
    else if([menuItem action] == @selector(changePageOrder:))
    {
        if([[self.session valueForKey: TSSTPageOrder] boolValue])
        {
            [menuItem setTitle: NSLocalizedString(@"Right To Left", @"Right to left page order menu item text")];
        }
        else
        {
            [menuItem setTitle: NSLocalizedString(@"Left To Right", @"Left to right page order menu item text")];
        }
    }
    else if([menuItem action] == @selector(pageRight:))
    {
        valid = [pageController canSelectRight];
    }
    else if([menuItem action] == @selector(pageLeft:))
    {
        valid = [pageController canSelectLeft];
    }
    else if ([menuItem action] == @selector(firstPage:))
    {
        valid = !([pageController selectionIndex] <= 0);
    }
    else if ([menuItem action] == @selector(lastPage:))
    {
        valid = !([pageController selectionIndex] >= ([[pageController content] count] - 1));
    }
    else if ([menuItem action] == @selector(shiftPageRight:))
    {
        valid = [pageController canSelectRight];
    }
    else if ([menuItem action] == @selector(shiftPageLeft:))
    {
        valid = [pageController canSelectLeft];
    }
    else if ([menuItem action] == @selector(skipRight:))
    {
        valid = [pageController canSelectRight];
    }
    else if ([menuItem action] == @selector(skipLeft:))
    {
        valid = [pageController canSelectLeft];
    }
    
    return valid;
}


@end
