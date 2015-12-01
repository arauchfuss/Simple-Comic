//
//  TSSTInfoWindow.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/15/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*
 This panel subclass is used by both the loupe and the speach bubble styled
 page preview.
 */
@interface TSSTInfoWindow : NSPanel

- (void)caretAtPoint:(NSPoint)point size:(NSSize)size withLimitLeft:(CGFloat)left right:(CGFloat)right;
- (void)centerAtPoint:(NSPoint)center;
- (void)resizeToDiameter:(CGFloat)diameter;

@end

@class TSSTInfoView;

@interface TSSTCircularImageView : NSImageView

@end

