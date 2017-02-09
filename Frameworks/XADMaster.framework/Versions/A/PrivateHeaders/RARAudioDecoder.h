#ifndef __RARAUDIODECODER_H__
#define __RARAUDIODECODER_H__

typedef struct RAR20AudioState
{
	int weight1,weight2,weight3,weight4,weight5;
	int delta1,delta2,delta3,delta4;
	int lastdelta;
	int error[11];
	int count;
	int lastbyte;
} RAR20AudioState;

typedef struct RAR30AudioState
{
	int weight1,weight2,weight3,weight4,weight5;
	int delta1,delta2,delta3,delta4;
	int lastdelta;
	int error[7];
	int count;
	int lastbyte;
} RAR30AudioState;

int DecodeRAR20Audio(RAR20AudioState *state,int *channeldelta,int delta);
int DecodeRAR30Audio(RAR30AudioState *state,int delta);

#endif
