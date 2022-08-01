//  OCRTracker.m
//  MockSimpleComic
//
//  Created by David Phillip Oster on 5/21/2022  license.txt applies.
//

#import "OCRTracker.h"

#import "OCRSelectionLayer.h"
#import "OCRFind.h"
#import "OCRVision.h"
#import <Vision/Vision.h>

NSString *const OCRDisableKey = @"OCRDisableKey";

static BOOL sIsEnabled = YES;

// Tags on menu items, for: hideOCRMenusIfUnavailable
enum {
  PREDECESSOR_TAG = 1879,
	SEPARATOR_TAG = 1901,
	FIND_TAG = 1902,
	SPEEK_TAG = 1906,
};

// When the menu items that depend on recognized text are hidden, save those items here.
static NSMutableArray<NSMenuItem *> *sStashedMenuItems = nil;


/// @return the quadrilateral of the rect observation as a NSBezierPath/
API_AVAILABLE(macos(10.15))
static NSBezierPath *OCRBezierPathFromRectObservation(VNRectangleObservation *piece)
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
NSBezierPath *OCRBezierPathFromTextObservationRange(VNRecognizedTextObservation *piece, NSRange r)
{
	VNRecognizedText *recognizedText = [[piece topCandidates:1] firstObject];
	// VNRectangleObservation is a superclass of VNRecognizedTextObservation. On error, use the whole thing.
	VNRectangleObservation *rect = [recognizedText boundingBoxForRange:r error:NULL] ?: piece;
	return OCRBezierPathFromRectObservation(rect);
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

/// Bundle up all the data associated with one our client's images.
@interface OCRDatum : NSObject

/// The image associated with these textPieces. Weak, because the client of this owns it.
@property(weak) NSImage *image;

/// The image that would have been current, but we are disabled. Weak, because the client of this owns it.
/// Only used for the transition from disabled to enabled.
@property(weak) NSImage *imageWhileDisabled;

/// non-nil while this is actively OCRing.
@property OCRVision *activeOCR API_AVAILABLE(macos(10.15));

@property(weak) CALayer *selectionLayer;

/// <VNRecognizedTextObservation *> - 10.15 and newer
@property(nonatomic) NSArray *textPieces;

// Key is VNRecognizedTextObservation.
// The value is the NSRange of the underlying string to show as selected.
@property NSMutableDictionary<NSObject *, NSValue *> *selectionPieces;

@property(nonatomic, readonly) NSUInteger totalStringLength;

- (void)reset;

@end

@implementation OCRDatum
@synthesize totalStringLength = _totalStringLength;

- (void)setTextPieces:(NSArray *)textPieces
{
	_textPieces = textPieces;
	_totalStringLength = NSNotFound;
}

- (NSUInteger)totalStringLength
{
	if (@available(macOS 10.15, *))
	{
		if (_totalStringLength == NSNotFound) {
			_totalStringLength = 0;
			for (VNRecognizedTextObservation *piece in self.textPieces) {
				_totalStringLength += [[[[piece topCandidates:1] firstObject] string] length];
			}
		}
		return _totalStringLength;
	}
	return 0;
}

- (void)reset
{
	self.image = nil;
	self.textPieces = @[];
	[self.selectionPieces removeAllObjects];
}

@end

@interface OCRTracker()
@property BOOL isDragging;
@property BOOL needsInvalidateCursorRects;

@property NSArray<OCRDatum *> *datums;

@property (weak, readwrite, nullable) NSView *view;

@end

@implementation OCRTracker

+ (void)hideOCRMenusIfUnavailable {
	if (![[NSUserDefaults standardUserDefaults] boolForKey:OCRDisableKey]) {
		if (sStashedMenuItems) {
			//  If we'd previously removed menu items, put them back in the menu bar.
			NSArray<NSMenuItem *> *mainMenu = [[NSApp mainMenu] itemArray];
			for (NSMenuItem *topItem in mainMenu) {
				NSUInteger count = topItem.submenu.itemArray.count;
				for (NSUInteger i = 0; i < count; ++i) {
					NSMenuItem *oldItem = topItem.submenu.itemArray[i];
					if ([oldItem tag] == PREDECESSOR_TAG) {
						NSMutableArray *newItems = [topItem.submenu.itemArray mutableCopy];
						while (sStashedMenuItems.count) {
							[newItems insertObject:sStashedMenuItems.firstObject atIndex:i+1];
							[sStashedMenuItems removeObjectAtIndex:0];
						}
						sStashedMenuItems = nil;
						[topItem.submenu setItemArray:newItems];
						break;
					}
				}
			}
		}
		return;
	}
	// Hide the Find and Speak submenus.
	NSArray<NSMenuItem *> *mainMenu = [[NSApp mainMenu] itemArray];
	int tags[] = {SPEEK_TAG, FIND_TAG, SEPARATOR_TAG};
	for(int i = 0; i < sizeof(tags)/sizeof(*tags); ++i) {
		for (NSMenuItem *topItem in mainMenu) {
			NSInteger index = [topItem.submenu indexOfItemWithTag:tags[i]];
			if (0 < index) {
				if (sStashedMenuItems == nil) {
					sStashedMenuItems = [NSMutableArray array];
				}
				[sStashedMenuItems addObject:[topItem.submenu itemAtIndex:index]];
				[topItem.submenu removeItemAtIndex:index];
			}
		}
	}
}

- (instancetype)initWithView:(NSView *)view
{
	self = [super init];
	if (self)
	{
		_view = view;
		_datums = @[
			[[OCRDatum alloc] init],
			[[OCRDatum alloc] init],
		];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults addObserver:self forKeyPath:OCRDisableKey options:0 context:NULL];
		sIsEnabled = ![defaults boolForKey:OCRDisableKey];
	}
	return self;
}

- (void)dealloc
{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults removeObserver:self forKeyPath:OCRDisableKey context:NULL];
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

- (void)observeValueForKeyPath:(NSString *)keyPath
											ofObject:(id)object
												change:(NSDictionary *)change
											 context:(void *)context
{
	if ([keyPath isEqual:OCRDisableKey]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if (defaults == object) {
			sIsEnabled = ![defaults boolForKey:OCRDisableKey];
			if (sIsEnabled) {
				NSUInteger count = self.datums.count;
				for (NSUInteger i = 0; i < count; ++i)
				{
					OCRDatum *datum = self.datums[i];
					NSImage *image = datum.imageWhileDisabled;
					if (image)
					{
						datum.imageWhileDisabled = nil;
						[self ocrImage:image index:i];
					}
				}
			}
			[self.view setNeedsDisplay:YES];
			self.needsInvalidateCursorRects = YES;
			[self.view.window invalidateCursorRectsForView:self.view];
			[[self class] hideOCRMenusIfUnavailable];
		}
	}
}

- (OCRDatum *)datumOfImage:(NSImage *)image
{
	for (OCRDatum *datum in self.datums) {
		if (datum.image == image) {
			return datum;
		}
	}
	return nil;
}

- (BOOL)isAnySelected {
	for (OCRDatum *datum in self.datums)
	{
		if (datum.image != nil && datum.selectionPieces.count != 0)
		{
			return YES;
		}
	}
	return NO;
}

- (NSInteger)totalTextPiecesCount
{
	NSInteger total = 0;
	for (OCRDatum *datum in self.datums)
	{
		if (datum.image != nil) {
			total += datum.textPieces.count;
		}
	}
	return total;
}

- (NSInteger)totalSelectionPiecesCount
{
	NSInteger total = 0;
	for (OCRDatum *datum in self.datums)
	{
		if (datum.image != nil) {
			total += datum.selectionPieces.count;
		}
	}
	return total;
}

- (void)addSelectionPiecesFromDictionary:(NSDictionary *)previousSelection API_AVAILABLE(macos(10.15))
{
	for (VNRecognizedTextObservation *textPiece in previousSelection.allKeys)
	{
		for (OCRDatum *datum in self.datums)
		{
			if (datum.image != nil && [datum.textPieces containsObject:textPiece]) {
				datum.selectionPieces[textPiece] = previousSelection[textPiece];
				break;
			}
		}
	}
}


/// @return a layer of the selection for image scaled to frame.
- (nullable CALayer *)layerForImage:(NSImage *)image imageLayer:(CALayer *)imageLayer {
	if (!sIsEnabled) {
		return nil;
	}
	CALayer *layer = nil;
	if (@available(macOS 10.15, *))
	{
		OCRDatum *datum = [self datumOfImage:image];
		if (datum.image != nil && datum.textPieces != nil)
		{
			OCRSelectionLayer *selectionLayer =  [[OCRSelectionLayer alloc] initWithObservations:datum.textPieces selection:datum.selectionPieces imageLayer:imageLayer];
			datum.selectionLayer = selectionLayer;
			if (self.needsInvalidateCursorRects)
			{
				[self.view.window invalidateCursorRectsForView:self.view];
				self.needsInvalidateCursorRects = NO;
			}
			return selectionLayer;
		}
	}
	return layer;
}

#pragma mark Model

- (NSString *)allTextJoinedBy:(NSString *)join
{
	if (@available(macOS 10.15, *))
	{
		NSMutableArray *a = [NSMutableArray array];
		for (OCRDatum *datum in self.datums)
		{
			if (datum.image != nil)
			{
				for (VNRecognizedTextObservation *piece in datum.textPieces)
				{
					NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
					[a addObject:text1.firstObject.string];
				}
			}
		}
		return [a componentsJoinedByString:join];
	}
	return @"";
}

- (NSString *)allText
{
	return [self allTextJoinedBy:@"\n"];
}

- (NSRange)allTextSelection
{
	NSRange result = NSMakeRange(0, 0);
	NSInteger location = 0;
	if (@available(macOS 10.15, *))
	{
		for (OCRDatum *datum in self.datums)
		{
			if (datum.image != nil)
			{
				for (VNRecognizedTextObservation *piece in datum.textPieces)
				{
					NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
					location += text1.firstObject.string.length;
					NSValue *rangeInAValue = datum.selectionPieces[piece];
					if (rangeInAValue != nil)
					{
						NSRange r = [rangeInAValue rangeValue];
						location += r.location;
						return NSMakeRange(location, r.length);
					} else {
						location += 1;
					}
				}
			}
		}
	}
	return result;
}

- (void)setAllTextSelection:(NSRange)candidateSelection
{
	if (@available(macOS 10.15, *))
	{
		NSInteger location = candidateSelection.location;
		if (candidateSelection.length == 0 || candidateSelection.location == NSNotFound)
		{
			[self clearSelection];
			return;
		}
		for (OCRDatum *datum in self.datums)
		{
			if (datum.image != nil)
			{
				for (VNRecognizedTextObservation *piece in datum.textPieces)
				{
					NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
					if (text1.firstObject.string.length < location)
					{
						location -= text1.firstObject.string.length + 1;
					} else {
						NSRange r = NSMakeRange(location,
								MIN(candidateSelection.length, text1.firstObject.string.length));
						[datum.selectionPieces removeAllObjects];
						datum.selectionPieces[piece] = [NSValue valueWithRange:r];
						[self.view setNeedsDisplay:YES];
						return;
					}
				}
			}
		}
	}
}

- (void)clearSelection
{
	for (OCRDatum *datum in self.datums)
	{
		if (datum.image != nil && datum.selectionPieces.count != 0)
		{
			[datum.selectionPieces removeAllObjects];
			[self.view setNeedsDisplay:YES];
		}
	}
}


- (NSString *)selectionJoinedBy:(NSString *)join
{
	NSMutableArray *a = [NSMutableArray array];
	if (@available(macOS 10.15, *))
	{
		for (OCRDatum *datum in self.datums)
		{
			if (datum.image != nil)
			{
				for (VNRecognizedTextObservation *piece in datum.textPieces)
				{
					NSValue *rangeInAValue = datum.selectionPieces[piece];
					if (rangeInAValue != nil)
					{
						NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
						NSString *s = text1.firstObject.string;
						s = [s substringWithRange:[rangeInAValue rangeValue]];
						[a addObject:s];
					}
				}
			}
		}
	}
	return [a componentsJoinedByString:join];
}

- (NSString *)selection
{
	return [self selectionJoinedBy:@"\n"];
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
		for (OCRDatum *datum in self.datums)
		{
			if (datum.image != nil && datum.textPieces)
			{
				CGRect container = [[[self view] enclosingScrollView] documentVisibleRect];
				CGSize imageSize = datum.selectionLayer.bounds.size;
				for (VNRecognizedTextObservation *piece in datum.textPieces)
				{
					CGRect r = VNImageRectForNormalizedRect(piece.boundingBox, imageSize.width, imageSize.height);
					r = [datum.selectionLayer convertRect:r toLayer:self.view.layer];
					r = CGRectIntersection(r, container);
					if (!CGRectIsEmpty(r) && CGRectContainsPoint(r, where))
					{
						return piece;
					}
				}
			}
		}
	}
	return nil;
}

/// Return the boundbox of a range of a piece in View coordinates
///
/// @param piece - A text piece
/// @param charRange - the range within the piece.
/// @return The bound box in VNRecognizedTextObservation coordinates
- (CGRect)boundBoxOfPiece:(VNRecognizedTextObservation *)piece range:(NSRange)charRange API_AVAILABLE(macos(10.15))
{
	VNRecognizedText *text1 = [[piece topCandidates:1] firstObject];
	NSString *s1 = text1.string;
	if (s1.length < charRange.location + charRange.length)
	{
		return CGRectNull;
	}

	NSBezierPath *path = OCRBezierPathFromTextObservationRange(piece, charRange);
	return path.bounds;
}

- (NSArray *)textPieces
{
	NSMutableArray *a = [NSMutableArray array];
	for (OCRDatum *datum in self.datums) {
		[a addObjectsFromArray:datum.textPieces];
	}
	return a;
}

#pragma mark OCR

/// Housekeeping around being called by the OCR engine.
///
///  Since this will affect the U.I., sets state on the main thread.
/// @param results -  the OCR's results object.
- (void)ocrDidFinish:(id<OCRVisionResults>)results image:(NSImage *)image index:(NSInteger)index
{
	NSArray *textPieces = @[];
	NSError *error = results.ocrError;
	if (@available(macOS 10.15, *)) {
		self.datums[index].activeOCR = nil;
		textPieces = results.textObservations;
	}
	// Since we are changing state that affects the U.I., we do it on the main thread in the future,
	// but `complete` isn't guaranteed to exist then, so we assign to locals so it will be captured
	// by the block.
	dispatch_async(dispatch_get_main_queue(), ^{
		OCRDatum *datum = self.datums[index];
		datum.image = (error == nil) ? image : nil;
		datum.textPieces = (error == nil) ? textPieces : @[];
		[datum.selectionPieces removeAllObjects];
		[self.view setNeedsDisplay:YES];
		self.needsInvalidateCursorRects = YES;
	});
}

- (void)ocrImage:(NSImage *)image index:(NSInteger)index
{
	if (@available(macOS 10.15, *)) {
		OCRDatum *datum = self.datums[index];
		datum.image = nil;
		[datum.activeOCR cancel];
		datum.activeOCR = nil;
		datum.textPieces = @[];
		[datum.selectionPieces removeAllObjects];
		if (image)
		{
			__block OCRVision *ocrVision = [[OCRVision alloc] init];
			datum.activeOCR = ocrVision;
			__weak typeof(self) weakSelf = self;
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
				[ocrVision ocrImage:image completion:^(id<OCRVisionResults> _Nonnull complete) {
					[weakSelf ocrDidFinish:complete image:image index:index];
					ocrVision = nil;
				}];
			});
		}
	}
}

- (void)ocrImage:(NSImage *)image
{
	if (sIsEnabled) {
		[self ocrImage:image index:0];
	} else {
		[self.datums[0] reset];
		self.datums[0].imageWhileDisabled = image;
	}
}

- (void)ocrImage2:(NSImage *)image
{
	if (sIsEnabled) {
		[self ocrImage:image index:1];
	} else {
		[self.datums[1] reset];
		self.datums[1].imageWhileDisabled = image;
	}
}


#pragma mark Mouse

- (BOOL)didMouseDown:(NSEvent *)theEvent
{
	if (!sIsEnabled) {
		return NO;
	}
	NSObject *textPiece = nil;
	if (@available(macOS 10.15, *)) {
		textPiece = [self textPieceForMouseEvent:theEvent];
	}
	BOOL isDoingMouseDown = (textPiece != nil);
	if (isDoingMouseDown)
	{
		[self mouseDown:theEvent textPiece:textPiece];
	}
	else if (!(theEvent.modifierFlags & NSEventModifierFlagCommand) && self.isAnySelected)
	{
		// click not in text selection. Clear the selection.
		for (OCRDatum *datum in self.datums)
		{
			[datum.selectionPieces removeAllObjects];
		}
		[self.view setNeedsDisplay:YES];
	}
	return isDoingMouseDown;
}

- (void)mouseDown:(NSEvent *)theEvent textPiece:(NSObject *)textPiece
{
	if (!sIsEnabled) {
		return;
	}
	NSInteger i = 0;
	NSValue *rangeValue = nil;
	for (;i < self.datums.count; ++i) {
		OCRDatum *datum = self.datums[i];
		rangeValue = datum.selectionPieces[textPiece];
		if (datum.image != nil && rangeValue != nil)
		{
			break;
		}
	}
	if (rangeValue != nil && (theEvent.modifierFlags & NSEventModifierFlagControl) != 0) {
		NSMenu *theMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Contextual Menu", @"")];
		[theMenu insertItemWithTitle:NSLocalizedString(@"Copy", @"") action:@selector(copy:) keyEquivalent:@"" atIndex:0];
		[theMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
		[theMenu insertItemWithTitle:NSLocalizedString(@"Start Speaking", @"") action:@selector(startSpeaking:) keyEquivalent:@"" atIndex:2];
		[theMenu insertItemWithTitle:NSLocalizedString(@"Stop Speaking", @"") action:@selector(stopSpeaking:) keyEquivalent:@"" atIndex:3];
		[NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self.view];
	} else {
		[[NSCursor IBeamCursor] set];
		if (!(theEvent.modifierFlags & NSEventModifierFlagCommand))
		{
			for (OCRDatum *datum in self.datums)
			{
				[datum.selectionPieces removeAllObjects];
			}
			[self.view setNeedsDisplay:YES];
		}
	}
}

- (BOOL)didMouseDragged:(NSEvent *)theEvent
{
	if (!sIsEnabled) {
		return NO;
	}
	NSObject *textPiece = nil;
	if (@available(macOS 10.15, *)) {
		textPiece = [self textPieceForMouseEvent:theEvent];
	}
	BOOL isDoingMouseDragged = (textPiece != nil);
	if (isDoingMouseDragged)
	{
		[self mouseDrag:theEvent textPiece:textPiece];
	}
	return isDoingMouseDragged;
}

- (void)mouseDrag:(NSEvent *)theEvent textPiece:(NSObject *)textPiece
{
	NSPoint startPoint = [self.view convertPoint:[theEvent locationInWindow] fromView:nil];
	self.isDragging = YES;
	NSMutableDictionary *previousSelection = [NSMutableDictionary dictionary];
	if (theEvent.modifierFlags & NSEventModifierFlagCommand)
	{
		for (OCRDatum *datum in self.datums)
		{
			if (datum.image != nil)
			{
				[previousSelection addEntriesFromDictionary:datum.selectionPieces];
			}
		}
	}
	for (OCRDatum *datum in self.datums)
	{
		[datum.selectionPieces removeAllObjects];
	}
	if (@available(macOS 10.15, *)) {
		[self addSelectionPiecesFromDictionary:previousSelection];
	}
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

/// @param downRect - the rectangle in view coordinates from the start mouse position to the current mouse position.
/// @param previousSelection - the selection as it was before the call to this. This method will update it.
- (void)updateSelectionFromDownRect:(NSRect)downRect previousSelection:(NSMutableDictionary *)previousSelection
{
	if (@available(macOS 10.15, *))
	{
		BOOL needsDisplay = NO;

		for (OCRDatum *datum in self.datums) {
			if (datum.image != nil)
			{
				NSMutableDictionary *selectionDict = [NSMutableDictionary dictionary];
				CGSize imageSize = datum.selectionLayer.bounds.size;
				for (VNRecognizedTextObservation *piece in datum.textPieces)
				{
					CGRect pieceR = VNImageRectForNormalizedRect(piece.boundingBox, imageSize.width, imageSize.height);
					pieceR = [datum.selectionLayer convertRect:pieceR toLayer:self.view.layer];
					if (CGRectIntersectsRect(downRect, pieceR)) {
						CGRect imageDownRect = [datum.selectionLayer convertRect:downRect fromLayer:self.view.layer];
						CGRect pieceDownRect = VNNormalizedRectForImageRect(imageDownRect, imageSize.width, imageSize.height);
						NSRange r = [self rangeOfPiece:piece intersectsRect:pieceDownRect];
						NSValue *rangePtr = previousSelection[piece];
						if (rangePtr != nil) {
							NSRange oldRange = [rangePtr rangeValue];
							r = UnionRanges(r, oldRange);
							previousSelection[piece] = nil;
						}
						selectionDict[piece] = [NSValue valueWithRange:r];
					}
				}
				[selectionDict addEntriesFromDictionary:previousSelection];
				if (![datum.selectionPieces isEqual:selectionDict]) {
					datum.selectionPieces = selectionDict;
					needsDisplay = YES;
				}

			}
		}
		if (needsDisplay)
		{
			[self.view setNeedsDisplay:YES];
			[self.view.window invalidateCursorRectsForView:self.view];
		}
	}
}

// if the start and end indices delimit a range that intersects r, return the range, else the NotFound range.
//
// @param piece - the VNRecognizedTextObservation to examine
// @param r - The rectangle, in VNRecognizedTextObservation coordinates to intersect against
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

/// @param downRect - in VNRecognizedTextObservation coordinates
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

/// @param downRect - in VNRecognizedTextObservation coordinates
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

/// @param downRect - in VNRecognizedTextObservation coordinates
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
		for (OCRDatum *datum in self.datums)
		{
			if (datum.image != nil && datum.textPieces.count)
			{
				CGRect container = [[[self view] enclosingScrollView] documentVisibleRect];
				CGSize imageSize = datum.selectionLayer.bounds.size;
				for (VNRecognizedTextObservation *piece in datum.textPieces)
				{
					CGRect r = VNImageRectForNormalizedRect(piece.boundingBox, imageSize.width, imageSize.height);
					r = [datum.selectionLayer convertRect:r toLayer:self.view.layer];
					r = CGRectIntersection(r, container);
					if (!CGRectIsEmpty(r))
					{
						[self.view addCursorRect:r cursor:[NSCursor IBeamCursor]];
					}
				}
			}
		}
	}
	return NO;
}

#pragma mark Find

- (NSValue *)range:(NSRange)target withinRanges:(NSArray<NSValue *> *)selectedRanges {
	for (NSValue *rangep in selectedRanges) {
		NSRange range = [rangep rangeValue];
		if (NSLocationInRange(range.location, target)) {
			return rangep;
		}
	}
	return nil;
}

- (NSArray<NSValue *> *)selectedFindRanges
{
	NSMutableArray<NSValue *> *selectedRanges = [NSMutableArray array];
	NSUInteger offset = 0;
	for (OCRDatum *datum in self.datums)
	{
		if (datum.image != nil)
		{
			for (VNRecognizedTextObservation *piece in datum.textPieces)
			{
				NSValue *rangePtr = datum.selectionPieces[piece];
				if (rangePtr != nil)
				{
					NSRange r = [rangePtr rangeValue];
					r.location += offset;
					[selectedRanges addObject:[NSValue valueWithRange:r]];
				}
				NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
				offset += text1.firstObject.string.length + 1;
			}
		}
	}
	return selectedRanges;
}

- (void)setSelectedFindRange:(NSRange)selectedR
{
	NSUInteger offset = 0;
	for (OCRDatum *datum in self.datums)
	{
		datum.selectionPieces = [NSMutableDictionary dictionary];
	}
	if (selectedR.location == NSNotFound) {
		return;
	}
	for (OCRDatum *datum in self.datums)
	{
		if (datum.image != nil)
		{
			for (VNRecognizedTextObservation *piece in datum.textPieces)
			{
				NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
				NSRange allText1 = NSMakeRange(offset, text1.firstObject.string.length);
				if (NSLocationInRange(selectedR.location, allText1)) {
					NSRange localText = selectedR;
					localText.location -= offset;
					NSInteger fullLength = localText.length;
					localText.length = MIN(allText1.length - localText.location, localText.length);
					datum.selectionPieces[piece] = [NSValue valueWithRange:localText];
					[self.view setNeedsDisplay:YES];
					if (fullLength - localText.length <= 1) {
						return;
					} else {
						selectedR.location += localText.length+1;
						selectedR.length -= localText.length+1;
					}
				}
				offset += text1.firstObject.string.length + 1;
			}
		}
	}
}

- (void)scrollFindRangeToVisible:(NSRange)findRange
{
	NSUInteger offset = 0;
	for (OCRDatum *datum in self.datums)
	{
		if (datum.image != nil)
		{
			for (VNRecognizedTextObservation *piece in datum.textPieces)
			{
				NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
				NSRange allText1 = NSMakeRange(offset, text1.firstObject.string.length);
				if (NSLocationInRange(findRange.location, allText1)) {
					findRange.location -= offset;	// Converts the range to textPiece coordinates
					VNRectangleObservation *rectObserved = [text1.firstObject boundingBoxForRange:findRange error:NULL] ?: piece;

					CGSize imageSize = datum.selectionLayer.bounds.size;
					CGRect r = VNImageRectForNormalizedRect(rectObserved.boundingBox, imageSize.width, imageSize.height);
					CGRect viewRect = [datum.selectionLayer convertRect:r toLayer:self.view.layer];
					[self.view scrollRectToVisible:viewRect];
					return;
				}
				offset += text1.firstObject.string.length + 1;
			}
		}
	}
}

#pragma mark Menubar

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (!sIsEnabled) {
		return NO;
	}
	if ([menuItem action] == @selector(copy:))
	{
		BOOL isAnySelected = self.isAnySelected;
		menuItem.title = isAnySelected ? NSLocalizedString(@"Copy Text", @"") : NSLocalizedString(@"Copy", @"");
		return isAnySelected;
	}
	else if ([menuItem action] == @selector(selectAll:))
	{
		if (@available(macOS 10.15, *))
		{
			NSInteger totalTextPiecesCount = self.totalTextPiecesCount;
			return totalTextPiecesCount != 0 && totalTextPiecesCount != self.totalSelectionPiecesCount;
		} else {
			return  NO;
		}
		return YES;
	}
	else if ([menuItem action] == @selector(startSpeaking:))
	{
		if (@available(macOS 10.15, *))
		{
			return self.isAnySelected;
		} else {
			return  NO;
		}
		return YES;
	}
	else if ([menuItem action] == @selector(stopSpeaking:))
	{
		return [sSpeechSynthesizer isSpeaking];
	}
	else if ([menuItem action] == @selector(performOCRFindAction:))
	{
		return [self.delegate.find validateAction:[menuItem tag]];
	}
	return NO;
}

- (IBAction)performOCRFindAction:(id)sender
{
	[self.delegate.find performAction:[sender tag]];
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
		for (OCRDatum *datum in self.datums)
		{
			if (datum.image != nil)
			{
				datum.selectionPieces = [NSMutableDictionary dictionary];
				for (VNRecognizedTextObservation *piece in datum.textPieces)
				{
					NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
					NSRange r = NSMakeRange(0, text1.firstObject.string.length);
					datum.selectionPieces[piece] = [NSValue valueWithRange:r];
				}
			}
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
  if (sIsEnabled && (([sendType isEqual:NSPasteboardTypeString] || [sendType isEqual:NSStringPboardType]) && self.isAnySelected))
	{
    return self;
  }
  return [[self nextResponder] validRequestorForSendType:sendType returnType:returnType];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types
{
  if (sIsEnabled && (([types containsObject:NSPasteboardTypeString] || [types containsObject:NSStringPboardType]) && self.isAnySelected))
	{
    [self copyToPasteboard:pboard];
    return YES;
  }
  return NO;
}

@end
