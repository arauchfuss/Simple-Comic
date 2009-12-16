/*	
 Copyright (c) 2006-2009 Dancing Tortoise Software
 Created by Alexander Rauchfuss
 
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
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
 OTHER DEALINGS IN THE SOFTWARE.
 
 DTPolishedProgressBar.h
*/


#import <Cocoa/Cocoa.h>

/*
	Configurable progress bar.  Allows the setting of various style attributes.
	Progress direction can be set.
*/
@interface DTPolishedProgressBar : NSView
{
	int maxValue;		/* The maximum value of the progress bar. */
	int currentValue;	/* The progress bar is filled to this level. */
	BOOL leftToRight;	/* The direction of the porgress bar. */
	NSRect progressRect; /* This is the section of the view. Users can mouse over and click here. */
	float horizontalMargin; /* How much room is given for the text on either side. */
	float cornerRadius;
	
	NSGradient * emptyGradient; /* This is the color of the unfilled bar. */
	NSGradient * barGradient;	/* The color of the filled bar. */
	NSGradient * shadowGradient; /* */
	NSColor * highlightColor;	/* The highlight on the bottom lip of the bar. */
	NSDictionary * numberStyle; /* The font attributes of the progress numbers. */
}

/*
 List of replacements for the highcontrast flag
 Highlight: NSColor if nil then layout is slightly shifted.
 barFill: This is the gradient of the empty portion of the progress bar
 progressFill: This is the gradient of the filled portion of the pr ituogress bar.
 shadow:  This is the gradient that give the illusion of depth.
 textStyle: Dictionary of string attributes.
 */

@property (assign) BOOL leftToRight;
@property (assign) int maxValue;
@property (assign) int currentValue;

@property (assign) NSRect progressRect;
@property (assign) float horizontalMargin;

@property (assign) float cornerRadius;
@property (retain) NSGradient * emptyGradient;
@property (retain) NSGradient * barGradient;
@property (retain) NSGradient * shadowGradient;
@property (retain) NSColor * highlightColor;
@property (retain) NSDictionary * numberStyle;

- (int)indexForPoint:(NSPoint)point;

@end
