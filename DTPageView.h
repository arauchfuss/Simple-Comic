//
//  DTPageView.h
//  Simple Comic 2
//
//  Created by Alexander Rauchfuss on 11/26/11.
//  Copyright (c) 2011 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Page;
@class DTPageViewController;

@interface DTPageView : NSView
{
    IBOutlet DTPageViewController *viewController;
}


@end
