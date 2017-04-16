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
    [super dealloc];
}

- (void)awakeFromNib {
    pageController.pageOrder = LeftRight;
    pageController.pageLayout = SinglePage;
    TSSTSortDescriptor * fileNameSort = [[TSSTSortDescriptor alloc] initWithKey: @"imagePath" ascending: YES];
    TSSTSortDescriptor * archivePathSort = [[TSSTSortDescriptor alloc] initWithKey: @"group.path" ascending: YES];
    self.pageSortDescriptor = @[archivePathSort, fileNameSort];
    [pageController addObserver: self forKeyPath: @"selectionIndex" options: 0 context: nil];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupPageLayers];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
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
    
}



@end
