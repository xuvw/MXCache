//
//  MXMemoryCache.h
//  MXCache
//
//  Created by heke on 2018/12/7.
//  Copyright © 2018 MX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MXMemoryCache : NSObject

@property (nonatomic, copy)   NSString  *name;
/**
 default:40MB
 */
@property (nonatomic, assign) NSInteger maxMemoryUsage;
@property (nonatomic, assign) NSInteger currentMemoryUsage;
/**
 default:200
 */
@property (nonatomic, assign) NSInteger maxCacheCount;
@property (nonatomic, assign) NSInteger currentCacheCount;

/**
 default:YES
 */
@property (nonatomic, assign) BOOL clearOnMemoryWarnning;
/**
 default:YES
 */
@property (nonatomic, assign) BOOL clearInBackground;

- (void)saveDataForKey:(NSData *)data forKey:(NSString *)key;

- (NSData *)dataForKey:(NSString *)key;

- (void)removeDataForKey:(NSString *)key;

- (void)removeAllDatas;

@end

NS_ASSUME_NONNULL_END
