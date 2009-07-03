/*	
	Copyright (c) 2006 Dancing Tortoise Software
 
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
	TSSTImageUtilities.m
*/


#import "TSSTImageUtilities.h"


CGSize scaleSize(CGSize aSize, float scale)
{
	CGSize outputSize;
	outputSize.width = (aSize.width * scale);
	outputSize.height = (aSize.height * scale);
	return outputSize;
}


CGSize fitSizeInSize(CGSize constraint, CGSize size)
{
    if(size.width < constraint.width || size.height < constraint.height)
    {
        if( constraint.height / constraint.width > size.width / size.width)
        {
            size = scaleSize(size, size.height / constraint.height);
        }
        else
        {
            size = scaleSize(size, size.width / constraint.width);
        }
    }
    
    return size;
}


