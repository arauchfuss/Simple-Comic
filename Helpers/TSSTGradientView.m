//
//  TSSTGradientView.m
//  Simple SFTP
//
//  Created by Alexander Rauchfuss on 4/26/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//


#import "TSSTGradientView.h"


@implementation TSSTGradientView


- (void)drawRect:(NSRect)aRect
{
    NSGradient * fillGradient = [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceWhite:0.85 alpha:1.0]
                                                              endingColor: [NSColor colorWithDeviceWhite:0.95 alpha:1.0]];
    [fillGradient drawInRect: [self bounds] angle: 270];
    [fillGradient release];
}


@end

