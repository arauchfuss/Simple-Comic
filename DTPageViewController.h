//
//  DTPageViewController.h
//  Simple Comic 2
//
//  Created by Alexander Rauchfuss on 11/26/11.
//  Copyright (c) 2011 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DTPageArrayController;
@class DTPageView;
@class DTImageView;

@interface DTPageViewController : NSViewController
{
    IBOutlet DTPageArrayController * pageController;
//    IBOutlet NSImageView * imageTest;
    
    CALayer * pageOne;
    CALayer * pageTwo;
    
    CALayer * nextPageOne;
    CALayer * nextPageTwo;

    
    BOOL pageTurn;
    BOOL zoomMode;

    NSArray * pageSort;
    
}

@property (nonatomic, retain) CALayer * pageOne;
@property (nonatomic, retain) CALayer * pageTwo;
@property (nonatomic, retain) NSArray * pageSort;
@property (nonatomic, assign) BOOL zoomMode;



- (void)refreshPages;




@end
