//
//  TSSTImageView.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/15/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TSSTImageView : NSImageView
{
    BOOL clears;
    NSString * imageName;
}

@property (retain) NSString * imageName;
- (void)setClears:(BOOL)yes;
- (BOOL)clears;


@end
