//
//  DTThumbnailController.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 2/28/10.
//  Copyright 2010 Dancing Tortoise Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DTThumbnailController : NSViewController {
	IBOutlet NSArrayController * pageController;
	NSOperationQueue * thumbnailQueue;
	
}


- (void)processThumbs;
- (void)rebuildGrid;
- (void)normalizeThumbnailCount;
- (void)addThumbnailForIndex:(NSNumber *)index;

@end
