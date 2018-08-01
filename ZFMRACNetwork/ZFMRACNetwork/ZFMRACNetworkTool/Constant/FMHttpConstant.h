//
//  FMHttpConstant.h
//  ZFMRACNetwork
//
//  Created by todriver02 on 2018/7/31.
//  Copyright © 2018年 zhufaming. All rights reserved.
//

/**
 *  网络请求相关 宏定义
 */

#ifndef FMHttpConstant_h
#define FMHttpConstant_h

/*******URL******/
#define BaseUrl @"https://live.9158.com/"
/********ImgBaseURL*****/
#define ImgBaseURL @""

/********如果需要存储，相应的的 key 宏定义********/
/// 服务器相关
#define HTTPRequestTokenKey @"token"
/// 签名key
#define HTTPServiceSignKey @"sign"

/// 私钥key
#define HTTPServiceKey  @"privatekey"
/// 私钥Value
#define HTTPServiceKeyValue @"/** 你的私钥 **/"


/// 状态码key
#define HTTPServiceResponseCodeKey @"code"
/// 消息key
#define HTTPServiceResponseMsgKey @"msg"
/// 数据data
#define HTTPServiceResponseDataKey  @"data"

#endif /* FMHttpConstant_h */
