//
//  ViewController.m
//  ZFMRACNetwork
//
//  Created by todriver02 on 2018/7/30.
//  Copyright © 2018年 zhufaming. All rights reserved.
//

#import "ViewController.h"
#import "FMARCNetwork.h"
#import "FMHttpRequest.h"
#import "FMHttpResonse.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textV;


@property (nonatomic,strong) RACSignal * reqSignal;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (IBAction)correctAction:(UIButton *)sender {
    /// 1. 配置参数
    NSMutableDictionary *easyDict = [NSMutableDictionary dictionary];
    easyDict[@"useridx"] = @"61856069";
    easyDict[@"type"] = @(1);
    easyDict[@"page"] = @(1);
    easyDict[@"lat"] = @(22.54192103514200);
    easyDict[@"lon"] = @(113.96939828211362);
    easyDict[@"province"] = @"广东省";
    
    /// 2. 配置参数模型 #define MH_GET_LIVE_ROOM_LIST  @"Room/GetHotLive_v2"
    FMHttpRequest *req = [FMHttpRequest urlParametersWithMethod:HTTTP_METHOD_POST path:@"Room/GetHotLive_v2" parameters:easyDict];
    
    
    _reqSignal = [[FMARCNetwork sharedInstance] requestNetworkData:req];
    
    [_reqSignal subscribeNext:^(FMHttpResonse *response) {
        if (response.isSuccess) {
            NSLog(@"--%@",response.reqResult);
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response.reqResult options:NSJSONWritingPrettyPrinted error:nil];
            
            NSString * str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            self.textV.text = str;
        }
        
    }];
}



#pragma mark--模仿错误请求，改变路径
- (IBAction)errorCorrectAction:(UIButton *)sender {
    /// 1. 配置参数
    NSMutableDictionary *easyDict = [NSMutableDictionary dictionary];
//    easyDict[@"useridx"] = @"61856069";
//    easyDict[@"type"] = @(1);
//    easyDict[@"page"] = @(1);
//    easyDict[@"lat"] = @(22.54192103514200);
//    easyDict[@"lon"] = @(113.96939828211362);
//    easyDict[@"province"] = @"广东省";
    
    /// 2. 配置参数模型 #define MH_GET_LIVE_ROOM_LIST  @"Room/GetHotLive_v2"
    FMHttpRequest *req = [FMHttpRequest urlParametersWithMethod:HTTTP_METHOD_POST path:@"Room/GetHotLive_v2xx" parameters:easyDict];
    
    
    _reqSignal = [[FMARCNetwork sharedInstance] requestNetworkData:req];
    
    [_reqSignal subscribeNext:^(FMHttpResonse *response) {
        if (response.isSuccess) {
            NSLog(@"--%@",response.reqResult);
        }
        
    }];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
