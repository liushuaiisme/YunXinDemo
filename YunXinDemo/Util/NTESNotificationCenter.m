    //
//  NTESNotificationCenter.m
//  NIM
//
//  Created by Xuhui on 15/3/25.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESNotificationCenter.h"
//#import "NTESVideoChatViewController.h"
//#import "NTESAudioChatViewController.h"
//#import "NTESMainTabController.h"
//#import "NTESSessionViewController.h"
//#import "NSDictionary+NTESJson.h"
//#import "NTESCustomNotificationDB.h"
//#import "NTESCustomNotificationObject.h"
//#import "UIView+Toast.h"
//#import "NTESWhiteboardViewController.h"
//#import "NTESCustomSysNotificationSender.h"
//#import "NTESGlobalMacro.h"
#import <AVFoundation/AVFoundation.h>
//#import "NTESLiveViewController.h"
//#import "NTESSessionMsgConverter.h"
//#import "NTESSessionUtil.h"

#import "LSVideoController.h"
#import "LSAudioController.h"
#import "LSTempModel.h"
#import "NTESNetChatViewController.h"


NSString *NTESCustomNotificationCountChanged = @"NTESCustomNotificationCountChanged";

@interface NTESNotificationCenter () <NIMSystemNotificationManagerDelegate,NIMNetCallManagerDelegate,NIMRTSManagerDelegate,NIMChatManagerDelegate>

@property (nonatomic,strong) AVAudioPlayer *player; //播放提示音

@end

@implementation NTESNotificationCenter

+ (instancetype)sharedCenter
{
    static NTESNotificationCenter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NTESNotificationCenter alloc] init];
    });
    return instance;
}

- (void)start
{
//    DDLogInfo(@"Notification Center Setup");
}

- (instancetype)init {
    self = [super init];
    if(self) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"message" withExtension:@"wav"];
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];

        [[NIMSDK sharedSDK].systemNotificationManager addDelegate:self];
        [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
        [[NIMAVChatSDK sharedSDK].rtsManager addDelegate:self];
        [[NIMSDK sharedSDK].chatManager addDelegate:self];
    }
    return self;
}


- (void)dealloc{
    [[NIMSDK sharedSDK].systemNotificationManager removeDelegate:self];
    [[NIMAVChatSDK sharedSDK].netCallManager removeDelegate:self];
    [[NIMAVChatSDK sharedSDK].rtsManager removeDelegate:self];
    [[NIMSDK sharedSDK].chatManager removeDelegate:self];
}


#pragma mark - NIMChatManagerDelegate
//- (void)onRecvMessages:(NSArray *)messages
//{
//    static BOOL isPlaying = NO;
//    if (isPlaying) {
//        return;
//    }
//    isPlaying = YES;
//    [self playMessageAudioTip];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        isPlaying = NO;
//    });
//    [self checkMessageAt:messages];
//}

//- (void)playMessageAudioTip
//{
//    UINavigationController *nav = [NTESMainTabController instance].selectedViewController;
//    BOOL needPlay = YES;
//    for (UIViewController *vc in nav.viewControllers) {
//        if ([vc isKindOfClass:[NIMSessionViewController class]] ||  [vc isKindOfClass:[NTESLiveViewController class]] || [vc isKindOfClass:[NTESNetChatViewController class]])
//        {
//            needPlay = NO;
//            break;
//        }
//    }
//    if (needPlay) {
//        [self.player stop];
//        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error:nil];
//        [self.player play];
//    }
//}

//- (void)checkMessageAt:(NSArray *)messages
//{
//    //同个 session 的消息
//    NIMSession *session = [messages.firstObject session];
//    UINavigationController *nav = [NTESMainTabController instance].selectedViewController;
//    for (UIViewController *vc in nav.viewControllers) {
//        if ([vc isKindOfClass:[NIMSessionViewController class]])
//        {
//            //只有在@所属会话页外面才需要标记有人@你
//            if ([[(NIMSessionViewController*)vc session] isEqual:session]) {
//                return;
//            };
//        }
//    }
//    NSString *me = [[NIMSDK sharedSDK].loginManager currentAccount];
//    
//    for (NIMMessage *message in messages) {
//        if ([message.apnsMemberOption.userIds containsObject:me]) {
//            [NTESSessionUtil addRecentSessionAtMark:session];
//            return;
//        }
//    }
//}

//{- (void)onRecvRevokeMessageNotification:(NIMRevokeMessageNotification *)notification
//
//    NIMMessage *tipMessage = [NTESSessionMsgConverter msgWithTip:[NTESSessionUtil tipOnMessageRevoked:notification]];
//    NIMMessageSetting *setting = [[NIMMessageSetting alloc] init];
//    setting.shouldBeCounted = NO;
//    tipMessage.setting = setting;
//    tipMessage.timestamp = notification.timestamp;
//    
//    NTESMainTabController *tabVC = [NTESMainTabController instance];
//    UINavigationController *nav = tabVC.selectedViewController;
//
//    for (NTESSessionViewController *vc in nav.viewControllers) {
//        if ([vc isKindOfClass:[NTESSessionViewController class]]
//            && [vc.session.sessionId isEqualToString:notification.session.sessionId]) {
//            NIMMessageModel *model = [vc uiDeleteMessage:notification.message];
//            if (model) {
//                [vc uiInsertMessages:@[tipMessage]];
//            }
//            break;
//        }
//    }
//    
//    // saveMessage 方法执行成功后会触发 onRecvMessages: 回调，但是这个回调上来的 NIMMessage 时间为服务器时间，和界面上的时间有一定出入，所以要提前先在界面上插入一个和被删消息的界面时间相符的 Tip, 当触发 onRecvMessages: 回调时，组件判断这条消息已经被插入过了，就会忽略掉。
//    [[NIMSDK sharedSDK].conversationManager saveMessage:tipMessage
//                                             forSession:notification.session
//                                             completion:nil];
//}


#pragma mark - NIMSystemNotificationManagerDelegate
//- (void)onReceiveCustomSystemNotification:(NIMCustomSystemNotification *)notification{
//    
//    NSString *content = notification.content;
//    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
//    if (data)
//    {
//        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
//                                                             options:0
//                                                               error:nil];
//        if ([dict isKindOfClass:[NSDictionary class]])
//        {
//            if ([dict jsonInteger:NTESNotifyID] == NTESCustom)
//            {
//                //SDK并不会存储自定义的系统通知，需要上层结合业务逻辑考虑是否做存储。这里给出一个存储的例子。
//                NTESCustomNotificationObject *object = [[NTESCustomNotificationObject alloc] initWithNotification:notification];
//                //这里只负责存储可离线的自定义通知，推荐上层应用也这么处理，需要持久化的通知都走可离线通知
//                if (!notification.sendToOnlineUsersOnly) {
//                    [[NTESCustomNotificationDB sharedInstance] saveNotification:object];
//                }
//                if (notification.setting.shouldBeCounted) {
//                    [[NSNotificationCenter defaultCenter] postNotificationName:NTESCustomNotificationCountChanged object:nil];
//                }
//                NSString *content  = [dict jsonString:NTESCustomContent];
//                [[NTESMainTabController instance].selectedViewController.view makeToast:content duration:2.0 position:CSToastPositionCenter];
//            }
//        }
//    }
//}



#pragma mark - NIMNetCallManagerDelegate
//被叫接收通话响应方法 (自己点进去上层看一下)
- (void)onReceive:(UInt64)callID from:(NSString *)caller type:(NIMNetCallMediaType)type message:(NSString *)extendMessage{
    //处理扩展信息 (自己加的)
    NSDictionary *dic =(NSDictionary*)extendMessage;
    LSTempModel *model = [LSTempModel yy_modelWithJSON:dic];
    NSLog(@"%@",model);
    
    //拿到顶部控制器(用来判断当前用户是否在通话中)
    UIViewController *topRootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topRootViewController.presentedViewController)
    {
        topRootViewController = topRootViewController.presentedViewController;
    }

    //判断是否忙碌
    if ([self shouldResponseBusy]){
        
        [[NIMAVChatSDK sharedSDK].netCallManager control:callID type:NIMNetCallControlTypeBusyLine];
        
    }else {
        //    UIViewController *vc;
        LSVideoController* vc1;
        LSAudioController* vc2;
        
        switch (type) {
            case NIMNetCallTypeVideo:{
                vc1 = [[LSVideoController alloc] initWithCaller:caller callId:callID];
                vc1.headURLStr = model.headImg;
                vc1.nickName = model.nickName;
                
            }
                break;
            case NIMNetCallTypeAudio:{
                vc2 = [[LSAudioController alloc] initWithCaller:caller callId:callID];
                vc2.headURLStr = model.headImg;
                vc2.nickName = model.nickName;
            }
                break;
            default:
                break;
        }
        
        if (!vc1&&!vc2) {
            return;
        }
        
        //解决方法
        //    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:vc];
        if (vc1) {
            [topRootViewController presentViewController:vc1 animated:YES completion:nil];
        }else{
            [topRootViewController presentViewController:vc2 animated:YES completion:nil];
        }
    }
    
    

}

//- (void)onRTSRequest:(NSString *)sessionID
//                from:(NSString *)caller
//            services:(NSUInteger)types
//             message:(NSString *)info
//{
//    NTESMainTabController *tabVC = [NTESMainTabController instance];
//    
//    [tabVC.view endEditing:YES];
//
//    if ([self shouldResponseBusy]) {
//        [[NIMAVChatSDK sharedSDK].rtsManager responseRTS:sessionID accept:NO option:nil completion:nil];
//    }
//    else {
//        NTESWhiteboardViewController *vc = [[NTESWhiteboardViewController alloc] initWithSessionID:sessionID
//                                                                                            peerID:caller
//                                                                                             types:types
//                                                                                              info:info];
//        if (tabVC.presentedViewController) {
//            __weak NTESMainTabController *wtabVC = (NTESMainTabController *)tabVC;
//            [tabVC.presentedViewController dismissViewControllerAnimated:NO completion:^{
//                [wtabVC presentViewController:vc animated:NO completion:nil];
//            }];
//        }else{
//            [tabVC presentViewController:vc animated:NO completion:nil];
//        }
//    }
//}

- (BOOL)shouldResponseBusy
{

    //当前顶层页面是否为 通话页面
    return [[UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController isKindOfClass:[LSVideoController class]]||[[UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController isKindOfClass:[LSAudioController class]];
    
}




@end
