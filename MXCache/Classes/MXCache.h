//
//  MXCache.h
//  MXCache
//
//  Created by heke on 2018/12/7.
//  Copyright © 2018 MX. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<MXCache/MXCache.h>)
    FOUNDATION_EXPORT double MXCacheVersionNumber;
    FOUNDATION_EXPORT const unsigned char MXCacheVersionString[];
    #import <MXCache/MXDiskCache.h>
    #import <MXCache/MXMemoryCache.h>
    #import <MXCache/MXStorage.h>
#else
    #import "MXDiskCache.h"
    #import "MXMemoryCache.h"
    #import "MXStorage.h"
#endif

extern NSInteger const OneMegabytes;

NS_ASSUME_NONNULL_BEGIN

@interface MXCache : NSObject

@property (nonatomic, readonly, copy) NSString *path;
@property (nonatomic, readonly, strong) MXDiskCache *diskCache;
@property (nonatomic, readonly, strong) MXMemoryCache *memoryCache;

- (nullable instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;
+ (nullable instancetype)cacheWithPath:(NSString*)path;

- (instancetype)init __unavailable;
+ (instancetype)new __unavailable;

- (void)saveDataForKey:(NSData *)data forKey:(NSString *)key;
- (void)saveDataForKey:(NSData *)data forKey:(NSString *)key withCompleteBlock:(nullable void(^)(NSString *key))block;

- (NSData *)dataForKey:(NSString *)key;
- (void)dataForKey:(NSString *)key withCompleteBlock:(nullable void(^)(NSString *key, NSData *data, NSError *error))block;

- (void)removeDataForKey:(NSString *)key;
- (void)removeDataForKey:(NSString *)key withCompleteBlock:(nullable void(^)(NSString *key))block;

- (void)removeAllDatas;
- (void)removeAllDatasWithCompleteBlock:(void(^)(void))block;

- (void)removeAllDatasWithProgessBlock:(nullable void(^)(int removeCount, int totalCount))progress
                         completeBlock:(nullable void(^)(BOOL complete))block;

@property (nonatomic, readonly, assign)NSUInteger memoryCapacity;

@property (nonatomic, readonly, assign)NSUInteger diskCapacity;

@property (readonly) NSUInteger currentMemoryUsage;

@property (readonly) NSUInteger currentDiskUsage;

@end

NS_ASSUME_NONNULL_END
