//
//  MXStorage.m
//  MXCache
//
//  Created by heke on 2018/12/28.
//  Copyright © 2018 MX. All rights reserved.
//

#import "MXStorage.h"

#if __has_include(<FMDB/FMDB.h>)
#import <FMDB/FMDB.h>
#else
#import "FMDB.h"
#endif

@import QuartzCore;

@implementation MXStorageDataItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.key = @"";
        self.data = nil;
        self.size = 0;
        self.create_time = 0;
        self.last_visit_time = 0;
        self.exts = @"";
    }
    return self;
}

- (void)setExts:(NSString *)exts {
    _exts = exts;
    if (!exts) {
        _exts = @"";
    }
}

- (void)setKey:(NSString *)key {
    _key = key;
    if (!key) {
        _key = @"";
    }
}

- (void)setData:(NSData *)data {
    _data = data;
    _size = data.length;
}

@end

/**
 缓存元数据表：
 CREATE TABLE IF NOT EXISTS cache_meta_info(
 key PRIMARY KEY TEXT,
 size INTEGER DEFAULT 0,
 create_time INTEGER DEFAULT 0,
 last_visit_time INTEGER DEFAULT 0,
 exts TEXT DEFAULT '');
 CREATE UNIQUE INDEX IF NOT EXISTS key_index ON cache_meta_info(key);
 */
NSString *const cache_meta_info = @"PRAGMA journal_mode = WAL;"
//"PRAGMA synchronous = OFF;"
//"PRAGMA cache_size = 2097152;"
"CREATE TABLE IF NOT EXISTS cache_meta_info("
"key             TEXT PRIMARY KEY,"
"size            INTEGER DEFAULT 0,"
"data            BLOB DEFAULT NULL,"
"create_time     INTEGER DEFAULT 0,"
"last_visit_time INTEGER DEFAULT 0,"
"exts            TEXT    DEFAULT '');"
"CREATE INDEX IF NOT EXISTS cache_meta_info_index_last_visit_time ON cache_meta_info(last_visit_time);"
"CREATE UNIQUE INDEX IF NOT EXISTS cache_meta_info_index_key ON cache_meta_info(key);";

NSString *const cache_db_name =  @"MX.cache.db";
NSString *const cache_data_dir = @"MX.cache.data";
NSString *const cache_trash_dir = @"MX.cache.trash";

@interface MXStorage ()
{
    NSString *dbPath;
    NSString *dataPath;
    NSString *trashPath;
}

@property (nonatomic, strong) FMDatabase *dbHandle;
@property (nonatomic, weak)   NSFileManager *fileManager;

@end

@implementation MXStorage

- (instancetype)initWithPath:(NSString *)path {
    
    if (self = [super init]) {
        
        _path     = path;
        dbPath    = [path stringByAppendingPathComponent:cache_db_name];
        dataPath  = [path stringByAppendingPathComponent:cache_data_dir];
        trashPath = [path stringByAppendingPathComponent:cache_trash_dir];
        _saveToDBThreshold = 20 * 1024;//20KB
        
        if ([self createCacheDouments] && [self createDB]) {
            
            return self;
        }else {
            
            [self clearCache];
            if ([self createCacheDouments] && [self createDB]) {
                
                return self;
            }
            NSLog(@"MX.cache: MXStorage init failed");
            return nil;
        }
    }
    NSLog(@"MX.cache: MXStorage init failed");
    return nil;
}

- (void)dealloc
{
    if (_dbHandle && _dbHandle.isOpen) {
        [_dbHandle close];
    }
}

#pragma mark - CRUD operation
#pragma mark - save data
- (BOOL)saveItem:(MXStorageDataItem *)item {
    
    if (item.key.length < 1 || item.size < 1) {
        return NO;
    }
    if (_dbHandle.isOpen || [_dbHandle open]) {
        
        item.create_time = time(NULL);
        BOOL result = NO;
        if (item.size <= _saveToDBThreshold) {
            
            result = [_dbHandle executeUpdate:@"INSERT OR REPLACE INTO cache_meta_info (key, size, data, create_time, last_visit_time,exts) VALUES (?, ?, ?, ?, ?, ?)",item.key,@(item.size),item.data,@(item.create_time),@(item.last_visit_time),item.exts];
            
            NSString *dataFilePath = [dataPath stringByAppendingPathComponent:item.key];
            NSError *error = nil;
            if ([_fileManager fileExistsAtPath:dataFilePath]) {
                [_fileManager removeItemAtPath:dataFilePath error:&error];
                if (error) {
                    NSLog(@"MX.cache:delete file:%@ error:%@",dataFilePath, error);
                }
            }
        }else {
            
            result = [_dbHandle executeUpdate:@"INSERT OR REPLACE INTO cache_meta_info (key, size, data, create_time, last_visit_time,exts) VALUES (?, ?, ?, ?, ?, ?)",item.key,@(item.size),nil,@(item.create_time),@(item.last_visit_time),item.exts];
            
            if (result) {
                
                NSString *dataFilePath = [dataPath stringByAppendingPathComponent:item.key];
                [item.data writeToFile:dataFilePath atomically:NO];
            }
        }
        
        return result;
    }
    
    return NO;
}

#pragma mark - get data
- (MXStorageDataItem *)dataItemForKey:(NSString *)key {
    if (_dbHandle.isOpen || [_dbHandle open]) {
        
        [_dbHandle beginTransaction];
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT * FROM cache_meta_info WHERE key == '%@';",key];
        FMResultSet *rs = [_dbHandle executeQuery:selectSQL];
        MXStorageDataItem *di = [self extrectDataItemFrom:rs];
        [rs close];
        
        NSString *updateSQL = [NSString stringWithFormat:@"UPDATE cache_meta_info SET last_visit_time = %ld WHERE key == '%@';",time(NULL),key];
        [_dbHandle executeUpdate:updateSQL];
        [_dbHandle commit];
        
        if (di) {
            if (!di.data) {
                NSString *dataFilePath = [dataPath stringByAppendingPathComponent:key];
                di.data = [NSData dataWithContentsOfFile:dataFilePath];
            }
        }
        
        return di;
    }
    
    return nil;
}

- (MXStorageDataItem *)extrectDataItemFrom:(FMResultSet *)rs {
    if (!rs) {
        return nil;
    }
    MXStorageDataItem *di = [[MXStorageDataItem alloc] init];
    while ([rs next]) {
        di.key = [rs stringForColumn:@"key"];
        di.size = [rs intForColumn:@"size"];
        di.data = [rs dataForColumn:@"data"];
        di.create_time = [rs intForColumn:@"create_time"];
        di.last_visit_time = [rs intForColumn:@"last_visit_time"];
        di.exts = [rs stringForColumn:@"exts"];
        break;
    }
    return di;
}

#pragma mark - remove data

- (BOOL)removeItemForKey:(NSString *)key {
    
    BOOL result = NO;
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM cache_meta_info WHERE key == '%@';",key];
    
    if (_dbHandle.isOpen || [_dbHandle open]) {
        
        result = [_dbHandle executeUpdate:deleteSQL];
    }
    return result;
}

- (BOOL)removeItemsForKeys:(NSArray<NSString *> *)keys {
    
    NSMutableString *inList = [NSMutableString new];
    for (NSString *key in keys) {
        if (inList.length > 0) {
            [inList appendString:@","];
        }
        [inList appendString:@"'"];
        [inList appendString:key];
        [inList appendString:@"'"];
    }
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM cache_meta_info WHERE key IN (%@);",inList];
    BOOL result = NO;
    if (_dbHandle.isOpen || [_dbHandle open]) {
        
        result = [_dbHandle executeUpdate:deleteSQL];
    }
    return result;
}

- (BOOL)removeAllData {
    BOOL result = NO;
    if (_dbHandle.isOpen || [_dbHandle open]) {
        
        NSString *deleteSQL = @"DELETE FROM cache_meta_info;";
        result = [_dbHandle executeUpdate:deleteSQL];
        if (result) {
            NSError *error = nil;
            [_fileManager removeItemAtPath:dataPath error:&error];
            [self createFile:dataPath isDirectory:YES];
        }
    }
    return result;
}

#pragma mark - storage info fetch
- (BOOL)itemExistsForKey:(NSString *)key {
    BOOL result = NO;
    if (_dbHandle.isOpen || [_dbHandle open]) {
        
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT key FROM cache_meta_info WHERE key == '%@';",key];
        FMResultSet *rs = [_dbHandle executeQuery:selectSQL];
        if (rs) {
            while ([rs next]) {
                result = YES; break;
            }
            [rs close];
        }
    }
    return result;
}

- (NSInteger)itemCount {
    NSInteger count = 0;
    if (_dbHandle.isOpen || [_dbHandle open]) {
        
        NSString *selectSQL = @"SELECT key FROM cache_meta_info;" ;
        
        FMResultSet *rs = [_dbHandle executeQuery:selectSQL];
        if (rs) {
            while ([rs next]) {
                ++count;
            }
            [rs close];
        }
    }
    return count;
}

- (NSInteger)totalSize {
    NSInteger size = 0;
    if (_dbHandle.isOpen || [_dbHandle open]) {
        
        NSString *selectSQL = @"SELECT sum(size) as total_size FROM cache_meta_info;" ;
        FMResultSet *rs = [_dbHandle executeQuery:selectSQL];
        if (rs) {
            while ([rs next]) {
                size = [rs intForColumn:@"total_size"];
            }
            [rs close];
        }
    }
    return size;
}

- (void)reduceDataToFitSize:(NSInteger)size {
    NSInteger diskUsage = 0;
    if (_dbHandle.isOpen || [_dbHandle open]) {
        
        NSString *selectSQL = @"SELECT sum(size) as total_size FROM cache_meta_info;" ;
        FMResultSet *rs = [_dbHandle executeQuery:selectSQL];
        if (rs) {
            while ([rs next]) {
                diskUsage = [rs intForColumn:@"total_size"]; break;
            }
            [rs close];
        }
        
        if (diskUsage <= size) {
            return;
        }
        
        selectSQL = @"SELECT key, size, last_visit_time FROM cache_meta_info ORDER BY last_visit_time ASC LIMIT 1;";
        NSString *key = nil;
        NSString *filePath = nil;
        NSError *error = nil;
        BOOL result = NO;
        while (diskUsage > size) {
            FMResultSet *rs = [_dbHandle executeQuery:selectSQL];
            if (rs) {
                while ([rs next]) {
                    diskUsage -= [rs intForColumn:@"size"];
                    
                    key = [rs stringForColumn:@"key"];
                    
                    break;
                }
                [rs close];
                
                filePath = [dataPath stringByAppendingPathComponent:key];
                [_fileManager removeItemAtPath:filePath error:&error];
                result = [_dbHandle executeUpdate:@"DELETE FROM cache_meta_info WHERE key == ?;",key];
                if (!result) {
                    NSLog(@"key:%@ db 操作失败",key);
                }else {
//                    NSLog(@"key:%@ db 操作成功",key);
                }
            }
        }
    }
}

- (void)reduceDataCountToFitCount:(NSInteger)count {
    NSInteger cacheCount = 0;
    if (_dbHandle.isOpen || [_dbHandle open]) {
        
        NSString *countSQL = @"SELECT count(*) as num FROM cache_meta_info;" ;
        FMResultSet *rs = [_dbHandle executeQuery:countSQL];
        if (rs) {
            while ([rs next]) {
                cacheCount = [rs intForColumn:@"num"]; break;
            }
            [rs close];
        }
        
        if (cacheCount <= count) {
            return;
        }
        
        NSString *selectLRUTailSQL = @"SELECT key, size, last_visit_time FROM cache_meta_info ORDER BY last_visit_time ASC LIMIT 1;";
        NSString *key = nil;
        NSString *filePath = nil;
        NSError *error = nil;
        BOOL result = NO;
        while (cacheCount > count) {
            FMResultSet *rs = [_dbHandle executeQuery:selectLRUTailSQL];
            if (rs) {
                while ([rs next]) {
                    
                    key = [rs stringForColumn:@"key"]; break;
                }
                [rs close];
                
                filePath = [dataPath stringByAppendingPathComponent:key];
                [_fileManager removeItemAtPath:filePath error:&error];
                result = [_dbHandle executeUpdate:@"DELETE FROM cache_meta_info WHERE key == ?;",key];
                if (!result) {
                    NSLog(@"key:%@ db 操作失败",key);
                }else {
//                    NSLog(@"key:%@ db 操作成功",key);
                }
                --cacheCount;
            }
        }
    }
}

#pragma mark - private
- (void)clearCache {
    NSError *error = nil;
    [_fileManager removeItemAtPath:_path error:&error];
}

- (BOOL)createDB {
    
    __block BOOL result = NO;
    
    _dbHandle = [FMDatabase databaseWithPath:dbPath];
    if (!_dbHandle) {
        return NO;
    }
    if ([_dbHandle open]) {
        
        result = [_dbHandle executeStatements:cache_meta_info];
    }else {
        
        result = NO;
    }
    
    return result;
}

- (BOOL)createCacheDouments {
    
    _fileManager = [NSFileManager defaultManager];
    
    //create root path
    BOOL createRootPathResult = [self createFile:_path isDirectory:YES];
    
    //create data path
    BOOL createDataDirResult = [self createFile:dataPath isDirectory:YES];
    
    //create transh data path
    BOOL createTrashDirResult = [self createFile:trashPath isDirectory:YES];
    
    return createRootPathResult && createDataDirResult && createTrashDirResult;
}

- (BOOL)createFile:(NSString *)filePath isDirectory:(BOOL)directory {
    
    BOOL result = NO;
    
    BOOL isDirectory = NO;
    if (![_fileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
        if (directory) {
            NSError *error = nil;
            result =[_fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"MX.cache:create data dir error:%@",error);
            }
        }else {
            result = [_fileManager createFileAtPath:filePath contents:nil attributes:nil];
        }
    }else {
        if (isDirectory) {
            result = YES;
        }else {
            NSLog(@"MX.cache:file type error, we need directory but current file type is file:%@",filePath);
        }
    }
    
    return result;
}


@end
