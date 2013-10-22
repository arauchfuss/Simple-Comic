//
//  DTImageView.h
//  Simple Comic 2
//
//  Created by Alexander Rauchfuss on 11/26/11.
//  Copyright (c) 2011 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DTImageView : NSView
{
    NSImage * page;
}

@property (nonatomic,retain) NSImage * page; 

@end
