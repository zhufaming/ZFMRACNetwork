//
//  FMEasyDict.m
//  ZFMRACNetwork
//
//  Created by todriver02 on 2018/7/31.
//  Copyright © 2018年 zhufaming. All rights reserved.
//

#import "FMEasyDict.h"

@interface FMEasyDict()

/// 字典
@property (nonatomic, readwrite, strong) NSMutableDictionary *kvs;

@end

@implementation FMEasyDict

/// 类方法
+ (instancetype) easyDict{
    return [[self alloc] init];
}

//初始化 字典
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.kvs = [NSMutableDictionary dictionary];
    }
    return self;
}

/// 拼接一个字典
+ (instancetype)easyWithDictionary:(NSDictionary *) dict{
    return [[self alloc] initWithDictionary:dict];
}
//初始化
-(instancetype)initWithDictionary:(NSDictionary *) dict{
    self = [super init];
    if (self) {
        self.kvs = [NSMutableDictionary dictionary];
        if ([dict count]) {
            [self.kvs addEntriesFromDictionary:dict];
        }
    }
    return self;
}

//根据 key 取值
- (id)objectForKey:(id)key{
    return key ? [self.kvs objectForKey:key] : nil;
}
//单个设置值
- (void)setObject:(id)obj forKey:(id <NSCopying>)key{
    if (key) {
        if (obj) {
            [self.kvs setObject:obj forKey:key];
        } else {
            [self.kvs removeObjectForKey:key];
        }
    }
}

/// 转换为字典
- (NSDictionary *)dictionary{
    return self.kvs.copy;
}


@end
