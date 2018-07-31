//
//  FMHttpRequest.m
//  ZFMRACNetwork
//
//  Created by todriver02 on 2018/7/31.
//  Copyright © 2018年 zhufaming. All rights reserved.
//

#import "FMHttpRequest.h"

@implementation ExtendsParameters

+ (instancetype)extendsParameters
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSString *)version{
    static NSString *version = nil;
    if (version == nil) version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
    return (version.length>0)?version:@"";
}

- (NSString *)token {
    // token 自己的逻辑
    return @"";
}

- (NSString *)deviceid {
    static NSString *deviceidStr = nil;
    //设备ID 自行逻辑获取
    return deviceidStr.length>0?deviceidStr:@"";
}

- (NSString *)platform{
    return @"iOS";
}

- (NSString *)channel{
    return @"AppStore";
}

- (NSString *)t {
    return [NSString stringWithFormat:@"%.f", [NSDate date].timeIntervalSince1970];
}

@end

@implementation FMHttpRequest

+(instancetype)urlParametersWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
    return [[self alloc] initUrlParametersWithMethod:method path:path parameters:parameters];
}

-(instancetype)initUrlParametersWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
    self = [super init];
    if (self) {
        self.method = method;
        self.path = path;
        self.parameters = parameters;
        self.extendsParameters = [[ExtendsParameters alloc] init];
    }
    return self;
}

@end
