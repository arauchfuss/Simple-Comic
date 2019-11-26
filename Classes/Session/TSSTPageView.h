/*
	Copyright (c) 2006-2009 Dancing Tortoise Software

	Permission is hereby granted, free of charge, to any person
	obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use,
	copy, modify, merge, publish, distribute, sublicense, and/or
	sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following
	conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	Simple Comic
	TSSTPageView.h
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@class TSSTSessionWindowController;

@protocol DTPageSelectionProtocol <NSObject>

@property (readonly) BOOL pageSelectionInProgress;
@property (readonly) BOOL pageSelectionCanCrop;
- (void)selectedPage:(NSInteger)index withCropRect:(NSRect)crop;
- (BOOL)canSelectPageIndex:(NSInteger)index;
- (void)cancelPageSelection;

@end

typedef NS_ENUM(NSInteger, DTPageScaling) {
	DTPageScalingOriginal = 0,
	DTPageScalingToWindow = 1,
	DTPageScalingToWidth = 2,
};

@protocol DTPageLayoutProtocol <NSObject>

@property (readonly) DTPageScaling pageScaling;
@property (readonly) BOOL leftToRightOrder;
@property (readonly) BOOL singlePageLayout;

@end

@protocol DTPageSourceProtocol <NSObject>

@property (readonly, nullable, copy) NSImage *pageOne;
@property (readonly, nullable, copy) NSImage *pageTwo;

@end



/*!
	Composites one or two images to the screen, making sure that they
	are horizontally alligned.
	None of the logic involving the aspect ratios of the images is
	in this class.
 */
@interface TSSTPageView : NSView

@property (nonatomic, assign) NSInteger rotation;
@property (weak) IBOutlet TSSTSessionWindowController * sessionController;


/*!  This is where it all begins sets the two pages.
    Starts any animations
    Calls resize view
    Calls \c correctViewPoint */
- (void)setFirstPage:(nullable NSImage *)first secondPageImage:(nullable NSImage *)second;


/*!  Finds the size of the pages that are to be renedered.
    This includes minor scaling to equalize the height of facing pages. */
- (NSSize)combinedImageSizeForZoom:(CGFloat)level;


/*!  If the view are is larger than the display area
    then drag scrolling is available. */
@property (readonly) BOOL dragIsPossible;


/*!  This is used by the image loupe.  Grabs the portion of the pages
    displayed that fall within "rect." The origin of the argument
    is centered instead of at the bottom left. */
- (nullable NSImage *)imageInRect:(NSRect)rect;


/*!  This is the actual rectangle within which the pages are rendered.
    Handy to know for various reasons. */
@property (readonly) NSRect imageBounds;


/*! This method scrolls the views so that the proper
    corner is displayed if the pages rendered are
    larger than the display area. */
- (void)correctViewPoint;


/*!  Resizes the view based on the current scaling method and the
    selected images. */
- (void)resizeView;

/*! Used to find the click area for page selection */
- (NSRect)pageSelectionRect:(NSInteger)selection;

/*!	Concatinates an affine transform to the context.
	This is what enables the page rotation. */
- (void)rotationTransformWithFrame:(NSRect)rect;

@property (readonly) BOOL horizontalScrollIsPossible;
@property (readonly) BOOL verticalScrollIsPossible;

// Timers
- (void)startAnimationForImage:(nullable NSImage *)image;
- (void)animateImage:(NSTimer *)timer;

/*	My rather crappy smooth scrolling timer.
	It does allow for multi axis keyboard scrolling though which is pretty cool. */
- (void)scroll:(NSTimer *)timer;

- (void)pageUp;
- (void)pageDown;

@property (readonly) NSRect imageCropRectangle;

@end

NS_ASSUME_NONNULL_END
