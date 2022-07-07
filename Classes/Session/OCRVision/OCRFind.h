//  OCRFind.h
//
//  Created by David Phillip Oster on 6/10/22. license.txt applies.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class OCRTracker;
@class OCRFindViewController;
@class VNRecognizedTextObservation;

@protocol OCRFindDelegate;

/// Does the actual finding. The controller of this owns this. This implements the OCRFindEngine protocol.
@interface OCRFind : NSObject

/// The delegate owns this and the tracker.
@property(weak) id<OCRFindDelegate> delegate;

/// Perform an action on the Find submenu,
- (void)performAction:(NSTextFinderAction)op;

/// Perform an menu item on the Find submenu,
- (BOOL)validateAction:(NSTextFinderAction)op;

@end

@protocol OCRFindDelegate <NSObject>

@property(readonly) OCRTracker *tracker;

@property(readonly) id<NSTextFinderBarContainer> findBarContainer;

@property(readonly) NSInteger findCount;

/// OCRFind can set this to move the U.I. to a different page.
@property NSInteger findIndex;

///  Ask the document to cancel any OCR operation in progress and call the observationsForFindIndex: completion.
- (void)cancelObservations;

/// Ask the document for the text observtions for the page at index.
- (void)observationsForFindIndex:(NSInteger)index completion:(void (^)(NSArray<VNRecognizedTextObservation *> *pieces)) completion;

@end

NS_ASSUME_NONNULL_END
