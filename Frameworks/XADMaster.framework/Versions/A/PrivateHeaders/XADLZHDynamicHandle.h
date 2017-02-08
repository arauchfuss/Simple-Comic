#import "XADLZSSHandle.h"
#import "XADPrefixCode.h"

typedef struct XADLZHDynamicNode XADLZHDynamicNode;

struct XADLZHDynamicNode
{
	XADLZHDynamicNode *parent,*leftchild,*rightchild;
	int index,freq,value;
};

@interface XADLZHDynamicHandle:XADLZSSHandle
{
	XADPrefixCode *distancecode;
	XADLZHDynamicNode *nodes[314*2-1],nodestorage[314*2-1];
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(void)dealloc;

-(void)resetLZSSHandle;
-(int)nextLiteralOrOffset:(int *)offset andLength:(int *)length atPosition:(off_t)pos;

-(void)updateNode:(XADLZHDynamicNode *)node;
-(void)rearrangeNode:(XADLZHDynamicNode *)node;
-(void)reconstructTree;

@end
