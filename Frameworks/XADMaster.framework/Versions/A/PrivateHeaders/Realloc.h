#import <Foundation/Foundation.h>

static inline void *Realloc(void *ptr,size_t newsize)
{
	void *newptr=realloc(ptr,newsize);
	if(!newptr)
	{
		free(ptr);
		[NSException raise:NSMallocException format:@"Realloc() failed"];
	}
	return newptr;
}
