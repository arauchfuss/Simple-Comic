//
//  TSSTCRTProgressBar.h
//  iTunesProgress
//
//  Created by Alexander Rauchfuss on 7/14/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol TSSTProgressBarDataSourceProto


@end


@interface TSSTCRTProgressBar : NSView
{
    int maxValue;
    int currentValue;
    BOOL leftToRight;
    NSRect progressRect;
	float horizontalMargin;
	BOOL highContrast;
}

@property (assign) BOOL highContrast;
@property (assign) BOOL leftToRight;

@property (assign) NSRect progressRect;
@property (assign) float horizontalMargin;

@property (assign) int maxValue;
@property (assign) int currentValue;

- (int)indexForPoint:(NSPoint)point;


@end
