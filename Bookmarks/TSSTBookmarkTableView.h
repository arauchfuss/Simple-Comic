//
//  TSSTBookmarkTableView.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/9/08.
//  Copyright 2008 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TSSTBookmarkTableView : NSTableView {
	IBOutlet NSArrayController * bookmarkController;
}

@end
