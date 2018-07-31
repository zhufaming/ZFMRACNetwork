//
//  FMEasyDict.h
//  ZFMRACNetwork
//
//  Created by todriver02 on 2018/7/31.
//  Copyright © 2018年 zhufaming. All rights reserved.
//

/**
 *  便捷字典参数构造
 */

#import <Foundation/Foundation.h>

@interface FMEasyDict : NSObject

/// 类方法
+ (instancetype) easyDict;
/// 拼接一个字典
+ (instancetype)easyWithDictionary:(NSDictionary *) dict;
//初始化
-(instancetype)initWithDictionary:(NSDictionary *) dict;
//根据 key 取值
- (id)objectForKey:(id)key;
//单个设置值
- (void)setObject:(id)obj forKey:(id <NSCopying>)key;

/// 转换为字典
- (NSDictionary *)dictionary;

@end
