//
//  MXLRU.h
//  MXLRU
//
//  Created by heke on 2018/10/7.
//  Copyright © 2019 MX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MXLRU : NSObject

@property (nonatomic, assign) NSInteger maxNodeCount;
@property (nonatomic, assign) NSInteger maxMemoryUsage;

- (void)setData:(NSData *)data forKey:(NSString *)key;
- (NSData *)dataForKey:(NSString *)key;
- (void)removeDataForKey:(NSString *)key;
- (void)clear;

- (NSInteger)getCurrentMemoryUsage;
- (NSInteger)getCurrentNodeCount;
- (float)getCurrentHitRate;

- (void)trim;

@end

NS_ASSUME_NONNULL_END
