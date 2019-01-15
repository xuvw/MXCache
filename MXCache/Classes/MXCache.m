//
//  MXCache.m
//  MXCache
//
//  Created by heke on 2018/12/7.
//  Copyright © 2018 MX. All rights reserved.
//

#import "MXCache.h"
@import QuartzCore;

@interface MXCache ()

@end

@implementation MXCache

- (nullable instancetype)initWithPath:(NSString *)path {
    if (path.length < 1) {
        return nil;
    }
    if (self = [super init]) {
        _path = path;
        _diskCache = [[MXDiskCache alloc] initWithPath:path];
        _diskCache.maxDiskUsage = NSIntegerMax;
        _diskCache.maxCacheCount = NSIntegerMax;
        
        _memoryCache = [[MXMemoryCache alloc] init];
        _memoryCache.maxMemoryUsage = 40 * 1024 * 1024;
        _memoryCache.maxCacheCount = 200;
        _memoryCache.name = @"MX.memory.cache";
    }
    return self;
}

+ (nullable instancetype)cacheWithPath:(NSString*)path {
    return [[self alloc] initWithPath:path];
}

- (instancetype)init __unavailable {
    NSLog(@"init is unavailable, use initWithPath to initialize");
    return [self initWithPath:@""];
}

- (void)saveDataForKey:(NSData *)data forKey:(NSString *)key {
    [_memoryCache saveDataForKey:data forKey:key];
    [_diskCache saveDataForKey:data forKey:key];
}

- (void)saveDataForKey:(NSData *)data forKey:(NSString *)key withCompleteBlock:(nullable void(^)(NSString *key))block {
    [_memoryCache saveDataForKey:data forKey:key];
    [_diskCache saveDataForKey:data forKey:key withCompleteBlock:block];
}

- (NSData *)dataForKey:(NSString *)key {
    NSData *data = [_memoryCache dataForKey:key];
    
    if (data) {
        
        return data;
    }
    
    data = [_diskCache dataForKey:key];
    if (data) {
        [_memoryCache saveDataForKey:data forKey:key];
    }
    return data;
}

- (void)dataForKey:(NSString *)key withCompleteBlock:(nullable void(^)(NSString *key, NSData *data, NSError *error))block {
    NSData *data = [_memoryCache dataForKey:key];
    if (data) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(key, data, nil);
        });
        
        return;
    }
    __weak typeof(self)weakSelf = self;
    [_diskCache dataForKey:key withCompleteBlock:^(NSString * _Nonnull key, NSData * _Nonnull data, NSError * _Nonnull error) {
        
        block(key, data, nil);
        NSLog(@"!!!!!!!-----%@=%@",key, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        if (data) {
            [weakSelf.memoryCache saveDataForKey:data forKey:key];
        }
    }];
}

- (void)removeDataForKey:(NSString *)key {
    [_memoryCache removeDataForKey:key];
    [_diskCache removeDataForKey:key];
}

- (void)removeDataForKey:(NSString *)key withCompleteBlock:(nullable void(^)(NSString *key))block {
    [_memoryCache removeDataForKey:key];
    [_diskCache removeDataForKey:key withCompleteBlock:block];
}

- (void)removeAllDatas {
    [_memoryCache removeAllDatas];
    [_diskCache removeAllDatas];
}

- (void)removeAllDatasWithCompleteBlock:(void(^)(void))block {
    [_memoryCache removeAllDatas];
    [_diskCache removeAllDatasWithCompleteBlock:block];
}

- (void)removeAllDatasWithProgessBlock:(nullable void(^)(int removeCount, int totalCount))progress
                         completeBlock:(nullable void(^)(BOOL complete))block {
    [_diskCache removeAllDatasWithProgessBlock:progress completeBlock:block];
}

@end
