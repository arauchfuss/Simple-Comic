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
    NSString * imageName;
}

@property (copy) NSString * imageName;
@property  BOOL clears;


@end
