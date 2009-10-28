#import <Foundation/Foundation.h>

uint32_t XADCRC(uint32_t prevcrc,uint8_t byte,const uint32_t *table);
uint32_t XADCalculateCRC(uint32_t prevcrc,const uint8_t *buffer,int length,const uint32_t *table);

int XADUnReverseCRC16(int val);

extern const uint32_t XADCRCTable_a001[256];
extern const uint32_t XADCRCReverseTable_1021[256];
extern const uint32_t XADCRCTable_edb88320[256];
