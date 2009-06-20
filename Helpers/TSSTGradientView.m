//
//  TSSTGradientView.m
//  Simple SFTP
//
//  Created by Alexander Rauchfuss on 4/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//


#import "TSSTGradientView.h"


@implementation TSSTGradientView


- (void)drawRect:(NSRect)aRect
{
    NSGradient * fillGradient = [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.85 green: 0.85 blue: 0.85 alpha: 1.0] 
                                                              endingColor: [NSColor colorWithDeviceRed: 0.95 green: 0.95 blue: 0.95 alpha: 1.0]];
    [fillGradient drawInRect: [self bounds] angle: 270];
    [fillGradient release];
}


@end

