//
//  TSSTThumbnailView.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 8/22/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TSSTInfoWindow;
@class TSSTImageView;


@interface TSSTThumbnailView : NSView
{
    IBOutlet NSArrayController * pageController;
	
	IBOutlet TSSTImageView * thumbnailView;
	
    NSMutableIndexSet * trackingRects;
    NSMutableSet * trackingIndexes;
	
    NSInteger hoverIndex;
    NSInteger limit;
    
    NSLock * thumbLock;
    unsigned threadIdent;
}


- (NSRect)rectForIndex:(NSInteger)index;
- (void)removeTrackingRects;
- (void)buildTrackingRects;
- (void)processThumbs;
@property (assign) id dataSource;
- (void)dwell:(NSTimer *)timer;
- (void)zoomThumbnailAtIndex:(NSInteger)index;

@end
