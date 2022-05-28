//  OCRTracker.h
//
//  Created by David Phillip Oster on 5/21/2022 Apache Version 2 open source license.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class VNRecognizedTextObservation;

/// Provide mouse tracking services for an NSImageView to track the recognized text.
@interface OCRTracker : NSResponder

/// The selected text as a single string. Readonly, because it is selected using the mouse. nil if not available.
@property(readonly, nullable) NSString *selection;

/// all the text on the page. nil if not available.
@property(readonly, nullable) NSString *allText;

/// Run the ocr engine on the first page image in the default language.
/// @param image - OCRed, then used as a cache key for mouse tracking the result. Pass nil to clear the cache entry
- (void)ocrImage:(nullable NSImage *)image;

/// Run the ocr engine on the second page image in the default language.
/// @param image - OCRed, then used as a cache key for mouse tracking the result. Pass nil to clear the cache entry
- (void)ocrImage2:(nullable NSImage *)image;


- (instancetype)initWithView:(NSView *)view NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

#pragma  mark -

///
/// @param image the key for the cached selection
/// @param imageLayer the layer that draws the CGmage
/// @return The layer that draws the hiliting of the selected text.
- (nullable CALayer *)layerForImage:(NSImage *)image imageLayer:(CALayer *)imageLayer;

/// @return YES if this handles the mouse down.
- (BOOL)didMouseDown:(NSEvent *)theEvent;

/// @return YES if this handles the mouse drag.
- (BOOL)didMouseDragged:(NSEvent *)theEvent;

/// @return YES if this handles setting the cursor rects.
- (BOOL)didResetCursorRects;

/// When owning view becomes first responder, call this so this object is next.
- (void)becomeNextResponder;

@end

///  Get the bezierPath of a part of a text observation.
///
///  Used by both OCRTtracker and OCRSelectionLayer
///
/// @param piece - the TextObservation
/// @param r - the range of the string of the TextObservation
/// @return the quadrilateral of the text observation as a NSBezierPath/
API_AVAILABLE(macos(10.15))
NSBezierPath *OCRBezierPathFromTextObservationRange(VNRecognizedTextObservation *piece, NSRange r);

NS_ASSUME_NONNULL_END
