//
//  MXLRU.m
//  MXLRU
//
//  Created by heke on 2018/10/7.
//  Copyright © 2019 MX. All rights reserved.
//

#import "MXLRU.h"
@import QuartzCore;

@interface MXDoubleLinKNode : NSObject
{
    @package
    MXDoubleLinKNode *prev;
    MXDoubleLinKNode *next;
    
    NSString *key;
    NSData *value;
    NSInteger visitTime;
}

@end

@implementation MXDoubleLinKNode

- (instancetype)init
{
    self = [super init];
    if (self) {
        prev = nil;
        next = nil;
        key = nil;
        value = nil;
        visitTime = 0;
    }
    return self;
}

@end

#define LRUWait() dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER)
#define LRUSignal() dispatch_semaphore_signal(lock)

@interface MXLRU ()
{
    dispatch_semaphore_t lock;
    NSInteger currentCount;
    NSInteger currentMemoryUsage;
    NSInteger searchCount;
    NSInteger hitCount;
    CFMutableDictionaryRef nodeMap;
}

@property (nonatomic, strong) MXDoubleLinKNode *head;
@property (nonatomic, strong) MXDoubleLinKNode *tail;

@end

#define DicValueForKey(dic, key) CFDictionaryGetValue(dic, (__bridge const void *)key)
#define DicSetValueForKey(dic, value, key) CFDictionarySetValue(dic, (__bridge const void *)key, (__bridge const void *)value);
#define DicRemoveValueForKey(dic, key) CFDictionaryRemoveValue(dic, (__bridge const void *)key);

@implementation MXLRU

- (void)dealloc {
    CFRelease(nodeMap);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        nodeMap = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _head = nil;
        _tail = nil;
        lock = dispatch_semaphore_create(1);
        searchCount = 0;
        hitCount = 0;
    }
    return self;
}

- (void)setData:(NSData *)data forKey:(NSString *)key {
    if (!key) {
        return;
    }
    LRUWait();
    MXDoubleLinKNode *nodeOfKey = DicValueForKey(nodeMap, key);
    if (nodeOfKey) {
        nodeOfKey->visitTime = ceil(CACurrentMediaTime());
        
        if (!data) {
            [self removeNode:nodeOfKey];
            DicRemoveValueForKey(nodeMap, key);
            --currentCount;
            currentMemoryUsage -= nodeOfKey->value.length;
        }else {
            nodeOfKey->value = data;
            [self bringNodeToHead:nodeOfKey];
            ++currentCount;
        }
    }else {
        MXDoubleLinKNode *node = [[MXDoubleLinKNode alloc] init];
        node->key = key;
        node->value = data;
        node->visitTime = CACurrentMediaTime();
        if (data) {
            [self insertNodeToHead:node];
            ++currentCount;
            currentMemoryUsage += data.length;
            DicSetValueForKey(nodeMap, node, key);
        }
    }
    LRUSignal();
}

- (NSData *)dataForKey:(NSString *)key {
    ++searchCount;
    if (!key) {
        return nil;
    }
    LRUWait();
    
    MXDoubleLinKNode *nodeOfKey = DicValueForKey(nodeMap, key);
    if (nodeOfKey) {
        nodeOfKey->visitTime = CACurrentMediaTime();
        [self bringNodeToHead:nodeOfKey];
        ++hitCount;
    }else {
    }
    
    LRUSignal();
    
    return nodeOfKey ? nodeOfKey->value : nil;
}

- (void)removeDataForKey:(NSString *)key {
    if (!key) {
        return;
    }
    LRUWait();
    
    MXDoubleLinKNode *nodeOfKey = DicValueForKey(nodeMap, key);
    if (nodeOfKey) {
        [self removeNode:nodeOfKey];
    }
    
    LRUSignal();
}

- (void)clear {
    LRUWait();
    [self _clear];
    _head = nil;
    _tail = nil;
    currentCount = 0;
    currentMemoryUsage = 0;
    searchCount = 0;
    hitCount = 0;
    LRUSignal();
}

/*
 trim by node count
 trim by memory usage
 */
- (void)trim {
    LRUWait();
    //memory usage
    while (currentCount > _maxNodeCount ||
           currentMemoryUsage > _maxMemoryUsage) {
        DicRemoveValueForKey(nodeMap, _tail->key)
        
        if (_tail != _head) {
            
            --currentCount;
            currentMemoryUsage -= _tail->value.length;
            
            _tail = _tail->prev;
            _tail->next->prev = nil;
            _tail->next = nil;
            
        }else {
            
            _tail = nil;
            _head = nil;
            currentCount = 0;
            currentMemoryUsage = 0;
        }
    }
    LRUSignal();
}

- (NSInteger)getCurrentMemoryUsage {
    return currentMemoryUsage;
}

- (NSInteger)getCurrentNodeCount {
    return currentCount;
}

- (float)getCurrentHitRate {
    if (searchCount < 1) {
        return 0;
    }
    return hitCount * (1./searchCount);
}

#pragma mark - private
- (void)bringNodeToHead:(MXDoubleLinKNode *)node {
    if (_head == _tail && _head == node) {
        return;
    }
    if (node == _head) {
        //--
    }else if (node == _tail) {
        
        _tail = node->prev;
        _tail->next = nil;
        
        node->next = _head;
        _head->prev = node;
        
        _head = node;
        _head->prev = nil;
        
    }else {
        node->prev->next = node->next;
        node->next->prev = node->prev;
        
        node->next = _head;
        _head->prev = node;
        
        _head = node;
        _head->prev = nil;
    }
}

- (void)insertNodeToHead:(MXDoubleLinKNode *)node {
    if (!_head) {
        
        _head = node;
        _tail = node;
    }else {
        
        node->next = _head;
        _head->prev = node;
        
        _head = node;
        _head->prev = nil;
    }
}

- (void)removeNode:(MXDoubleLinKNode *)node {
    if (_head == _tail) {
        _head = nil;
        _tail = nil;
        return;
    }
    
    if (node == _head) {
        
        _head = _head->next;
        _head->prev = nil;
        node->next = nil;
    }else if (node == _tail) {
        
        _tail = _tail->prev;
        _tail->next = nil;
        node->prev = nil;
    }else {
        
        node->prev->next = node->next;
        node->next->prev = node->prev;
        node->prev = nil;
        node->next = nil;
    }
}

/*
 remove all node.
 */
- (void)_clear {
    while (_tail != nil) {
        DicRemoveValueForKey(nodeMap, _tail->key);
        if (_tail != _head) {
            _tail = _tail->prev;
            _tail->next->prev = nil;
            _tail->next = nil;
        }else {
            _tail = nil;
            _head = nil;
        }
    }
    currentCount = 0;
    currentMemoryUsage = 0;
}

@end
