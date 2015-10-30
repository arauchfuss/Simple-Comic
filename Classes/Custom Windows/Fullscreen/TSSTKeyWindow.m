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
 
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
	OTHER DEALINGS IN THE SOFTWARE.
	
	Simple Comic
	TSSTKeyWindow.m
*/



#import "TSSTKeyWindow.h"
#import "TSSTSessionWindowController.h"



@implementation TSSTKeyWindow



- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect: contentRect styleMask: NSBorderlessWindowMask backing: bufferingType defer: flag];
    
    if(self)
    {
        [self setOpaque: NO];
    }
    return self;
}



- (BOOL)canBecomeKeyWindow
{
	return YES;
}



- (void)performClose:(id)sender
{
    [[self delegate] windowShouldClose: self];
}



- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
    return ([anItem action] == @selector(performClose:)) ? YES : NO;
}



@end



@implementation TSSTTransparentView


- (void)drawRect:(NSRect)rect
{
    [[NSColor colorWithCalibratedWhite: 0 alpha: 0.7] set];
    NSRectFill(rect);
}



@end


