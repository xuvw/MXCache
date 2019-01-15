//
//  MXDiskCache.h
//  MXCache
//
//  Created by heke on 2018/12/7.
//  Copyright © 2018 MX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface MXDiskCache : NSObject

/**
 default:NSIntegerMaxMB
 */
@property (nonatomic, assign) NSInteger maxDiskUsage;
/**
 default:NSIntegerMax
 */
@property (nonatomic, assign) NSInteger maxCacheCount;

- (nullable instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;
- (instancetype)init __unavailable;
+ (instancetype)new  __unavailable;

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

@end

NS_ASSUME_NONNULL_END
