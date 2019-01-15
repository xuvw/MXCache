//
//  MXDiskCache.m
//  MXCache
//
//  Created by heke on 2018/12/7.
//  Copyright © 2018 MX. All rights reserved.
//

#import "MXDiskCache.h"
#import "MXStorage.h"

#if __has_include(<MXGCDQueuePool/MXGCDQueuePool.h>)
#import <MXGCDQueuePool/MXGCDQueuePool.h>
#else
#import "MXGCDQueuePool.h"
#endif

#import <pthread.h>

@import QuartzCore;

#define Wait() dispatch_semaphore_wait(self->lock, DISPATCH_TIME_FOREVER)
#define Signal() dispatch_semaphore_signal(self->lock)

//#define Wait() pthread_mutex_lock(&pLock)
//#define Signal() pthread_mutex_unlock(&pLock)

@interface MXDiskCache ()
{
    dispatch_semaphore_t lock;
}
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) MXStorage *storage;

@end

@implementation MXDiskCache

- (nullable instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _path = path;
        _storage = [[MXStorage alloc] initWithPath:_path];
        _maxDiskUsage = NSIntegerMax;
        _maxCacheCount = NSIntegerMax;
        self->lock = dispatch_semaphore_create(1);
        [self checkDiskCache];
    }
    return self;
}

- (instancetype)init __unavailable {
    NSLog(@"init is unavailable, use initWithPath to initialize...");
    return [self initWithPath:@""];
}

- (void)saveDataForKey:(NSData *)data forKey:(NSString *)key {
    if (key.length < 1 || data.length < 1) {
        return;
    }
    
    Wait();
    MXStorageDataItem *item = [[MXStorageDataItem alloc] init];
    item.key = key;
    item.data = data;
    item.create_time = time(NULL);
    [_storage saveItem:item];
    Signal();
}
- (void)saveDataForKey:(NSData *)data forKey:(NSString *)key withCompleteBlock:(nullable void(^)(NSString *key))block {
    if (key.length < 1 || data.length < 1) {
        return;
    }
    [MXGCDQueuePool dispatchAsync:^{
        [self saveDataForKey:data forKey:key];
        if (block) {
            block(key);
        }
    }];
}

- (NSData *)dataForKey:(NSString *)key {
    
    if (!key) {
        return nil;
    }
    
    Wait();
    
    MXStorageDataItem *di = [_storage dataItemForKey:key];
    Signal();
    
    return di.data;
}
- (void)dataForKey:(NSString *)key withCompleteBlock:(nullable void(^)(NSString *key, NSData *data, NSError *error))block {
    if (key.length < 1) {
        if (block) {
            block(key, nil, nil);
        }
    }
    [MXGCDQueuePool dispatchAsync:^{
        if (block) {
            block(key, [self dataForKey:key], nil);
        }
    }];
    return;
}

- (void)removeDataForKey:(NSString *)key {
    if (key.length < 1) {
        return;
    }
    Wait();
    [_storage removeItemForKey:key];
    Signal();
}
- (void)removeDataForKey:(NSString *)key withCompleteBlock:(nullable void(^)(NSString *key))block {
    [MXGCDQueuePool dispatchAsync:^{
        [self removeDataForKey:key];
        if (block) {
            block(key);
        }
    }];
}

- (void)removeAllDatas {
    
    Wait();
    [_storage removeAllData];
    Signal();
}

- (void)removeAllDatasWithCompleteBlock:(void(^)(void))block {
    [MXGCDQueuePool dispatchAsync:^{
        [self removeAllDatas];
        if (block) {
            block();
        }
    }];
}

- (void)removeAllDatasWithProgessBlock:(nullable void(^)(int removeCount, int totalCount))progress
                         completeBlock:(nullable void(^)(BOOL complete))block {
    Wait();
    [_storage removeAllData];
    Signal();
    
    if (block) {
        block(YES);
    }
}

- (void)checkDiskCache {
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)),
                   [MXGCDQueuePool activeQueue],
                   ^{
                       
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf doCheck];
        [strongSelf checkDiskCache];
                       
    });
}

- (void)doCheck {
    [MXGCDQueuePool dispatchAsync:^{
        Wait();
//        NSLog(@"MX.cache: disk cache check on thread:%@", [NSThread currentThread]);
        [self checkDiskUsage];
        [self checkCacheCount];
        Signal();
    }];
}

//线程安全
- (void)checkDiskUsage {
    if (_maxDiskUsage >= NSIntegerMax) {
        return;
    }
    [_storage reduceDataToFitSize:_maxDiskUsage];
}

//线程安全
- (void)checkCacheCount {
    if (_maxCacheCount >= NSIntegerMax) {
        return;
    }
    [_storage reduceDataCountToFitCount:_maxCacheCount];
}

@end
