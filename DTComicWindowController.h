//
//  DTComicWindowController.h
//  Simple Comic 2
//
//  Created by Alexander Rauchfuss on 11/25/11.
//  Copyright (c) 2011 Dancing Tortoise Software. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class DTPageArrayController;
@class DTPageViewController;

@interface DTComicWindowController : NSWindowController
{
    __weak NSManagedObject * managedWindow;
}


@property (nonatomic, readonly) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, weak) NSManagedObject * managedWindow;

- (id)initWithManagedObject:(NSManagedObject *)object;

@end
