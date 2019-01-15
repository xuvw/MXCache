#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MXCache.h"
#import "MXDiskCache.h"
#import "MXMemoryCache.h"
#import "MXSandBox.h"
#import "MXStorage.h"

FOUNDATION_EXPORT double MXCacheVersionNumber;
FOUNDATION_EXPORT const unsigned char MXCacheVersionString[];

