//  OCRSelectionLayer.h
//
//  Created by David Phillip Oster on 5/26/2022 Apache Version 2 open source license.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// The layer that displays the hilite of the selected text. For internal use by OCRTracker.
API_AVAILABLE(macos(10.15))
@interface OCRSelectionLayer : CALayer
- (instancetype)initWithObservations:(NSArray *)observations selection:(NSDictionary *)selection imageLayer:(CALayer *)imageLayer;
@end

NS_ASSUME_NONNULL_END
