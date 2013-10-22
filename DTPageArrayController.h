//
//  DTPageArrayController.h
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 6/11/08.
//  Copyright 2008 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DTManagedPage;

@interface DTPageArrayController : NSArrayController
{
	BOOL twoPage;
	BOOL leftToRight;
}

@property (assign) BOOL leftToRight;
@property (assign) BOOL twoPage;

@property (readonly) DTManagedPage * firstPage;
@property (readonly) DTManagedPage * secondPage;

+ (NSSet *)keyPathsForValuesAffectingFirstPage;
+ (NSSet *)keyPathsForValuesAffectingSecondPage;

- (void)selectFirst;
- (void)selectLast;

- (IBAction)pageRight:(id)sender;
- (IBAction)pageLeft:(id)sender;
- (IBAction)pageTurn:(id)sender;
- (IBAction)shiftPageRight:(id)sender;
- (IBAction)shiftPageLeft:(id)sender;
- (IBAction)skipRight:(id)sender;

- (BOOL)canSelectLeft;
- (BOOL)canSelectRight;

@end
