//
//  TSSTInfoWindow.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 7/15/07.
//  Copyright 2007 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@interface TSSTInfoWindow : NSPanel { }

- (void)caretAtPoint:(NSPoint)point size:(NSSize)size withLimitLeft:(float)left right:(float)right;
- (void)centerAtPoint:(NSPoint)center;
- (void)resizeToDiameter:(float)diameter;

@end



@interface TSSTInfoView : NSView
{
    float caretPosition;
	BOOL bordered;
}

@property (assign) BOOL bordered;
@property (assign) float caretPosition;

@end



@interface TSSTTransparentContent : NSView {
    
}

@end


@interface TSSTCircularImageView : NSImageView {
    
}

@end

