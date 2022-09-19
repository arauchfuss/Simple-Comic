//  OCRTracker.h
//
//  Created by David Phillip Oster on 5/21/2022  license.txt applies.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// A key for NSUserDefaults \c boolForKey: - if true the entire OCR system is turned  off.
extern NSString *const OCRDisableKey;

@class VNRecognizedTextObservation;
@class OCRFind;
@protocol OCRTrackerDelegate;

/// Provide mouse tracking services for an NSImageView to track the recognized text.
@interface OCRTracker : NSResponder

/// The selected text as a single string. Readonly, because it is selected using the mouse. nil if not available.
@property (readonly, nullable) NSString *selection;

/// all the text on the page. nil if not available.
@property (readonly, nullable) NSString *allText;

@property (readonly, weak, nullable) NSView *view;

@property (weak)id<OCRTrackerDelegate> delegate;


/// the range of 'allText' that is currently selected.
@property NSRange allTextSelection;

/// If OCR is disabled, then hide the Find and Speak menus that use it.
+ (void)hideOCRMenusIfUnavailable;

/// Run the ocr engine on the first page image in the default language.
/// @param image OCRed, then used as a cache key for mouse tracking the result. Pass \c nil to clear the cache entry
- (void)ocrImage:(nullable NSImage *)image;

/// Run the ocr engine on the second page image in the default language.
/// @param image OCRed, then used as a cache key for mouse tracking the result. Pass \c nil to clear the cache entry
- (void)ocrImage2:(nullable NSImage *)image;

- (nullable instancetype)initWithView:(NSView *)view NS_DESIGNATED_INITIALIZER;

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

#pragma  mark - Find

/// all of the ocr'ed text, `join` separated lines.
- (NSString *)allTextJoinedBy:(NSString *)join;

/// all of the ocr'ed selected text,  `join` separated lines
- (NSString *)selectionJoinedBy:(NSString *)join;

/// These 'find' methods use ranges that operate on a virtual string: the in-order concatenation plus space of all the recognized text pieces.
- (NSArray<NSValue *> *)selectedFindRanges API_AVAILABLE(macos(10.15));

/// These 'find' methods use ranges that operate on a virtual string: the in-order concatenation plus space of all the recognized text pieces.
///  setting the range here causes the U.I. to draw the new selection.
- (void)setSelectedFindRange:(NSRange)range API_AVAILABLE(macos(10.15));

/// These 'find' methods use ranges that operate on a virtual string: the in-order concatenation of all the recognized text pieces.
/// Scroll the range into the visible part of the scrollable window.
- (void)scrollFindRangeToVisible:(NSRange)range API_AVAILABLE(macos(10.15));

/// an array of all the text pieces.
- (NSArray *)textPieces API_AVAILABLE(macos(10.15));

@end

@protocol OCRTrackerDelegate <NSObject>
- (OCRFind *)find;
@end

/// Get the bezierPath of a part of a text observation.
///
/// Used by both \c OCRTtracker and \c OCRSelectionLayer
///
/// @param piece - the TextObservation
/// @param r - the range of the string of the TextObservation
/// @return the quadrilateral of the text observation as a NSBezierPath/
API_AVAILABLE(macos(10.15))
NSBezierPath *OCRBezierPathFromTextObservationRange(VNRecognizedTextObservation *piece, NSRange r);

NS_ASSUME_NONNULL_END
