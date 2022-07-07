//  OCRVision.h
//
//  Created by David Phillip Oster on 5/19/2022.  license.txt applies.
//

#import "OCRVision.h"

#import <Vision/Vision.h>

NSString *const OCRLanguageKey = @"OCRLanguageKey";

static NSString *sOCRLanguage;

static NSArray<NSString *> *sOCRLanguages;

// Omit any VNRecognizedTextObservation that have a confidence value below this threshold.
static CGFloat OCRConfidence = 0.5;

// ocrErrors use this NSError Domain
NSErrorDomain const OCRVisionDomain = @"OCRVisionDomain";

/// Rather than allocate a new object to pass the results, just make the OCRVision object do double duty.
@interface OCRVision()<OCRVisionResults>

/// non nil while processing the request
///
/// Assumes caller will create a new OCRVision for each image to analyze.
@property(nullable) VNRecognizeTextRequest *activeTextRequest;

@property(readwrite) NSArray<VNRecognizedTextObservation *> *textObservations;
@property(readwrite, nullable, setter=setOCRError:) NSError *ocrError;
@end

@implementation OCRVision

+ (void)initialize
{
	[super initialize];
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *defaultOCRLanguage = @"";	// i.e., off.
		if (@available(macOS 12.0, *))
		{
			defaultOCRLanguage = @"en-US";
		}
		NSDictionary* standardDefaults =
		@{
			OCRLanguageKey: defaultOCRLanguage,
		};
		NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
		[defaults registerDefaults: standardDefaults];
		NSUInteger revision = VNRecognizeTextRequestRevision1;
#if defined(MAC_OS_VERSION_13_0) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_VERSION_13_0
#warn "if you can see this, it's time to remove the #if."
			if (@available(macOS 13.0, *))
			{
				revision = VNRecognizeTextRequestRevision3;
			} else
#endif
		if (@available(macOS 11.0, *))
		{
			revision = VNRecognizeTextRequestRevision2;
		}
		if (@available(macOS 12.0, *))
		{
			VNRecognizeTextRequest *textRequest = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error){}];
			sOCRLanguages = [textRequest supportedRecognitionLanguagesAndReturnError:nil];
		} else {
			sOCRLanguages = [VNRecognizeTextRequest supportedRecognitionLanguagesForTextRecognitionLevel:VNRequestTextRecognitionLevelAccurate revision:revision error:NULL];
		}
		sOCRLanguage = sOCRLanguages.firstObject ?: @"";
	});
}

+ (NSArray<NSString *> *)ocrLanguages
{
	if (nil == sOCRLanguages){ return @[]; }
	return sOCRLanguages;
}

+ (NSString *)ocrLanguage
{
	NSString *defaultLanguage = [[NSUserDefaults standardUserDefaults] stringForKey:OCRLanguageKey];
	if (defaultLanguage != nil && [self.ocrLanguages containsObject:defaultLanguage]) {
		return defaultLanguage;
	}
	return sOCRLanguage;
}

#pragma mark OCR

- (void)callCompletion:(void (^)(id<OCRVisionResults> _Nonnull))completion
					observations:(NSArray<VNRecognizedTextObservation *> *)observations
								 error:(NSError *)error
{
	self.textObservations = observations;
	self.ocrError = error;
	completion(self);
	self.textObservations = @[];
	self.ocrError = nil;
}

- (NSString *)allText
{
	NSMutableArray *a = [NSMutableArray array];
	for (VNRecognizedTextObservation *piece in self.textObservations)
	{
		NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
		[a addObject:text1.firstObject.string];
	}
	return [a componentsJoinedByString:@"\n"];
}


/// Called by VNRecognizeTextRequest to process the result.
/// Filter the textObservations that includes actual text, and store in self.textObservations.
///
///  Since this is called on a worker queue, it delivers results on the main queue.
///
/// @param request - The VNRecognizeTextRequest
/// @param error - if non-nil, the VNRecognizeTextRequest is reporting an error.
- (void)handleTextRequest:(nullable VNRequest *)request
							 completion:(void (^)(id<OCRVisionResults> _Nonnull))completion
										error:(nullable NSError *)error
{
	if (error)
	{
		[self callCompletion:completion observations:@[] error:error];
	}
	else if ([request isKindOfClass:[VNRecognizeTextRequest class]])
	{
		VNRecognizeTextRequest *textRequests = (VNRecognizeTextRequest *)request;
		if (textRequests == self.activeTextRequest)
		{
			self.activeTextRequest = nil;
		}
		// Remove the low confidence recognitions.
		NSMutableArray<VNRecognizedTextObservation*> *results = [NSMutableArray array];
		for (VNRecognizedTextObservation *observation in textRequests.results)
		{
            NSArray<VNRecognizedText *> *text1 = [observation topCandidates:1];
			if (OCRConfidence <= observation.confidence && text1.count != 0) {
				[results addObject:observation];
			}
		}
		[self callCompletion:completion observations:results error:nil];
	} else {
		NSString *desc = @"Unrecognized text request";
		NSError *err = [NSError errorWithDomain:@""
																			 code:OCRVisionErrUnrecognized
																	 userInfo:@{NSLocalizedDescriptionKey : desc}];
		[self callCompletion:completion observations:@[] error:err];
	}
}

- (void)ocrCGImage:(CGImageRef)cgImage completion:(void (^)(id<OCRVisionResults> _Nonnull))completion
{
  __weak typeof(self) weakSelf = self;
  VNRecognizeTextRequest *textRequest =
      [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error)
			{
				[weakSelf handleTextRequest:request completion:completion error:error];
			}];
  if (textRequest)
  {
		NSString *ocrLanguage = [[self class] ocrLanguage];
		if (ocrLanguage.length != 0)
		{
			textRequest.recognitionLanguages = @[ocrLanguage];
			textRequest.usesLanguageCorrection = YES;
#if defined(MAC_OS_VERSION_13_0) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_VERSION_13_0
#warn "if you can see this, it's time to remove the #if."
			if (@available(macOS 13.0, *))
			{
				textRequest.automaticallyDetectsLanguage = YES;
			}
#endif
		}
		NSError *error = nil;
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}];
    self.activeTextRequest = textRequest;
		if (![handler performRequests:@[textRequest] error:&error])
		{
			[weakSelf callCompletion:completion observations:@[] error:error];
		}
  } else {
		NSString *desc = @"Could not create text request";
		NSError *err = [NSError errorWithDomain:OCRVisionDomain
																			 code:OCRVisionErrNoCreate
																	 userInfo:@{NSLocalizedDescriptionKey : desc}];
			[self callCompletion:completion observations:@[] error:err];
  }
}

- (void)ocrImage:(NSImage *)image completion:(void (^)(id<OCRVisionResults> _Nonnull))completion
{
	NSData *imageData = image.TIFFRepresentation;
	if(imageData != nil)
	{
		CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
		if (imageSource != nil)
		{
			CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
			if (imageRef != nil)
			{
				[self ocrCGImage:imageRef completion:completion];
				CFRelease(imageRef);
			}
			CFRelease(imageSource);
		}
	}
}

- (void)cancel
{
	[self.activeTextRequest cancel];
}

@end
