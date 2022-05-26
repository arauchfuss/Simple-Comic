//  OCRTracker.h
//  MockSimpleComic
//
//  Created by David Phillip Oster on 5/21/2022 Apache Version 2 open source license.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Provide mouse tracking services for an NSImageView to track the recognized text.
@interface OCRTracker : NSResponder

/// The selected text as a single string. Readonly, because it is selected using the mouse. nil if not available.
@property(readonly, nullable) NSString *selection;

/// all the text on the page. nil if not available.
@property(readonly, nullable) NSString *allText;

/// Run the ocr engine on the image in the default language.
- (void)ocrImage:(NSImage *)image;

/// Run the ocr engine on the CGimage in the default language.
- (void)ocrCGImage:(CGImageRef)cgImage;

- (instancetype)initWithView:(NSView *)view NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

#pragma  mark -

/// After owning views, call this to draw the selection as a tint on the view.
- (void)drawRect:(NSRect)dirtyRect;

/// return YES if this handles the mouse down.
- (BOOL)didMouseDown:(NSEvent *)theEvent;

/// return YES if this handles the mouse drag.
- (BOOL)didMouseDragged:(NSEvent *)theEvent;

/// return YES if this handles setting the cursor rects.
- (BOOL)didResetCursorRects;

/// When owning view becomes first responder, call this so it is next.
- (void)becomeNextResponder;

@end

NS_ASSUME_NONNULL_END
