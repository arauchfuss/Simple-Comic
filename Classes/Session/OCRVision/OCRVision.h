//  OCRVision.h
//
//  Created by David Phillip Oster on 5/19/2022  license.txt applies.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Live text recognition language. Set to empty string to disable live text recognition. in User Defaults.
extern NSString *const OCRLanguageKey;

// OCRedTextView use this NSError Domain
extern NSErrorDomain const OCRVisionDomain;

typedef NS_ERROR_ENUM(OCRVisionDomain, OCRVisionError) {
	OCRVisionErrUnrecognized = 1,
	OCRVisionErrNoCreate
};

@class VNRecognizedTextObservation;

/// When the  OCR is complete, it will pass your continuation block an object that responds to this protocol.
@protocol OCRVisionResults <NSObject>

/// all the text on the page.
@property(readonly) NSString *allText;

/// non-nil if an error occurred OCR'ing the image.
@property(readonly, nullable) NSError *ocrError;

/// Once an OCR operation completes, the individual lines of text.
@property(readonly) NSArray<VNRecognizedTextObservation *> *textObservations;

@end

/// Wrap up the Vision OCR framework in a  simple API
API_AVAILABLE(macos(10.15))
@interface OCRVision : NSObject

/// The list of languages the VisionFramework will accept. en_US is the default. Empty array means the VisionFramework is not available.
@property(class, readonly) NSArray<NSString *> *ocrLanguages;

/// The language the VisionFramework will use. from the ocrLanguage in UserDefaults
@property(class, readonly) NSString *ocrLanguage;


/// Run the ocr engine on the image in the default language. When it's done, call the completion passing an object that implements the OCRVisionResults protocol
///
///  Note: does its work on a background concurrent GCD queue. Completion is called on that queue.
///
/// @param image - the image to OCR
/// @param completion - a block passed an object that corresponds to the OCRVision protocol.
- (void)ocrImage:(NSImage *)image completion:(void (^)(id<OCRVisionResults> _Nonnull ocrResults))completion;

/// Run the ocr engine on the image in the default language. When it's done, call the completion passing an object that implements the OCRVisionResults protocol
///
///  Note: does its work on a background concurrent GCD queue. Completion is called on that queue.
///
/// @param cgImage - the image to OCR
/// @param completion - a block passed an object that corresponds to the OCRVision protocol.
- (void)ocrCGImage:(CGImageRef)cgImage completion:(void (^)(id<OCRVisionResults> _Nonnull ocrResults))completion;

/// if a OCR task is currently running, attempt to cancel it. Always safe to call.
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
