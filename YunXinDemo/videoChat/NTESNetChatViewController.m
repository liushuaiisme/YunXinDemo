//
//  NTESNetChatViewController.m
//  NIM
//
//  Created by chris on 15/5/18.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESNetChatViewController.h"
//#import "UIAlertView+NTESBlock.h"
//#import "UIView+Toast.h"
#import "NTESTimerHolder.h"
#import "NetCallChatInfo.h"
#import "NTESBundleSetting.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <Photos/Photos.h>
#import "UIView+NTES.h"

//十秒之后如果还是没有收到对方响应的control字段，则自己发起一个假的control，用来激活铃声并自己先进入房间
#define DelaySelfStartControlTime 10
//激活铃声后无人接听的超时时间
#define NoBodyResponseTimeOut 40

//周期性检查剩余磁盘空间
#define DiskCheckTimeInterval 10
//剩余磁盘空间不足的警告阈值
#define MB (1024ll * 1024ll)
#define FreeDiskSpaceWarningThreshold (10 * MB)


@interface NTESNetChatViewController ()

@property (nonatomic, strong) NTESTimerHolder *timer;

@property (nonatomic, strong) NSMutableArray *chatRoom;

@property (nonatomic, assign) BOOL recordWillStopForLackSpace;

@property (nonatomic, strong) NTESTimerHolder *diskCheckTimer;

@property (nonatomic, assign) BOOL userHangup;

@property (nonatomic, strong) NTESTimerHolder *calleeResponseTimer; //被叫等待用户响应接听或者拒绝的时间
@property (nonatomic, assign) BOOL calleeResponsed;

@property (nonatomic, assign) int successRecords;

//@property (nonatomic, strong) NTESRecordSelectView * recordView;



//临时
@property(nonatomic,strong)CAEAGLLayer *layer;
@property(nonatomic,strong)CAEAGLLayer *openGLLayer;
@property(nonatomic,assign)GLsizei bufferWidth;
@property(nonatomic,assign)GLsizei bufferHeight;
@property(nonatomic,strong)EAGLContext *context;
@property(nonatomic,assign)GLuint colorRenderBuffer;
@property(nonatomic,assign)GLuint framebuffers;
@property(nonatomic,assign)GLuint vertShader;

@end

@implementation NTESNetChatViewController

NTES_FORBID_INTERACTIVE_POP

-(instancetype)initWithCallee:(NSString *)callee{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.peerUid = callee;
        self.callInfo.callee = callee;
        self.callInfo.caller = [[NIMSDK sharedSDK].loginManager currentAccount];
    }
    return self;
}

- (instancetype)initWithCaller:(NSString *)caller callId:(uint64_t)callID{
    
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.peerUid = caller;
        self.callInfo.caller = caller;
        self.callInfo.callee = [[NIMSDK sharedSDK].loginManager currentAccount];
        self.callInfo.callID = callID;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.edgesForExtendedLayout = UIRectEdgeAll;
        if (!self.callInfo) {
            [[NIMSDK sharedSDK].mediaManager switchAudioOutputDevice:NIMAudioOutputDeviceSpeaker];
            _callInfo = [[NetCallChatInfo alloc] init];
        }
        _timer = [[NTESTimerHolder alloc] init];
        _diskCheckTimer = [[NTESTimerHolder alloc] init];
        //防止应用在后台状态，此时呼入，会走init但是不会走viewDidLoad,此时呼叫方挂断，导致被叫监听不到，界面无法消去的问题。
        id<NIMNetCallManager> manager = [NIMAVChatSDK sharedSDK].netCallManager;
        [manager addDelegate:self];
    }
    return self;
}

- (void)dealloc{
//    DDLogDebug(@"vc dealloc info : %@",self);
    [[NIMAVChatSDK sharedSDK].netCallManager removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak typeof(self) wself = self;
    //判断麦克风相机是否打开
    [self checkServiceEnable:^(BOOL result) {
        if (result) {
            
            [wself afterCheckService];
        }else{
            //用户禁用服务，干掉界面
            if (wself.callInfo.callID) {
                //说明是被叫方
                [[NIMAVChatSDK sharedSDK].netCallManager response:wself.callInfo.callID accept:NO option:nil completion:nil];
            }
                [wself dismiss:nil];
        }
    }];
    
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setUpStatusBar:UIStatusBarStyleLightContent];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.player stop];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)afterCheckService{
    if (self.callInfo.isStart) {
        [self.timer startTimer:0.5 delegate:self repeats:YES];
        [self onCalling];
    }
    else if (self.callInfo.callID) {
        [self startByCallee];
    }
    else {
        [self startByCaller];
    }
    
    [self checkFreeDiskSpace];
    [self.diskCheckTimer startTimer:DiskCheckTimeInterval
                           delegate:self
                            repeats:YES];
}

#pragma mark - Subclass Impl
- (void)startByCaller{
    
    if (self.callInfo.callType == NIMNetCallTypeVideo) {
        //视频呼叫马上发起
        [self doStartByCaller];
    }
    else {
        //语音呼叫先播放一断提示音，然后再发起 (不明白为什么要加延迟)
//        [self playConnnetRing];
        __weak typeof(self) wself = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!wself) {
                return;
            }
            if (wself.userHangup) {
//                DDLogError(@"Netcall request was cancelled before, ignore it.");
                return;
            }
            [wself doStartByCaller];
        });
    }
}

- (void)doStartByCaller
{
    
    self.callInfo.isStart = YES;
    NSArray *callees = [NSArray arrayWithObjects:self.callInfo.callee, nil];
    
    //这个类是通话参数,里面有很多可以设置的东西(像这种看不懂的类要多点进去看)
    NIMNetCallOption *option = [[NIMNetCallOption alloc] init];
    
    //传昵称和头像(自己增加的扩展)
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* headStr= [defaults valueForKey:@"headImgUrl"];
    NSString* nickName = [defaults valueForKey:@"nickName"];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setValue:headStr forKey:@"headImg"];
    [dic setValue:nickName forKey:@"nickName"];
    NSString* str = [dic yy_modelToJSONString];
    //你可以通过option这个扩展 传你想传的数据(在拨出通话的时候)
    option.extendMessage = str;
    
    //这是设置推送的显示内容
    option.apnsContent = [NSString stringWithFormat:@"来自用户 %@ %@请求",nickName, self.callInfo.callType == NIMNetCallTypeAudio ? @"网络通话" : @"视频聊天"];
    option.apnsSound = @"video_chat_tip_receiver.aac";
    [self fillUserSetting:option];
    
    //视频采集
    option.videoCaptureParam.startWithCameraOn = (self.callInfo.callType == NIMNetCallTypeVideo);
    //打开美颜开关
    option.videoCaptureParam.provideLocalVideoProcess = (self.callInfo.callType == NIMNetCallTypeVideo);

    __weak typeof(self) wself = self;

    [[NIMAVChatSDK sharedSDK].netCallManager start:callees type:wself.callInfo.callType option:option completion:^(NSError *error, UInt64 callID) {
        if (!error && wself) {
            wself.callInfo.callID = callID;
            wself.chatRoom = [[NSMutableArray alloc]init];
            
            //十秒之后如果还是没有收到对方响应的control字段，则自己发起一个假的control，用来激活铃声并自己先进入房间
            NSTimeInterval delayTime = DelaySelfStartControlTime;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself onControl:callID from:wself.callInfo.callee type:NIMNetCallControlTypeFeedabck];
            });
        }else{
            if (error) {
                NSLog(@" 连接失败： %@",error);
                [SVProgressHUD showErrorSVP:@"连接失败"];
//                [wself.navigationController.view makeToast:@"连接失败"
//                                                  duration:2
//                                                  position:CSToastPositionCenter];
            }else{
                //说明在start的过程中把页面关了。。
                [[NIMAVChatSDK sharedSDK].netCallManager hangup:callID];
            }
            [wself dismiss:nil];
        }
    }];
}

- (void)startByCallee{
    
    
    //告诉对方可以播放铃声了
    self.callInfo.isStart = YES;
    NSMutableArray *room = [[NSMutableArray alloc] init];
    [room addObject:self.callInfo.caller];
    self.chatRoom = room;
    [[NIMAVChatSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeFeedabck];
    [self playReceiverRing];
    _calleeResponseTimer = [[NTESTimerHolder alloc] init];
    [_calleeResponseTimer startTimer:NoBodyResponseTimeOut delegate:self repeats:NO];
}


//挂断
- (void)hangup{
    _userHangup = YES;
    [[NIMAVChatSDK sharedSDK].netCallManager hangup:self.callInfo.callID];
    
    if (self.callInfo.localRecording) {
        __weak typeof(self) wself = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            wself.chatRoom = nil;
            [wself dismiss:nil];
        });
    }
    else {
        
        self.chatRoom = nil;
        [self dismiss:nil];
    }
    

    
}

- (void)response:(BOOL)accept{
    
    _calleeResponsed = YES;
    
    NIMNetCallOption *option = [[NIMNetCallOption alloc] init];

    [self fillUserSetting:option];
    
    __weak typeof(self) wself = self;

    [[NIMAVChatSDK sharedSDK].netCallManager response:self.callInfo.callID accept:accept option:option completion:^(NSError *error, UInt64 callID) {
        if (!error) {
                [wself onCalling];
                [wself.player stop];
                [wself.chatRoom addObject:wself.callInfo.callee];
                NSTimeInterval delay = 10.f; //10秒后判断下房间
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (wself.chatRoom.count == 1) {
                        [SVProgressHUD showErrorSVP:@"通话失败"];
//                        [wself.navigationController.view makeToast:@"通话失败"
//                                                          duration:2
//                                                          position:CSToastPositionCenter];
                        [wself hangup];
                    }
                });
        }else{
            wself.chatRoom = nil;
            [SVProgressHUD showErrorSVP:@"连接失败"];
//            [wself.navigationController.view makeToast:@"连接失败"
//                                              duration:2
//                                              position:CSToastPositionCenter];
            [wself dismiss:nil];
        }
    }];
    //dismiss需要放在self后面，否在ios7下会有野指针
    if (accept) {
        [self waitForConnectiong];
    }else{
        [self dismiss:nil];
    }
}

- (void)dismiss:(void (^)(void))completion{

   
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}

- (void)onCalling{
    //子类重写
}

- (void)waitForConnectiong{
    //子类重写
}

- (void)onCalleeBusy
{
    //子类重写
}

-(BOOL)startAudioRecording
{
    UInt64 timestamp =[[NSDate date]timeIntervalSince1970]*1000;
    NSString * pathComponent = [NSString stringWithFormat:@"record_audio%@_%llu",[[NIMSDK sharedSDK].loginManager currentAccount],timestamp];
    NSURL *filePath = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:pathComponent];

    return [[NIMAVChatSDK sharedSDK].netCallManager startAudioRecording:filePath error:nil];
}
- (BOOL)startLocalRecording
{
    UInt64 timestamp =[[NSDate date]timeIntervalSince1970]*1000;
    NSString * pathComponent = [NSString stringWithFormat:@"record_%@_%llu.mp4",[[NIMSDK sharedSDK].loginManager currentAccount],timestamp];
    NSURL *filePath = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:pathComponent];
    
    BOOL startAccepted;
    startAccepted = [[NIMAVChatSDK sharedSDK].netCallManager startRecording:filePath
                                                               videoBitrate:(UInt32)[[NTESBundleSetting sharedConfig] localRecordVideoKbps] * 1000
                                                                        uid:[[NIMSDK sharedSDK].loginManager currentAccount]
];
    return startAccepted;
}

- (BOOL)startOtherSideRecording
{
    UInt64 timestamp =[[NSDate date]timeIntervalSince1970]*1000;
    NSString * pathComponent = [NSString stringWithFormat:@"record_%@_%llu.mp4",self.peerUid,timestamp];
    NSURL *filePath = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:pathComponent];

    
    BOOL startAccepted;
    startAccepted = [[NIMAVChatSDK sharedSDK].netCallManager startRecording:filePath
                                                               videoBitrate:(UInt32)[[NTESBundleSetting sharedConfig] localRecordVideoKbps] * 1000
                                                                        uid:self.peerUid
                     ];
    return startAccepted;
}

-(void)stopAudioRecording
{
    [[NIMAVChatSDK sharedSDK].netCallManager stopAudioRecording];
    self.callInfo.audioConversation = NO;
}

- (BOOL)stopLocalRecording
{
    return [[NIMAVChatSDK sharedSDK].netCallManager stopRecordingWithUid:[[NIMSDK sharedSDK].loginManager currentAccount]];
}

- (BOOL)stopOtherSideRecording
{
    return [[NIMAVChatSDK sharedSDK].netCallManager stopRecordingWithUid:self.peerUid];
}

- (void)udpateLowSpaceWarning:(BOOL)show
{
    //子类重写
}

-(void)recordWithAudioConversation:(BOOL)audioConversationOn myMedia:(BOOL)myMediaOn otherSideMedia:(BOOL)otherSideMediaOn video:(BOOL)isVideo
{
    NSString *toastText = @"";
    int records = 0;
    _successRecords = 0;//不包括语音对话
    //语音对话
    if (audioConversationOn) {
        records++;
        if (!self.callInfo.audioConversation) {
            toastText =@"语音对话开始失败";
        }
    }
    //自己音视频
    if (myMediaOn) {
        records++;
        if (![self startLocalRecording]) {
            if(isVideo)
            {
                toastText = [toastText stringByAppendingString: [toastText isEqualToString:@""] ?@"自己音视频开始失败":@",自己音视频开始失败"];
            }
            else
            {
                toastText = [toastText stringByAppendingString: [toastText isEqualToString:@""] ?@"自己音频开始失败":@",自己音频开始失败"];
            }
            
        }
        else
        _successRecords++;

    }
    //对方音视频
    if (otherSideMediaOn) {
        records++;
        if (![self startOtherSideRecording]) {
            if (isVideo) {
                toastText =[toastText stringByAppendingString:[toastText isEqualToString:@""] ?@"对方音视频开始失败":@",对方音视频开始失败"];
            }
            else
            {
                toastText =[toastText stringByAppendingString:[toastText isEqualToString:@""] ?@"对方音频开始失败":@",对方音频开始失败"];
            }

        }
        else
            _successRecords++;

    }
    
    //判断是否需要提示
    if (![toastText isEqualToString:@""]) {
        if ([toastText componentsSeparatedByString:@","].count == records) {
//            [self.view makeToast:@"开始录制失败"
//                        duration:2
//                        position:CSToastPositionCenter];
        }
        else
        {
//            [self.view makeToast:toastText
//                        duration:2
//                        position:CSToastPositionCenter];
        }
    }

}

- (void)stopRecordTaskWithVideo:(BOOL)isVideo
{
    NSString *toastText = @"";
    int records = 0;

    //结束自己音视频
    if (self.callInfo.localRecording) {
        records++;
        if (![self stopLocalRecording]) {
            if (isVideo) {
                toastText = [toastText stringByAppendingString: [toastText isEqualToString:@""] ?@"自己音视频结束失败":@",自己音视频结束失败"];
            }
            else
            {
                toastText = [toastText stringByAppendingString: [toastText isEqualToString:@""] ?@"自己音频结束失败":@",自己音频结束失败"];
            }

        }
    }
    //结束对方音视频
    if (self.callInfo.otherSideRecording) {
        records++;
        if (![self stopOtherSideRecording]) {
            if (isVideo) {
                toastText = [toastText stringByAppendingString: [toastText isEqualToString:@""] ?@"对方音视频结束失败":@",对方音视频结束失败"];
            }
            else
            {
                 toastText = [toastText stringByAppendingString: [toastText isEqualToString:@""] ?@"对方音频结束失败":@",对方音频结束失败"];
            }

        }
    }
    //判断是否要提示
    if (![toastText isEqualToString:@""]) {
        if ([toastText componentsSeparatedByString:@","].count == records) {
//            [self.view makeToast:@"结束录制失败"
//                        duration:3
//                        position:CSToastPositionCenter];
        }
        else
        {
//            [self.view makeToast:toastText
//                        duration:3
//                        position:CSToastPositionCenter];
        }
    }


}

-(BOOL)allRecordsStopped
{
    //当前没有录制任务
    if (!self.callInfo.localRecording&&!self.callInfo.otherSideRecording&&!self.callInfo.audioConversation) {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(BOOL)allRecordsSucceeed
{
    int num = self.callInfo.localRecording + self.callInfo.otherSideRecording;
    if (num == _successRecords) {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(NSString *)peerUid
{
    if (_peerUid) {
        return _peerUid;
    }
    else
    {
        if ([_callInfo.callee isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
            _peerUid =  _callInfo.caller;
            return _callInfo.caller;
        }
        else
        {
            _peerUid =  _callInfo.callee;
            return _callInfo.callee;
        }
    }
}

#pragma mark - NIMNetCallManagerDelegate
- (void)onControl:(UInt64)callID
             from:(NSString *)user
             type:(NIMNetCallControlType)control{
    
    if (user == [[NIMSDK sharedSDK].loginManager currentAccount]) {
        //多端登录时，自己会收到自己发出的控制指令，这里忽略他
        return;
    }
    
    if (callID != self.callInfo.callID) {
        return;
    }
    
    switch (control) {
        case NIMNetCallControlTypeFeedabck:{
            NSMutableArray *room = self.chatRoom;
            if (room && !room.count && !_userHangup) {
                [self playSenderRing];
                [room addObject:self.callInfo.caller];
                //40秒之后查看一下房间状态，如果房间还在一个人的话，就播放铃声超时
                __weak typeof(self) wself = self;
                uint64_t callId = self.callInfo.callID;
                NSTimeInterval delayTime = NoBodyResponseTimeOut;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSMutableArray *room = wself.chatRoom;
                    if (wself && room && room.count == 1) {
                        [[NIMAVChatSDK sharedSDK].netCallManager hangup:callId];
                        wself.chatRoom = nil;
                        [wself playTimeoutRing];
                        [SVProgressHUD showErrorSVP:@"暂时无人接听"];
//                        [wself.navigationController.view makeToast:@"无人接听"
//                                                          duration:2
//                                                          position:CSToastPositionCenter];
                        [wself dismiss:nil];
                    }
                });
            }
            break;
        }
        case NIMNetCallControlTypeBusyLine: {
            [self onCalleeBusy];
            [self playOnCallRing];
            _userHangup = YES;
            //对方忙碌需要挂断当前通话, 通话id应该为0;
            [[NIMAVChatSDK sharedSDK].netCallManager hangup:0];
            [SVProgressHUD showErrorSVP:@"对不起,当前主播正忙"];
            __weak typeof(self) wself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself dismiss:nil];
            });
            break;
        }
        case NIMNetCallControlTypeStartRecord:
//            [self.view makeToast:@"对方开始了录制"
//                        duration:1
//                        position:CSToastPositionCenter];
            break;
        case NIMNetCallControlTypeStopRecord:
//            [self.view makeToast:@"对方结束了录制"
//                        duration:1
//                        position:CSToastPositionCenter];
            break;
        default:
            break;
    }
}

- (void)onResponse:(UInt64)callID from:(NSString *)callee accepted:(BOOL)accepted{
    if (self.callInfo.callID == callID) {
        if (!accepted) {
            self.chatRoom = nil;
            [SVProgressHUD showErrorSVP:@"暂时无人接听"];
//            [self.navigationController.view makeToast:@"对方拒绝接听"
//                                             duration:2
//                                             position:CSToastPositionCenter];
            [self playHangUpRing];
            __weak typeof(self) wself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself dismiss:nil];
            });

        }else{
            [self.player stop];
            [self onCalling];
            [self.chatRoom addObject:callee];
        }
    }
}

//点对点通话建立成功
-(void)onCallEstablished:(UInt64)callID
{

    if (self.callInfo.callID == callID) {
        self.callInfo.startTime = [NSDate date].timeIntervalSince1970;
        [self.timer startTimer:0.5 delegate:self repeats:YES];
    }
    
}

//通话异常断开
- (void)onCallDisconnected:(UInt64)callID withError:(NSError *)error
{
    if (self.callInfo.callID == callID) {
        [self.timer stopTimer];
        [self dismiss:nil];
        self.chatRoom = nil;
    }
}


- (void)onResponsedByOther:(UInt64)callID
                  accepted:(BOOL)accepted{
    [SVProgressHUD showWithSVP:@"已在其他端处理"];
//    [self.view.window makeToast:@"已在其他端处理"
//                       duration:2
//                       position:CSToastPositionCenter];
    [self dismiss:nil];
}

//对方挂断电话
- (void)onHangup:(UInt64)callID
              by:(NSString *)user{

    if (self.callInfo.callID == callID) {
        
        [self.player stop];
        if (self.callInfo.localRecording) {
            __weak typeof(self) wself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself dismiss:nil];
            });
        }
        else {
            [SVProgressHUD showWithSVP:@"当前通话结束"];
            [self dismiss:nil];
            
        }
    }
}

//录制成功开始
- (void)onRecordStarted:(UInt64)callID fileURL:(NSURL *)fileURL uid:(NSString *)userId
{
    if (self.callInfo.callID == callID) {
        if ([userId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
            self.callInfo.localRecording = YES;
        }
        if ([userId isEqualToString:self.peerUid]) {
            self.callInfo.otherSideRecording = YES;
        }
    }
}


//录制发生了错误
- (void)onRecordError:(NSError *)error
                    callID:(UInt64)callID
                       uid:(NSString *)userId
{
//    DDLogError(@"Local record error %@ (%zd)", error.localizedDescription, error.code);
    
    if (self.callInfo.callID == callID) {
        
//        [self.view makeToast:[NSString stringWithFormat:@"录制发生错误: %zd", error.code]
//                    duration:2
//                    position:CSToastPositionCenter];

        if ([userId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
            self.callInfo.localRecording = NO;
        }
        if ([userId isEqualToString:self.peerUid]) {
            self.callInfo.otherSideRecording = NO;
        }

    }
    
    if (error.code == NIMAVLocalErrorCodeRecordWillStopForLackSpace) {
        _recordWillStopForLackSpace = YES;
    }
}
//录制成功结束
- (void) onRecordStopped:(UInt64)callID
                      fileURL:(NSURL *)fileURL
                          uid:(NSString *)userId
{
    if (self.callInfo.callID == callID) {
        if ([userId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
            self.callInfo.localRecording = NO;
        }
        if ([userId isEqualToString:self.peerUid]) {
            self.callInfo.otherSideRecording = NO;
        }
        //辅助验证: 写到系统相册
        [self requestAuthorizationSaveToPhotosAlbum:fileURL];
    }
}

#pragma mark - NTESRecordSelectViewDelegate

-(void)onRecordWithAudioConversation:(BOOL)audioConversationOn myMedia:(BOOL)myMediaOn otherSideMedia:(BOOL)otherSideMediaOn
{
    //子类重写
}

#pragma mark - M80TimerHolderDelegate
- (void)onNTESTimerFired:(NTESTimerHolder *)holder{
    if (holder == self.diskCheckTimer) {
        [self checkFreeDiskSpace];
    }
    else if(holder == self.calleeResponseTimer) {
        if (!_calleeResponsed) {
            [SVProgressHUD showErrorSVP:@"接听超时"];
//            [self.navigationController.view makeToast:@"接听超时"
//                                              duration:2
//                                              position:CSToastPositionCenter];
            [self response:NO];
        }
    }
}


#pragma mark - Misc
- (void)checkServiceEnable:(void(^)(BOOL))result{
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            dispatch_async_main_safe(^{
                //提供顶层视图(如果当前界面不在顶层,弹不出提示框,所以用顶层视图来弹出)
                UIViewController *topRootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
                while (topRootViewController.presentedViewController)
                {
                    topRootViewController = topRootViewController.presentedViewController;
                }
                if (granted) {
                    NSString *mediaType = AVMediaTypeVideo;
                    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
                    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
                        
                        if (result) {
                            result(NO);
                        }
                        
                        UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"相机权限受限,无法音视频聊天" message:@"如还想使用此功能，请在手机设置中打开照相机"  preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *act2=[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        }];
                        [alert addAction:act2];
                        [topRootViewController presentViewController:alert animated:YES completion:nil];
                        
                    }else{
                        if (result) {
                            result(YES);
                        }
                    }
                }
                else {
                    
                    if (result) {
                        result(NO);
                    }
                    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"麦克风权限受限,无法音视频聊天" message:@"如还想使用此功能，请在手机设置中打开麦克风"  preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *act2=[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    }];
                    
                    [alert addAction:act2];
                    [topRootViewController presentViewController:alert animated:YES completion:nil];

                }

            });
        }];
    }
}

- (void)setUpStatusBar:(UIStatusBarStyle)style{
    [[UIApplication sharedApplication] setStatusBarStyle:style
                                                animated:NO];
}

- (void)requestAuthorizationSaveToPhotosAlbum:(NSURL *)fileURL
{
    __weak typeof(self) wself = self;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusRestricted || status == PHAuthorizationStatusDenied)
            {
                //没有权限
                dispatch_async_main_safe(^{
//                                             [wself.navigationController.view makeToast:@"保存失败,没有相册权限"
//                                                                               duration:3
//                                                                               position:CSToastPositionCenter];
                                         });
            }
            else if (status == PHAuthorizationStatusAuthorized)
            {
                //有权限
                [wself saveToPhotosAlbum:fileURL];
            }
        }];
    }
    else
    {
        [self saveToPhotosAlbum:fileURL];
    }
    
}

- (void)saveToPhotosAlbum:(NSURL *)fileURL
{
    if (fileURL) {
        __weak typeof(self) wself = self;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeVideoAtPathToSavedPhotosAlbum:fileURL
                                        completionBlock:^(NSURL *assetURL, NSError *error) {
                                            [wself checkVideoSaveToAlbum:error];
                                        }];
        }
        else
        {
            [[PHPhotoLibrary sharedPhotoLibrary]performChanges:^{
                [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
            }
                                             completionHandler:^(BOOL success, NSError * _Nullable error) {
                                                 dispatch_async_main_safe(^{
                                                     [wself checkVideoSaveToAlbum:error];
                                                 });
                                             }];
        }
    }
}

- (void)checkVideoSaveToAlbum:(NSError *)error
{
    NSString *toast = _recordWillStopForLackSpace ? @"你的手机内存不足，录制已结束\n" : @"录制已结束\n";
    
    if (error) {
        toast = [NSString stringWithFormat:@"%@保存至系统相册失败:%zd", toast, error.code];
    }
    else {
        toast = [toast stringByAppendingString:@"录制文件已保存至系统相册"];
    }
    
    if (!self.callInfo.localRecording&&!self.callInfo.otherSideRecording&&_successRecords==1) {
//        [self.navigationController.view makeToast:toast
//                                          duration:3
//                                          position:CSToastPositionCenter];
    }
    _successRecords--;
}

- (void)checkFreeDiskSpace{
    
    if (self.callInfo.localRecording) {
        uint64_t freeSpace = 1000 * MB;
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSDictionary *attrbites = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
        
        if (attrbites) {
            NSNumber *freeFileSystemSizeInBytes = [attrbites objectForKey:NSFileSystemFreeSize];
            freeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        
            [self udpateLowSpaceWarning:(freeSpace < FreeDiskSpaceWarningThreshold)];
        }
    }
}


- (void)fillUserSetting:(NIMNetCallOption *)option
{
    
    option.autoRotateRemoteVideo = [[NTESBundleSetting sharedConfig] videochatAutoRotateRemoteVideo];
    option.serverRecordAudio     = [[NTESBundleSetting sharedConfig] serverRecordAudio];
    option.serverRecordVideo     = [[NTESBundleSetting sharedConfig] serverRecordVideo];
    option.preferredVideoEncoder = [[NTESBundleSetting sharedConfig] perferredVideoEncoder];
    option.preferredVideoDecoder = [[NTESBundleSetting sharedConfig] perferredVideoDecoder];
    option.videoMaxEncodeBitrate = [[NTESBundleSetting sharedConfig] videoMaxEncodeKbps] * 1000;
    option.autoDeactivateAudioSession = [[NTESBundleSetting sharedConfig] autoDeactivateAudioSession];
    option.audioDenoise = [[NTESBundleSetting sharedConfig] audioDenoise];
    option.voiceDetect = [[NTESBundleSetting sharedConfig] voiceDetect];
    option.preferHDAudio =  [[NTESBundleSetting sharedConfig] preferHDAudio];
    
    NIMNetCallVideoCaptureParam *param = [[NIMNetCallVideoCaptureParam alloc] init];
    [self fillVideoCaptureSetting:param];
    option.videoCaptureParam = param;
    param.videoCrop  = [[NTESBundleSetting sharedConfig] videochatVideoCrop];
}

- (void)fillVideoCaptureSetting:(NIMNetCallVideoCaptureParam *)param
{
    param.preferredVideoQuality = [[NTESBundleSetting sharedConfig] preferredVideoQuality];
    param.startWithBackCamera   = [[NTESBundleSetting sharedConfig] startWithBackCamera];
    //上层做美颜处理
    param.videoHandler = ^(CMSampleBufferRef  _Nonnull sampleBuffer) {
        //四中效果
        //[[NIMAVChatSDK sharedSDK].netCallManager selectBeautifyType:NIMNetCallFilterTypeMeiyan1];
        //磨皮强度
        [[NIMAVChatSDK sharedSDK].netCallManager setSmoothFilterIntensity:0.7];
        //两种方式显示在本地镜像
        //[[NIMAVChatSDK sharedSDK].netCallManager setCodeMirror:YES];
        [[NIMAVChatSDK sharedSDK].netCallManager setPreViewMirror:YES];
        //发送SampleBuffer
        [[NIMAVChatSDK  sharedSDK].netCallManager sendVideoSampleBuffer:sampleBuffer];
    };
}






#pragma mark - Ring
//铃声 - 正在呼叫请稍后
- (void)playConnnetRing{
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_connect_chat_tip_sender" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.player play];
}

//铃声 - 对方暂时无法接听
- (void)playHangUpRing{
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_HangUp" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.player play];
}

//铃声 - 对方正在通话中
- (void)playOnCallRing{
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_OnCall" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.player play];
}

//铃声 - 对方无人接听
- (void)playTimeoutRing{
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_onTimer" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.player play];
}

//铃声 - 接收方铃声
- (void)playReceiverRing{
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_receiver" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.player.numberOfLoops = 20;
    [self.player play];
}

//铃声 - 拨打方铃声
- (void)playSenderRing{
    [self.player stop];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video_chat_tip_sender" withExtension:@"aac"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.player.numberOfLoops = 20;
    [self.player play];
}



@end
