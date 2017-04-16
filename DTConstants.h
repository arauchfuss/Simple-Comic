//
//  DTConstants.h
//  Simple Comic 2
//
//  Created by Alexander Rauchfuss on 7/12/14.
//  Copyright (c) 2014 Alexander Rauchfuss. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const DTPageLayout;
extern NSString *const DTPageOrder;
extern NSString *const DTPageScaling;

extern NSString *const DTBackgroundColor;
extern NSString *const DTSessionRestore;


enum pageLayoutMode {
    SinglePage,
    TwoPage,
    VerticalStream,
    HorizontalStream
};

enum pageOrderMode {
    LeftRight,
    RightLeft
};

enum pageScalingMode {
    NoScaling,
    FitWindowScaling,
    HorizontalWindowScaling,
    VerticalWindowScaling
};
