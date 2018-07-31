//
//  FMARCNetwork.m
//  ZFMRACNetwork
//
//  Created by todriver02 on 2018/7/31.
//  Copyright © 2018年 zhufaming. All rights reserved.
//

#import "FMARCNetwork.h"
#import "FMHttpConstant.h"
#import "FMHttpRequest.h"
#import "FMHttpResonse.h"
#import "AFNetworking.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>

/// 请求数据返回的状态码、根据自己的服务端数据来
typedef NS_ENUM(NSUInteger, HTTPResponseCode) {
    HTTPResponseCodeSuccess = 0,           /// 请求成功
    HTTPResponseCodeNotLogin = 1009,       /// 用户尚未登录，一般在网络请求前判断处理，也可以在网络层处理
};

/// The Http request error domain
NSString *const HTTPServiceErrorDomain = @"HTTPServiceErrorDomain";
/// 请求成功，但statusCode != 0
NSString *const HTTPServiceErrorResponseCodeKey = @"HTTPServiceErrorResponseCodeKey";


NSString * const HTTPServiceErrorRequestURLKey = @"HTTPServiceErrorRequestURLKey";
NSString * const HTTPServiceErrorHTTPStatusCodeKey = @"HTTPServiceErrorHTTPStatusCodeKey";
NSString * const HTTPServiceErrorDescriptionKey = @"HTTPServiceErrorDescriptionKey";
NSString * const HTTPServiceErrorMessagesKey = @"HTTPServiceErrorMessagesKey";

@interface FMARCNetwork()
//网络管理工具
@property (nonatomic,strong) AFHTTPSessionManager * manager;

@end

@implementation FMARCNetwork

static FMARCNetwork * _instance = nil;

#pragma mark -  HTTPService
+(instancetype) sharedInstance {
    if (_instance == nil) {
        _instance = [[super alloc] init];
        //初始化 网络管理器
        _instance.manager = [AFHTTPSessionManager manager];
        [_instance configHTTPService];
        
    }
    return _instance;
}
+ (id)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
        
    });
    return _instance;
}
- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

-(id)mutableCopyWithZone:(NSZone *)zone{
    return _instance;
}

/// config service
- (void)configHTTPService{
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
#if DEBUG
    responseSerializer.removesKeysWithNullValues = NO;
#else
    responseSerializer.removesKeysWithNullValues = YES;
#endif
    responseSerializer.readingOptions = NSJSONReadingAllowFragments;
    /// config
    self.manager.responseSerializer = responseSerializer;
    self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    
    /// 安全策略
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    //allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    //如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO
    //主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    securityPolicy.validatesDomainName = NO;
    
    self.manager.securityPolicy = securityPolicy;
    /// 支持解析
    self.manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                      @"text/json",
                                                      @"text/javascript",
                                                      @"text/html",
                                                      @"text/plain",
                                                      @"text/html; charset=UTF-8",
                                                      nil];
    
    /// 开启网络监测
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [self.manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        if (status == AFNetworkReachabilityStatusUnknown) {
            NSLog(@"--- 未知网络 ---");
        }else if (status == AFNetworkReachabilityStatusNotReachable) {
  
            NSLog(@"--- 无网络 ---");
        }else{
            NSLog(@"--- 有网络 ---");
            
        }
    }];
    [self.manager.reachabilityManager startMonitoring];
}


- (RACSignal *)requestNetworkData:(FMHttpRequest *)req{
     /// request 必须的有值
    if (!req) return [RACSignal error:[NSError errorWithDomain:HTTPServiceErrorDomain code:-1 userInfo:nil]];
    
    @weakify(self);
    /// 创建信号
    RACSignal *signal = [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        @strongify(self);
        /// 获取request
        
        NSError *serializationError = nil;
        
        NSMutableURLRequest *request = [self.manager.requestSerializer requestWithMethod:req.method URLString:[[NSURL URLWithString:req.path relativeToURL:[NSURL URLWithString:BaseUrl] ] absoluteString] parameters:req.parameters error:&serializationError];
        
        if (serializationError) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.manager.completionQueue ?: dispatch_get_main_queue(), ^{
                [subscriber sendError:serializationError];
            });
#pragma clang diagnostic pop
            return [RACDisposable disposableWithBlock:^{
            }];
        }
        /// 获取请求任务
        __block NSURLSessionDataTask *task = nil;
        task = [self.manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            if (error) {
                NSError *parseError = [self errorFromRequestWithTask:task httpResponse:(NSHTTPURLResponse *)response responseObject:responseObject error:error];
    
                NSInteger code = [parseError.userInfo[HTTPServiceErrorHTTPStatusCodeKey] integerValue];
                NSString *msgStr = parseError.userInfo[HTTPServiceErrorDescriptionKey];
                //初始化、返回数据模型
                FMHttpResonse *response = [[FMHttpResonse alloc] initWithResponseError:parseError code:code msg:msgStr];
                //错误可以在此处处理---比如加入自己弹窗，主要是服务器错误、和请求超时、网络开小差
                //同样也返回到,调用的地址，也可处理，自己选择
                [subscriber sendNext:response];
                //[subscriber sendError:parseError];
                [subscriber sendCompleted];
                
            } else {
              
                /// 判断
                NSInteger statusCode = [responseObject[HTTPServiceResponseCodeKey] integerValue];
                if (statusCode == HTTPResponseCodeSuccess) {
                    FMHttpResonse *response = [[FMHttpResonse alloc] initWithResponseSuccess:responseObject[HTTPServiceResponseDataKey] code:statusCode];
                   
                    [subscriber sendNext:response];
                    [subscriber sendCompleted];
                    
                }else{
                    if (statusCode == HTTPResponseCodeNotLogin) {
                        //可以在此处理需要登录的逻辑、比如说弹出登录框，但是，一般请求某个 api 判断了是否需要登录就不会进入
                        //如果进入可一做错误处理
                        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                        userInfo[HTTPServiceErrorHTTPStatusCodeKey] = @(statusCode);
                        userInfo[HTTPServiceErrorDescriptionKey] = @"请登录!";
                        
                        NSError *noLoginError = [NSError errorWithDomain:HTTPServiceErrorDomain code:statusCode userInfo:userInfo];
                        
                        FMHttpResonse *response = [[FMHttpResonse alloc] initWithResponseError:noLoginError code:statusCode msg:@"请登录!"];
                        
                        [subscriber sendNext:response];
                        [subscriber sendCompleted];
                        
                    }else{
                        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                        userInfo[HTTPServiceErrorResponseCodeKey] = @(statusCode);
                        //取出服务给的提示
                        NSString *msgTips = responseObject[HTTPServiceResponseMsgKey];
                        //服务器没有返回，错误信息
                        if ((msgTips.length == 0 || msgTips == nil || [msgTips isKindOfClass:[NSNull class]])) {
                            msgTips = @"服务器出错了，请稍后重试~";
                        }
                        
                        userInfo[HTTPServiceErrorMessagesKey] = msgTips;
                        if (task.currentRequest.URL != nil) userInfo[HTTPServiceErrorRequestURLKey] = task.currentRequest.URL.absoluteString;
                        if (task.error != nil) userInfo[NSUnderlyingErrorKey] = task.error;
                        NSError *requestError = [NSError errorWithDomain:HTTPServiceErrorDomain code:statusCode userInfo:userInfo];
                        //错误信息反馈回去了、可以在此做响应的弹窗处理，展示出服务器给我们的信息
                        FMHttpResonse *response = [[FMHttpResonse alloc] initWithResponseError:requestError code:statusCode msg:msgTips];
                        [subscriber sendNext:response];
                        [subscriber sendCompleted];
                    }
                }
            }
        }];
        
        /// 开启请求任务
        [task resume];
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
    }];
    return signal;
}


- (RACSignal *)uploadNetworkPath:(NSString *)path params:(NSDictionary *)params fileDatas:(NSArray<NSData *> *)fileDatas name:(NSString *)name mimeType:(NSString *)mimeType
{
    
    return [self UploadRequestWithPath:path parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {

        NSInteger count = fileDatas.count;
        for (int i = 0; i< count; i++) {
            /// 取出fileData
            NSData *fileData = fileDatas[i];

            /// 断言
            NSAssert([fileData isKindOfClass:NSData.class], @"fileData is not an NSData class: %@", fileData);

            // 在网络开发中，上传文件时，是文件不允许被覆盖，文件重名
            // 要解决此问题，
            // 可以在上传时使用当前的系统事件作为文件名

            static NSDateFormatter *formatter = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                formatter = [[NSDateFormatter alloc] init];
            });
            // 设置时间格式
            [formatter setDateFormat:@"yyyyMMddHHmmss"];
            NSString *dateString = [formatter stringFromDate:[NSDate date]];
            NSString *fileName = [NSString  stringWithFormat:@"senba_empty_%@_%d.jpg", dateString , i];

            [formData appendPartWithFileData:fileData name:name fileName:fileName mimeType:!(mimeType.length == 0 || mimeType == nil || [mimeType isKindOfClass:[NSNull class]])?mimeType:@"application/octet-stream"];
            
        }
    }];
    
    
}

- (RACSignal *)UploadRequestWithPath:(NSString *)path parameters:(id)parameters constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block{
    @weakify(self);
    /// 创建信号
    RACSignal *signal = [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        @strongify(self);
        /// 获取request
        NSError *serializationError = nil;
        
        NSMutableURLRequest *request = [self.manager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:path relativeToURL:[NSURL URLWithString:ImgBaseURL]] absoluteString] parameters:parameters constructingBodyWithBlock:block error:&serializationError];
        if (serializationError) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.manager.completionQueue ?: dispatch_get_main_queue(), ^{
                [subscriber sendError:serializationError];
            });
#pragma clang diagnostic pop
            
            return [RACDisposable disposableWithBlock:^{
            }];
        }
        
        __block NSURLSessionDataTask *task = [self.manager uploadTaskWithStreamedRequest:request progress:nil completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
            if (error) {
                NSError *parseError = [self errorFromRequestWithTask:task httpResponse:(NSHTTPURLResponse *)response responseObject:responseObject error:error];
                
                NSInteger code = [parseError.userInfo[HTTPServiceErrorHTTPStatusCodeKey] integerValue];
                NSString *msgStr = parseError.userInfo[HTTPServiceErrorDescriptionKey];
                //初始化、返回数据模型
                FMHttpResonse *response = [[FMHttpResonse alloc] initWithResponseError:parseError code:code msg:msgStr];
                //错误可以在此处处理---比如加入自己弹窗，主要是服务器错误、和请求超时、网络开小差
                //同样也返回到,调用的地址，也可处理，自己选择
                [subscriber sendNext:response];
                //[subscriber sendError:parseError];
                [subscriber sendCompleted];
            } else {
                
                /// 判断
                NSInteger statusCode = [responseObject[HTTPServiceResponseCodeKey] integerValue];
                if (statusCode == HTTPResponseCodeSuccess) {
                    FMHttpResonse *response = [[FMHttpResonse alloc] initWithResponseSuccess:responseObject[HTTPServiceResponseDataKey] code:statusCode];
                    
                    [subscriber sendNext:response];
                    [subscriber sendCompleted];
                    
                }else{
                    if (statusCode == HTTPResponseCodeNotLogin) {
                        //可以在此处理需要登录的逻辑、比如说弹出登录框，但是，一般请求某个 api 判断了是否需要登录就不会进入
                        //如果进入可一做错误处理
                        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                        userInfo[HTTPServiceErrorHTTPStatusCodeKey] = @(statusCode);
                        userInfo[HTTPServiceErrorDescriptionKey] = @"请登录!";
                        
                        NSError *noLoginError = [NSError errorWithDomain:HTTPServiceErrorDomain code:statusCode userInfo:userInfo];
                        
                        FMHttpResonse *response = [[FMHttpResonse alloc] initWithResponseError:noLoginError code:statusCode msg:@"请登录!"];
                        
                        [subscriber sendNext:response];
                        [subscriber sendCompleted];
                        
                    }else{
                        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                        userInfo[HTTPServiceErrorResponseCodeKey] = @(statusCode);
                        //取出服务给的提示
                        NSString *msgTips = responseObject[HTTPServiceResponseMsgKey];
                        //服务器没有返回，错误信息
                        if ((msgTips.length == 0 || msgTips == nil || [msgTips isKindOfClass:[NSNull class]])) {
                            msgTips = @"服务器出错了，请稍后重试~";
                        }
                        
                        userInfo[HTTPServiceErrorMessagesKey] = msgTips;
                        if (task.currentRequest.URL != nil) userInfo[HTTPServiceErrorRequestURLKey] = task.currentRequest.URL.absoluteString;
                        if (task.error != nil) userInfo[NSUnderlyingErrorKey] = task.error;
                        NSError *requestError = [NSError errorWithDomain:HTTPServiceErrorDomain code:statusCode userInfo:userInfo];
                        //错误信息反馈回去了、可以在此做响应的弹窗处理，展示出服务器给我们的信息
                        FMHttpResonse *response = [[FMHttpResonse alloc] initWithResponseError:requestError code:statusCode msg:msgTips];
                        [subscriber sendNext:response];
                        [subscriber sendCompleted];
                    }
                }
            
            }
        }];
        
        [task resume];
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
        
    }];
    /// replayLazily:replayLazily会在第一次订阅的时候才订阅sourceSignal
    /// 会提供所有的值给订阅者 replayLazily还是冷信号 避免了冷信号的副作用
    return [[signal
             replayLazily]
            setNameWithFormat:@"-enqueueUploadRequestWithPath: %@ parameters: %@", path, parameters];
}



/// 请求错误解析
- (NSError *)errorFromRequestWithTask:(NSURLSessionTask *)task httpResponse:(NSHTTPURLResponse *)httpResponse responseObject:(NSDictionary *)responseObject error:(NSError *)error {
    /// 不一定有值，则HttpCode = 0;
    NSInteger HTTPCode = httpResponse.statusCode;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    NSString *errorDesc = @"服务器出错了，请稍后重试~";
    /// 其实这里需要处理后台数据错误，一般包在 responseObject
    /// HttpCode错误码解析 https://www.guhei.net/post/jb1153
    /// 1xx : 请求消息 [100  102]
    /// 2xx : 请求成功 [200  206]
    /// 3xx : 请求重定向[300  307]
    /// 4xx : 请求错误  [400  417] 、[422 426] 、449、451
    /// 5xx 、600: 服务器错误 [500 510] 、600
    NSInteger httpFirstCode = HTTPCode/100;
    if (httpFirstCode>0) {
        if (httpFirstCode==4) {
            /// 请求出错了，请稍后重试
            if (HTTPCode == 408) {
                errorDesc = @"请求超时，请稍后再试~";
            }else{
                errorDesc = @"请求出错了，请稍后重试~";
            }
        }else if (httpFirstCode == 5 || httpFirstCode == 6){
            /// 服务器出错了，请稍后重试
            errorDesc = @"服务器出错了，请稍后重试~";
            
        }else if (!self.manager.reachabilityManager.isReachable){
            /// 网络不给力，请检查网络
            errorDesc = @"网络开小差了，请稍后重试~";
        }
    }else{
        if (!self.manager.reachabilityManager.isReachable){
            /// 网络不给力，请检查网络
            errorDesc = @"网络开小差了，请稍后重试~";
        }
    }
    
    switch (HTTPCode) {
        case 400:{
                /// 请求失败
            break;
        }
        case 403:{
                /// 服务器拒绝请求
            break;
        }
        case 422:{
               /// 请求出错
            break;
        }
        default:
            /// 从error中解析
            if ([error.domain isEqual:NSURLErrorDomain]) {
                errorDesc = @"请求出错了，请稍后重试~";
                switch (error.code) {
                    case NSURLErrorTimedOut:{
                        errorDesc = @"请求超时，请稍后再试~";
                        break;
                    }
                    case NSURLErrorNotConnectedToInternet:{
                        errorDesc = @"网络开小差了，请稍后重试~";
                        break;
                    }
                }
            }
    }
    
    userInfo[HTTPServiceErrorHTTPStatusCodeKey] = @(HTTPCode);
    userInfo[HTTPServiceErrorDescriptionKey] = errorDesc;
    if (task.currentRequest.URL != nil) userInfo[HTTPServiceErrorRequestURLKey] = task.currentRequest.URL.absoluteString;
    if (task.error != nil) userInfo[NSUnderlyingErrorKey] = task.error;
    
    return [NSError errorWithDomain:HTTPServiceErrorDomain code:HTTPCode userInfo:userInfo];
    
}


@end
