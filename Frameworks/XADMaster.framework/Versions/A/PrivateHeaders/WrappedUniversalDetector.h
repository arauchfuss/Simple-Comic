#ifndef __WrappedUniversalDetector_h__
#define __WrappedUniversalDetector_h__

#ifdef __cplusplus
extern "C" {
#endif

void *AllocUniversalDetector();
void FreeUniversalDetector(void *detectorptr);
void UniversalDetectorHandleData(void *detectorptr,const char *data,int length);
void UniversalDetectorReset(void *detectorptr);
int UniversalDetectorDone(void *detectorptr);
const char *UniversalDetectorCharset(void *detectorptr,float *confidence);


#ifdef __cplusplus
}
#endif

#endif
