//
//  MXSandBox.m
//  MXCache
//
//  Created by heke on 2019/1/7.
//  Copyright © 2019 MX. All rights reserved.
//

#import "MXSandBox.h"

@implementation MXSandBox

+ (NSString *)documentPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
}

@end
