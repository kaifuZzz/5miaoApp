//
//  NotificationManager.m
//  VouteStatement
//
//  Created by 付凯 on 2017/4/26.
//  Copyright © 2017年 韫安. All rights reserved.
//

#import "NotificationManager.h"
#import "NotificationApiManager.h"
#import "NotificationReformer.h"
#import "AppDelegate.h"

NSString * const NotificationManagerDidReceiveNewData = @"NotificationManagerDidReceiveNewData";

static NSTimeInterval autoRequestTimeInterval = 5;
static NSInteger    defaultRequestId = -1;

@interface NotificationManager ()<VTAPIManagerParamSource,VTAPIManagerCallBackDelegate>

@property (nonatomic,strong)NotificationApiManager *apiManager;

@property (nonatomic,strong)NSTimer *timer;

@property (nonatomic,assign)NSInteger requestId;
@end

@implementation NotificationManager

static NotificationManager *obj = nil;
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!obj) {
            obj = [[NotificationManager alloc] init];
            [[NSNotificationCenter defaultCenter] addObserver:obj selector:@selector(userDidLoginIn) name:VTAppContextUserDidLoginInNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:obj selector:@selector(userDidLoginOut) name:VTAppContextUserDidLoginOutNotification object:nil];
        }
    });
    return obj;
}
- (void)startMonitoring {
    if ([VTAppContext shareInstance].isOnline) {
        [self.timer fire];
    }
}
- (void)stopMonitoring {
    [self.timer invalidate];
    self.timer = nil;
    [self.apiManager cancelAllRequest];
    AppDelegate *appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appdelegate.rootTabbarConfig.haveRedPointTip = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationManagerDidReceiveNewData object:@{@"circle":@"0",@"feed":@"0"}];
}
- (void)userDidLoginIn {
    [self startMonitoring];
}
- (void)userDidLoginOut {
    [self stopMonitoring];
}
- (void)autoRequest {
    [self.apiManager cancelAllRequest];
    [self.apiManager loadData];
}
#pragma mark -- VTAPIManagerParamSource
- (NSDictionary *)paramsForApi:(APIBaseManager *)manager {
    return @{};
}
#pragma mark -- VTAPIManagerCallBackDelegate
- (void)managerCallAPIDidSuccess:(APIBaseManager *)manager {
    NotificationReformer *reformer = [[NotificationReformer alloc] init];
    NSDictionary *data = [manager fetchDataWithReformer:reformer];
    int circle = [data[@"circle"] intValue];
    int feed = [data[@"feed"] intValue];
    BOOL ret = NO;
    if (circle || feed) {
        ret = YES;
    }
    AppDelegate *appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appdelegate.rootTabbarConfig.haveRedPointTip = ret;
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationManagerDidReceiveNewData object:data];
}
- (void)managerCallAPIDidFailed:(APIBaseManager *)manager {
    
}
#pragma -- getter
- (NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:autoRequestTimeInterval target:self selector:@selector(autoRequest) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return  _timer;
}
- (NotificationApiManager *)apiManager {
    if (!_apiManager) {
        _apiManager = [[NotificationApiManager alloc] init];
        _apiManager.delegate = self;
        _apiManager.paramsourceDelegate = self;
    }
    return _apiManager;
}
- (void)dealloc {
    [self stopMonitoring];
}
@end
