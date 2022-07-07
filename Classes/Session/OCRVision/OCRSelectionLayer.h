//  OCRSelectionLayer.h
//
//  Created by David Phillip Oster on 5/26/2022  license.txt applies.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

/// The layer that displays the hilite of the selected text. For internal use by OCRTracker.
API_AVAILABLE(macos(10.15))
@interface OCRSelectionLayer : CAShapeLayer
- (instancetype)initWithObservations:(NSArray *)observations selection:(NSDictionary *)selection imageLayer:(CALayer *)imageLayer;
@end

NS_ASSUME_NONNULL_END
