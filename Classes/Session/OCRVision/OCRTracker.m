//  OCRTracker.m
//  MockSimpleComic
//
//  Created by David Phillip Oster on 5/21/2022 Apache Version 2 open source license.
//

#import "OCRTracker.h"

#import "OCRVision.h"
#import <Vision/Vision.h>

/// @return the quadrilateral of the rect observation as a NSBezierPath/
API_AVAILABLE(macos(10.15))
static NSBezierPath *BezierPathFromRectObservation(VNRectangleObservation *piece)
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:piece.topLeft];
	[path lineToPoint:piece.topRight];
	[path lineToPoint:piece.bottomRight];
	[path lineToPoint:piece.bottomLeft];
	[path closePath];
	return path;
}

/// @param piece - the TextObservation
/// @param r - the range of the string of the TextObservation
/// @return the quadrilateral of the text observation as a NSBezierPath/
API_AVAILABLE(macos(10.15))
static NSBezierPath *BezierPathFromTextObservationRange(VNRecognizedTextObservation *piece, NSRange r)
{
	VNRecognizedText *recognizedText = [[piece topCandidates:1] firstObject];
	// VNRectangleObservation is a superclass of VNRecognizedTextObservation. On error, use the whole thing.
	VNRectangleObservation *rect = [recognizedText boundingBoxForRange:r error:NULL] ?: piece;
	return BezierPathFromRectObservation(rect);
}


/// @return the NSRect from two points.
static NSRect RectFrom2Points(NSPoint a, NSPoint b)
{
	return CGRectStandardize(NSMakeRect(a.x, a.y, b.x - a.x, b.y - a.y));
}

/// @return the set of indices into a string such that s[index] is at the near the beginning or end of a whitespace delimited 'word'
static NSIndexSet *WordsBoundariesOfString(NSString *s)
{
	NSMutableIndexSet *indicies = [NSMutableIndexSet indexSetWithIndex:0];
	[indicies addIndex:s.length];
	NSScanner *scanner = [[NSScanner alloc] initWithString:s];
	NSCharacterSet *textChars = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
	while ([scanner scanCharactersFromSet:textChars intoString:NULL])
	{
		[indicies addIndex:scanner.scanLocation];
	}
	return indicies;
}

/// Given two ranges in order, early before late
/// @return a continguous range that spans from early to late.
static NSRange UnionRanges(NSRange early, NSRange late)
{
	return NSMakeRange(early.location, late.length+late.location - early.location);
}


static NSSpeechSynthesizer *sSpeechSynthesizer;

@interface OCRTracker()
@property BOOL isDragging;

/// <VNRecognizedTextObservation *> - 10.15 and newer
@property NSArray *textPieces;

// Key is VNRecognizedTextObservation.
// The value is the NSRange of the underlying string to show as selected.
@property NSMutableDictionary<NSObject *, NSValue *> *selectionPieces;

@property (weak, nullable) NSView *view;

@end

@implementation OCRTracker

- (instancetype)initWithView:(NSView *)view
{
	self = [super init];
	if (self)
	{
		_view = view;
	}
	return self;
}

- (void)becomeNextResponder {
	if (self.view.nextResponder != self)
	{
		self.nextResponder = self.view.nextResponder;
		self.view.nextResponder = self;
	}
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (self.textPieces == nil)
	{
		if (@available(macOS 10.15, *))
		{
			// temporary, to show we haven't run the OCR yet.
			[[NSColor.yellowColor colorWithAlphaComponent:0.4] set];
			CGRect smallBounds = CGRectInset(self.view.bounds, 20, 20);
			NSRectFill(smallBounds);
		}
	} else {
		if (@available(macOS 10.15, *))
		{
			NSAffineTransform *transform = [NSAffineTransform transform];
			[transform scaleXBy:self.view.bounds.size.width yBy:self.view.bounds.size.height];
			for (VNRecognizedTextObservation *piece in self.textPieces)
			{
				NSValue *rangeValue = self.selectionPieces[piece];
				if (rangeValue != nil)
				{
					NSBezierPath *path = BezierPathFromTextObservationRange(piece, rangeValue.rangeValue);
					[path transformUsingAffineTransform:transform];
					[[NSColor.yellowColor colorWithAlphaComponent:0.4] set];
					[path fill];
				}
			}
		}
	}
}

#pragma mark Model

- (NSString *)allText
{
	if (@available(macOS 10.15, *))
	{
		NSMutableArray *a = [NSMutableArray array];
		for (VNRecognizedTextObservation *piece in self.textPieces)
		{
			NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
			[a addObject:text1.firstObject.string];
		}
		return [a componentsJoinedByString:@"\n"];
	}
	return nil;
}

- (NSString *)selection
{
	NSMutableArray *a = [NSMutableArray array];
	if (@available(macOS 10.15, *))
	{
		for (VNRecognizedTextObservation *piece in self.textPieces)
		{
			NSValue *rangeInAValue = self.selectionPieces[piece];
			if (rangeInAValue != nil)
			{
				NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
				NSString *s = text1.firstObject.string;
				s = [s substringWithRange:[rangeInAValue rangeValue]];
				[a addObject:s];
			}
		}
	}
	return [a componentsJoinedByString:@"\n"];
}

- (nullable VNRecognizedTextObservation *)textPieceForMouseEvent:(NSEvent *)theEvent API_AVAILABLE(macos(10.15))
{
	NSPoint where = [self.view convertPoint:[theEvent locationInWindow] fromView:nil];
	return [self textPieceForPoint:where];
}

/// For a point, find the textPiece
///
/// @param where - a point in View coordinates,
/// @return the textPiece that contains that point
- (nullable VNRecognizedTextObservation *)textPieceForPoint:(CGPoint)where API_AVAILABLE(macos(10.15))
{
	if (@available(macOS 10.15, *))
	{
		if (self.textPieces)
		{
			CGRect container = [[[self view] enclosingScrollView] documentVisibleRect];
			for (VNRecognizedTextObservation *piece in self.textPieces)
			{
				CGRect r = [self boundBoxOfPiece:piece];
				r = CGRectIntersection(r, container);
				if (!CGRectIsEmpty(r) && CGRectContainsPoint(r, where)) {
					return piece;
				}
			}
		}
	}
	return nil;
}

/// Return the boundbox of a piece in View coordinates
///
/// @param piece - A text piece
/// @return The bound box in View coordinates
- (CGRect)boundBoxOfPiece:(VNRecognizedTextObservation *)piece API_AVAILABLE(macos(10.15))
{
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:self.view.bounds.size.width yBy:self.view.bounds.size.height];
	CGRect r = piece.boundingBox;
	r.origin = [transform transformPoint:r.origin];
	r.size = [transform transformSize:r.size];
	return r;
}

/// Return the boundbox of a range of a piece in View coordinates
///
/// @param piece - A text piece
/// @param charRange - the range within the piece.
/// @return The bound box in View coordinates
- (CGRect)boundBoxOfPiece:(VNRecognizedTextObservation *)piece range:(NSRange)charRange API_AVAILABLE(macos(10.15))
{
	VNRecognizedText *text1 = [[piece topCandidates:1] firstObject];
	NSString *s1 = text1.string;
	if (s1.length < charRange.location + charRange.length)
	{
		return CGRectNull;
	}

	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:self.view.bounds.size.width yBy:self.view.bounds.size.height];
	NSBezierPath *path = BezierPathFromTextObservationRange(piece, charRange);
	CGRect r = path.bounds;
	r.origin = [transform transformPoint:r.origin];
	r.size = [transform transformSize:r.size];
	return r;
}


#pragma mark OCR

/// Housekeeping around being called by the OCR engine.
///
///  Since this will affect the U.I., sets state on the main thread.
/// @param results -  the OCR's results object.
- (void)ocrDidFinish:(id<OCRVisionResults>)results
{
	NSArray *textPieces = @[];
	if (@available(macOS 10.15, *)) {
		textPieces = results.textObservations;
	}
	// Since we are changing state that affects the U.I., we do it on the main thread in the future,
	// but `complete` isn't guaranteed to exist then, so we assign to locals so it will be captured
	// by the block.
	dispatch_async(dispatch_get_main_queue(), ^{
		self.textPieces = textPieces;
		[self.selectionPieces removeAllObjects];
		[self.view setNeedsDisplay:YES];
		[self.view.window invalidateCursorRectsForView:self.view];
	});
}

- (void)ocrImage:(NSImage *)image
{
	if (@available(macOS 10.15, *)) {
		__block OCRVision *ocrVision = [[OCRVision alloc] init];
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
			[ocrVision ocrImage:image completion:^(id<OCRVisionResults> _Nonnull complete) {
				[self ocrDidFinish:complete];
				ocrVision = nil;
			}];
		});
	}
}

- (void)ocrCGImage:(CGImageRef)cgImage
{
	if (@available(macOS 10.15, *)) {
		__block OCRVision *ocrVision = [[OCRVision alloc] init];
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
			[ocrVision ocrCGImage:cgImage completion:^(id<OCRVisionResults> _Nonnull complete) {
				[self ocrDidFinish:complete];
				ocrVision = nil;
			}];
		});
	}
}


#pragma mark Mouse

- (BOOL)didMouseDown:(NSEvent *)theEvent
{
	NSObject *textPiece = nil;
	if (@available(macOS 10.15, *)) {
		textPiece = [self textPieceForMouseEvent:theEvent];
	}
	BOOL isDoingMouseDown = (textPiece != nil);
	if (isDoingMouseDown)
	{
		[self mouseDownText:theEvent textPiece:textPiece];
	}
	else if (!(theEvent.modifierFlags & NSEventModifierFlagCommand) && self.selectionPieces.count != 0)
	{
		// click not in text selection. Clear the selection.
		[self.selectionPieces removeAllObjects];
		[self.view setNeedsDisplay:YES];
	}
	return isDoingMouseDown;
}

- (void)mouseDownText:(NSEvent *)theEvent textPiece:(NSObject *)textPiece
{
	NSValue *rangeValue = self.selectionPieces[textPiece];
	if (rangeValue != nil && (theEvent.modifierFlags & NSEventModifierFlagControl) != 0) {
		NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
		[theMenu insertItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"" atIndex:0];
		[theMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
		[theMenu insertItemWithTitle:@"Start Speaking" action:@selector(startSpeaking:) keyEquivalent:@"" atIndex:2];
		[theMenu insertItemWithTitle:@"Stop Speaking" action:@selector(stopSpeaking:) keyEquivalent:@"" atIndex:3];
		[NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self.view];
	} else {
		[[NSCursor IBeamCursor] set];
		if (!(theEvent.modifierFlags & NSEventModifierFlagCommand))
		{
			[self.selectionPieces removeAllObjects];
			[self.view setNeedsDisplay:YES];
		}
	}
}

- (BOOL)didMouseDragged:(NSEvent *)theEvent
{
	NSObject *textPiece = nil;
	if (@available(macOS 10.15, *)) {
		textPiece = [self textPieceForMouseEvent:theEvent];
	}
	BOOL isDoingMouseDragged = (textPiece != nil);
	if (isDoingMouseDragged)
	{
		[self mouseDragText:theEvent textPiece:textPiece];
	}
	return isDoingMouseDragged;
}

- (void)mouseDragText:(NSEvent *)theEvent textPiece:(NSObject *)textPiece
{
	NSPoint startPoint = [self.view convertPoint:[theEvent locationInWindow] fromView:nil];
	self.isDragging = YES;
	NSMutableDictionary *previousSelection = [NSMutableDictionary dictionary];
	if (theEvent.modifierFlags & NSEventModifierFlagCommand)
	{
		previousSelection = [self.selectionPieces mutableCopy];
	}
	[self.selectionPieces removeAllObjects];
	[self.selectionPieces addEntriesFromDictionary:previousSelection];
	while ([theEvent type] != NSEventTypeLeftMouseUp)
	{
		if ([theEvent type] == NSEventTypeLeftMouseDragged)
		{
			NSPoint endPoint = [self.view convertPoint:[theEvent locationInWindow] fromView:nil];
			NSRect downRect = RectFrom2Points(startPoint, endPoint);
			[self updateSelectionFromDownRect:downRect previousSelection:previousSelection];
		}
		theEvent = [[self.view window] nextEventMatchingMask: NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged];
	}
	[self.view.window invalidateCursorRectsForView:self.view];
	self.isDragging = NO;
}

/// @param downRect - the rectangle in image coordinates from the start mouse position to the current mouse position.
/// @param previousSelection - the selection as it was before the call to this. This method will update it.
- (void)updateSelectionFromDownRect:(NSRect)downRect previousSelection:(NSMutableDictionary *)previousSelection
{
	if (@available(macOS 10.15, *))
	{
		NSMutableDictionary *selectionSet = [NSMutableDictionary dictionary];
		for (VNRecognizedTextObservation *piece in self.textPieces)
		{
			CGRect pieceR = [self boundBoxOfPiece:piece];
			if (CGRectIntersectsRect(downRect, pieceR)) {
				NSRange r = [self rangeOfPiece:piece intersectsRect:downRect];
				selectionSet[piece] = [NSValue valueWithRange:r];
				previousSelection[piece] = nil;
			}
		}
		[selectionSet addEntriesFromDictionary:previousSelection];
		if (![self.selectionPieces isEqual:selectionSet]) {
			self.selectionPieces = selectionSet;
			[self.view setNeedsDisplay:YES];
			[self.view.window invalidateCursorRectsForView:self.view];
		}
	}
}

// if the start and end indices delimit a range that intersects r, return the range, else the NotFound range.
//
// @param piece - the VNRecognizedTextObservation to examine
// @param r - The rectangle to intersect against
// @param start - the start index into the string of the text of the piece
// @param end - the end index into the string of the text of the piece
// @return the range of the word of the piece that downRect intersects, else the NotFound range.
- (NSRange)rangeOfPiece:(VNRecognizedTextObservation *)piece intersectsRect:(NSRect)r start:(NSUInteger)start end:(NSUInteger)end  API_AVAILABLE(macos(10.15))
{
	if (0 < end - start)	// ignore zero length ranges.
	{
		NSRange wordRange = NSMakeRange(start, end - start);
		CGRect wordR = [self boundBoxOfPiece:piece range:wordRange];
		if (CGRectIntersectsRect(r, wordR))
		{
			return wordRange;
		}
	}
	return NSMakeRange(NSNotFound, 0);
}

// @return the first range of the word of the piece that downRect intersects, else the NotFound range.
- (NSRange)firstRangeOfPiece:(VNRecognizedTextObservation *)piece intersectsRect:(NSRect)downRect indexSet:(NSIndexSet *)wordStarts  API_AVAILABLE(macos(10.15))
{
	NSUInteger endIndex = [wordStarts indexGreaterThanIndex:0];
	NSUInteger startIndex = 0;
	for (;endIndex != NSNotFound; endIndex = [wordStarts indexGreaterThanIndex:endIndex])
	{
		NSRange wordRange = [self rangeOfPiece:piece intersectsRect:downRect start:startIndex end:endIndex];
		if (wordRange.location != NSNotFound)
		{
			return wordRange;
		}
		startIndex = endIndex;
	}
	return NSMakeRange(NSNotFound, 0);
}

/// @return the last range of the word of the piece that downRect intersects, else the NotFound range.
- (NSRange)lastRangeOfPiece:(VNRecognizedTextObservation *)piece intersectsRect:(NSRect)downRect indexSet:(NSIndexSet *)wordStarts  API_AVAILABLE(macos(10.15))
{
	NSUInteger endIndex = [wordStarts lastIndex];
	NSUInteger startIndex = [wordStarts indexLessThanIndex:endIndex];
	for (;startIndex != NSNotFound; startIndex = [wordStarts indexLessThanIndex:startIndex])
	{
		NSRange wordRange = [self rangeOfPiece:piece intersectsRect:downRect start:startIndex end:endIndex];
		if (wordRange.location != NSNotFound)
		{
			return wordRange;
		}
		endIndex = startIndex;
	}
	return NSMakeRange(0, NSNotFound);
}

/// @return the range of all of the words of the text of the piece that downRect intersects.
- (NSRange)rangeOfPiece:(VNRecognizedTextObservation *)piece intersectsRect:(NSRect)downRect API_AVAILABLE(macos(10.15))
{
	VNRecognizedText *text1 = [[piece topCandidates:1] firstObject];
	NSString *s = text1.string;
	NSIndexSet *wordStarts = WordsBoundariesOfString(s);

	NSRange first = [self firstRangeOfPiece:piece intersectsRect:downRect indexSet:wordStarts];
	NSRange last = [self lastRangeOfPiece:piece intersectsRect:downRect indexSet:wordStarts];
	if (first.location == NSNotFound || last.location == NSNotFound)
	{
		return NSMakeRange(0, s.length);
	}
	return UnionRanges(first, last);
}

- (BOOL)didResetCursorRects
{
	if (self.isDragging) {
		[self.view addCursorRect: [[[self view] enclosingScrollView] documentVisibleRect] cursor:[NSCursor IBeamCursor]];
		return YES;
	}
	else if (@available(macOS 10.15, *))
	{
		if (self.textPieces)
		{
			CGRect container = [[[self view] enclosingScrollView] documentVisibleRect];
			for (VNRecognizedTextObservation *piece in self.textPieces)
			{
				CGRect r = [self boundBoxOfPiece:piece];
				r = CGRectIntersection(r, container);
				if (!CGRectIsEmpty(r)) {
					[self.view addCursorRect:r cursor:[NSCursor IBeamCursor]];
				}
			}
		}
	}
	return NO;
}

#pragma mark Menubar

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(copy:))
	{
		BOOL isValid = [self.selectionPieces count] != 0;
		menuItem.title = isValid ? @"Copy Text" : @"Copy";
		return isValid;
	}
	else if ([menuItem action] == @selector(selectAll:))
	{
		if (@available(macOS 10.15, *))
		{
			return [self.textPieces count] != 0 && [self.textPieces count] != [self.selectionPieces count];
		} else {
			return  NO;
		}
		return YES;
	}
	else if ([menuItem action] == @selector(startSpeaking:))
	{
		if (@available(macOS 10.15, *))
		{
			return [self.textPieces count] != 0;
		} else {
			return  NO;
		}
		return YES;
	}
	else if ([menuItem action] == @selector(stopSpeaking:))
	{
		return [sSpeechSynthesizer isSpeaking];
	}
	return NO;
}

- (void)startSpeaking:(id)sender
{
	if (sSpeechSynthesizer == nil)
	{
		sSpeechSynthesizer = [[NSSpeechSynthesizer alloc] init];
	}
	[sSpeechSynthesizer startSpeakingString:[self selection]];
}

- (void)stopSpeaking:(id)sender
{
	[sSpeechSynthesizer stopSpeaking];
}

- (void)selectAll:(id)sender
{
	if (@available(macOS 10.15, *))
	{
		for (VNRecognizedTextObservation *piece in self.textPieces)
		{
			NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
			NSRange r = NSMakeRange(0, text1.firstObject.string.length);
			self.selectionPieces[piece] = [NSValue valueWithRange:r];
		}
		[self.view setNeedsDisplay:YES];
		[self.view.window invalidateCursorRectsForView:self.view];
	}
}

- (void)copy:(id)sender
{
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  [self copyToPasteboard:pboard];
}

- (void)copyToPasteboard:(NSPasteboard *)pboard
{
  NSString *s = [self selection];
  [pboard clearContents];
  [pboard setString:s forType:NSPasteboardTypeString];
}

#pragma mark Services

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType
{
  if (([sendType isEqual:NSPasteboardTypeString] || [sendType isEqual:NSStringPboardType]) && [self.selectionPieces count] != 0)
	{
    return self;
  }
  return [[self nextResponder] validRequestorForSendType:sendType returnType:returnType];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types
{
  if (([types containsObject:NSPasteboardTypeString] || [types containsObject:NSStringPboardType]) && [self.selectionPieces count] != 0)
	{
    [self copyToPasteboard:pboard];
    return YES;
  }
  return NO;
}

@end
