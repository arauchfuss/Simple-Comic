//
//  DTComicWindowController.m
//  Simple Comic 2
//
//  Created by Alexander Rauchfuss on 11/25/11.
//  Copyright (c) 2011 Dancing Tortoise Software. All rights reserved.
//

#import "DTComicWindowController.h"

@implementation DTComicWindowController

@synthesize managedWindow;
@dynamic managedObjectContext;


- (id)initWithManagedObject:(NSManagedObject *)object
{
    self = [super init];
    if (self) {
        self.managedWindow = object;
    }
    
    return self;
}



- (NSString *)windowNibName
{
    return @"DTComicWindow";
}



- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}



- (NSManagedObjectContext *)managedObjectContext
{
    return self.managedWindow.managedObjectContext;
}



@end

