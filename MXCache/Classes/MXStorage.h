//
//  MXStorage.h
//  MXCache
//
//  Created by heke on 2018/12/28.
//  Copyright © 2018 MX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MXStorageDataItem : NSObject

@property (nonatomic, copy)   NSString  *key;
@property (nonatomic, strong, nullable) NSData    *data;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, assign) NSInteger create_time;
@property (nonatomic, assign) NSInteger last_visit_time;
@property (nonatomic, copy)   NSString  *exts;

@end

@interface MXStorage : NSObject

@property (nonatomic, readonly, copy) NSString *path;

//default:20KB
@property (nonatomic, assign) NSInteger saveToDBThreshold;

- (instancetype)initWithPath:(NSString *)path;

#pragma mark - save data
- (BOOL)saveItem:(MXStorageDataItem *)item;
//- (void)saveItemWithData:(NSData *)data forKey:(NSString *)key;

#pragma mark - get data
- (MXStorageDataItem *)dataItemForKey:(NSString *)key;
//- (NSArray<MXStorageDataItem *> *)dataItemsForKeys:(NSArray<NSString *> *)keys;
//- (MXStorageDataItem *)dataInfoForKey:(NSString *)key;
//- (NSData *)dataForKey:(NSString *)key;

#pragma mark - remove data
- (BOOL)removeItemForKey:(NSString *)key;
- (BOOL)removeItemsForKeys:(NSArray<NSString *> *)keys;
- (BOOL)removeAllData;

#pragma mark - storage info fetch
- (BOOL)itemExistsForKey:(NSString *)key;
- (NSInteger)itemCount;
- (NSInteger)totalSize;

#pragma mark - disk check
- (void)reduceDataToFitSize:(NSInteger)size;
- (void)reduceDataCountToFitCount:(NSInteger)size;

@end

NS_ASSUME_NONNULL_END
