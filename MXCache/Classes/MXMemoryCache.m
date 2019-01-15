//
//  MXMemoryCache.m
//  MXCache
//
//  Created by heke on 2018/12/7.
//  Copyright © 2018 MX. All rights reserved.
//

#import "MXMemoryCache.h"

#if __has_include(<MXLRU/MXLRU.h>)
#import <MXLRU/MXLRU.h>
#else
#import "MXLRU.h"
#endif

#if __has_include(<MXGCDQueuePool/MXGCDQueuePool.h>)
#import <MXGCDQueuePool/MXGCDQueuePool.h>
#else
#import "MXGCDQueuePool.h"
#endif

@import UIKit;

@interface MXMemoryCache ()

@property (nonatomic, strong) MXLRU *LRU;

@end

@implementation MXMemoryCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        _clearOnMemoryWarnning = YES;
        _clearInBackground = YES;
        
        _maxMemoryUsage = 40 * 1024 * 1024;
        _maxCacheCount = 200;
        
        _LRU = [[MXLRU alloc] init];
        _LRU.maxMemoryUsage = _maxMemoryUsage;
        _LRU.maxNodeCount = _maxCacheCount;
        
        [self openNotificationMonitor];
        [self checkMemoryCache];
    }
    return self;
}

- (void)setMaxMemoryUsage:(NSInteger)maxMemoryUsage {
    _maxMemoryUsage = maxMemoryUsage;
    _LRU.maxMemoryUsage = maxMemoryUsage;
}

- (void)setMaxCacheCount:(NSInteger)maxCacheCount {
    _maxCacheCount = maxCacheCount;
    _LRU.maxNodeCount = maxCacheCount;
}

- (NSInteger)currentMemoryUsage {
    return [_LRU getCurrentMemoryUsage];
}

- (NSInteger)currentCacheCount {
    return [_LRU getCurrentNodeCount];
}

- (void)saveDataForKey:(NSData *)data forKey:(NSString *)key {
    [_LRU setData:data forKey:key];
}

- (NSData *)dataForKey:(NSString *)key {
    return [_LRU dataForKey:key];
}

- (void)removeDataForKey:(NSString *)key {
    [_LRU removeDataForKey:key];
}

- (void)removeAllDatas {
    [_LRU clear];
}

- (void)openNotificationMonitor {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)DidReceiveMemoryWarning:(NSNotification *)aNotification {
    if (_clearOnMemoryWarnning) {
        [_LRU clear];
    }
}

- (void)DidEnterBackground:(NSNotification *)aNotification {
    if (_clearInBackground) {
        [_LRU clear];
    }
}

- (void)checkMemoryCache {
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   [MXGCDQueuePool activeQueue],
                   ^{
                       
                       __strong typeof(weakSelf)strongSelf = weakSelf;
                       [strongSelf doCheck];
                       [strongSelf checkMemoryCache];
                       
                   });
}

- (void)doCheck {
    
//    NSLog(@"MX.cache: memory cache check on thread:%@", [NSThread currentThread]);
    [_LRU trim];
}

@end
