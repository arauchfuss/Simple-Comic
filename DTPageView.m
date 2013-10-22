//
//  DTPageView.m
//  Simple Comic 2
//
//  Created by Alexander Rauchfuss on 11/26/11.
//  Copyright (c) 2011 Dancing Tortoise Software. All rights reserved.
//

#import "DTPageView.h"
#import "DTPageViewController.h"

@implementation DTPageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    
}

- (void)setViewController:(DTPageViewController *)newController
{
    if (viewController)
    {
        NSResponder *controllerNextResponder = [viewController nextResponder];
        [super setNextResponder:controllerNextResponder];
        [viewController setNextResponder:nil];
    }
    
    viewController = newController;
    
    if (newController)
    {
        NSResponder *ownNextResponder = [self nextResponder];
        [super setNextResponder: viewController];
        [viewController setNextResponder:ownNextResponder];
    }
}

- (void)setNextResponder:(NSResponder *)newNextResponder
{
    if (viewController)
    {
        [viewController setNextResponder:newNextResponder];
        return;
    }
    
    [super setNextResponder:newNextResponder];
}


@end
