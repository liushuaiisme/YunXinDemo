//
//  LSVideoController.m
//  YouYue_ios
//
//  Created by HCMac on 2017/5/10.
//  Copyright © 2017年 HuiChuang. All rights reserved.
//

#import "LSVideoController.h"
#import "NTESGLView.h"
#import "NTESBundleSetting.h"
#import "NetCallChatInfo.h"
#import "NTESBundleSetting.h"
#import "NTESVideoChatNetStatusView.h"
#import "LSLabel.h"



#define NTESUseGLView


@interface LSVideoController ()

@property (nonatomic,assign) NIMNetCallCamera cameraType;
//大背景
@property(nonatomic,strong)UIImageView* bigVideoView;
//小背景
@property (nonatomic, strong)UIImageView *smallVideoView;
//通话时长
@property (nonatomic,strong) UILabel  *durationLabel;
//挂断
@property(nonatomic,strong)UIButton* hungUpBtn;
//返回
@property(nonatomic,strong)UIButton* backBtn;
//拨打视频界面头像
@property(nonatomic,strong)UIImageView* headImage;
//用户姓名
@property(nonatomic,strong)UILabel* nameLabel;
//价格
@property(nonatomic,strong)UILabel* priceLabel;
//固定提示
@property(nonatomic,strong)UILabel* cueLabel;
//警告提示
@property(nonatomic,strong)UILabel* ausgLabel;
//接听按钮
@property(nonatomic,strong)UIButton* acceptBtn;
//静音切换按钮
@property(nonatomic,strong)UIButton* muteBtn;
//前后摄像头切换
@property(nonatomic,strong)UIButton* switchCameraBtn;
//礼物按钮
@property(nonatomic,strong)UIButton* giftBtn;
//切换扬声器按钮
@property(nonatomic,strong)UIButton* speakerBtn;


@property (nonatomic,weak) UIView   *localView;
@property (nonatomic,strong) UIView *localVideoLayer;

@property (nonatomic, assign) BOOL calleeBasy;
@property (nonatomic,assign) BOOL oppositeCloseVideo;

#if defined (NTESUseGLView)
@property (nonatomic, strong) NTESGLView *remoteGLView;
#endif

@property (nonatomic,strong)NTESVideoChatNetStatusView *netStatusView;//网络状况

//额外用来判断点击屏幕清空界面
@property(nonatomic,assign)BOOL isTouch;
//区别大小视图
@property(nonatomic,assign)int type;


@end

@implementation LSVideoController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.callInfo.callType = NIMNetCallTypeVideo;
        self.callInfo.useSpeaker = YES;
        _cameraType = [[NTESBundleSetting sharedConfig] startWithBackCamera] ? NIMNetCallCameraBack :NIMNetCallCameraFront;
    }
    return self;
}



- (void)viewDidLoad {
    self.localView = self.smallVideoView;
    [super viewDidLoad];
    if (self.localVideoLayer) {
        self.localVideoLayer.frame = self.localView.bounds;
        [self.localView addSubview:self.localVideoLayer];
    }
    //设置UI
    [self initUI];
    //大小视图判断
    self.type = 1;
    
    //尝试点击小背景
    UITapGestureRecognizer*tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(Actiondo:)];
    self.smallVideoView.userInteractionEnabled = YES;
    [self.smallVideoView addGestureRecognizer:tapGesture];
}



#pragma mark - 设置UI
-(void)initUI{
    
    self.bigVideoView.userInteractionEnabled = YES;
    
    //大窗口
    [self.view addSubview:self.bigVideoView];
    [self.bigVideoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    //小窗口
    [self.view addSubview:self.smallVideoView];
    [self.smallVideoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-45*WIDTH_SIZE);
        make.top.offset(70*HEIGHT_SIZE);
        make.width.offset(140*WIDTH_SIZE);
        make.height.offset(200*HEIGHT_SIZE);
    }];
    //挂断电话
    [self.view addSubview: self.hungUpBtn];
    [self.hungUpBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bigVideoView);
        make.bottom.equalTo(self.bigVideoView).offset(-100*HEIGHT_SIZE);
    }];
    //返回按钮
    [self.view addSubview: self.backBtn];
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(35*WIDTH_SIZE);
        make.top.offset(45*HEIGHT_SIZE);
    }];
    //头像图片
    [self.view addSubview:self.headImage];
    [self.headImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.offset(150*WIDTH_SIZE);
        make.width.height.offset(150*WIDTH_SIZE);
    }];
    //姓名
    [self.view addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headImage.mas_bottom).offset(25*HEIGHT_SIZE);
        make.centerX.equalTo(self.view);
    }];
    //价格
    [self.view addSubview:self.priceLabel];
    [self.priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(70*HEIGHT_SIZE);
        make.centerX.equalTo(self.view);
    }];
    //提示文字
    [self.view addSubview:self.cueLabel];
    [self.cueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.priceLabel.mas_bottom).offset(25*HEIGHT_SIZE);
        make.centerX.equalTo(self.view);
    }];
    //提示警告文字
    LSLabel* ausgLabel = [[LSLabel alloc]init];
    self.ausgLabel = ausgLabel;
    ausgLabel.text = @"根据相关规定，互联网直播服务使用者不得利用互联网直播服务从事危害国家安全、破坏社会稳定、扰乱社会秩序、侵犯他人合法权益、传播淫秽色情等法律法规禁止的活动，不得利用互联网直播服务制作、复制、发布、传播法律法规禁止的信息内容。";
    ausgLabel.textColor = [UIColor whiteColor];
    ausgLabel.backgroundColor = [UIColor colorWithRed:(27)/255.0 green:(27)/255.0 blue:(28)/255.0 alpha:0.5];
    ausgLabel.font = [UIFont systemFontOfSize:12];
    ausgLabel.numberOfLines = 0;
    ausgLabel.textInsets = UIEdgeInsetsMake(0, 5, 0, 5);
    [self.view addSubview:self.ausgLabel];
    [self.ausgLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cueLabel.mas_bottom).offset(70*HEIGHT_SIZE);
        make.centerX.equalTo(self.view);
        make.width.offset(550*WIDTH_SIZE);
        make.height.offset(250*HEIGHT_SIZE);
    }];
    //通话时长
    [self.view addSubview:self.durationLabel];
    [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(45*HEIGHT_SIZE);
        make.centerX.equalTo(self.view).offset(-15*WIDTH_SIZE);
        
    }];
    //网络状态
    [self.view addSubview:self.netStatusView];
    [self.netStatusView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.durationLabel.mas_right).offset(15*WIDTH_SIZE);
        make.top.equalTo(self.durationLabel);
    }];
    //接听按钮
    [self.view addSubview:self.acceptBtn];
    [self.acceptBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.offset(-150*HEIGHT_SIZE);
    }];
    
    //切换扬声器
    [self.view addSubview:self.speakerBtn];
    [self.speakerBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX).offset(-55*WIDTH_SIZE);
        make.bottom.offset(-250*HEIGHT_SIZE);
    }];
    //静音按钮
    [self.view addSubview:self.muteBtn];
    [self.muteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.speakerBtn);
        make.centerX.equalTo(self.speakerBtn.mas_centerX).offset(-100*WIDTH_SIZE);
    }];
    //切换摄像头按钮
    [self.view addSubview:self.switchCameraBtn];
    [self.switchCameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX).offset(55*WIDTH_SIZE);
        make.top.equalTo(self.speakerBtn);
        
    }];
    //礼物按钮
    [self.view addSubview:self.giftBtn];
    [self.giftBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.speakerBtn);
        make.centerX.equalTo(self.switchCameraBtn.mas_centerX).offset(100*WIDTH_SIZE);
    }];
    
    //    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
    //        [self initRemoteGLView: self.type];
    //    }
    
    
    
    
}

//接收界面 初始化界面
#pragma mark - Call Life 接收界面 初始化界面
- (void)startByCaller{
    [super startByCaller];
    //正在接听中界面
    [self startInterface];
}
- (void)startByCallee{
    [super startByCallee];
    //选择是否接听界面
    [self waitToCallInterface];
}
- (void)onCalling{
    [super onCalling];
    //接听中界面(视频)
    [self videoCallingInterface];
}
- (void)waitForConnectiong{
    [super waitForConnectiong];
    //连接对方界面
    [self connectingInterface];
}
- (void)onCalleeBusy{
    _calleeBasy = YES;
    if (_localVideoLayer) {
        [_localVideoLayer removeFromSuperview];
    }
}


#pragma mark - Interface 4种界面
//正在接听中界面
- (void)startInterface{
    
    self.acceptBtn.hidden = YES;
    self.hungUpBtn.hidden   = NO;
    self.headImage.hidden = NO;
    self.nameLabel.hidden = NO;
    self.priceLabel.hidden = NO;
    self.cueLabel.hidden = NO;
    self.cueLabel.text = @"她即将接受你的邀请";
    self.ausgLabel.hidden = NO;
    self.backBtn.hidden = YES;
    self.muteBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.giftBtn.hidden = YES;
    self.speakerBtn.hidden = YES;
    
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
    self.localView = self.bigVideoView;
    
}

//选择是否接听界面
- (void)waitToCallInterface{
    
    self.acceptBtn.hidden = NO;
    self.hungUpBtn.hidden   = YES;
    self.nameLabel.hidden = NO;
    self.headImage.hidden = NO;
    self.priceLabel.hidden = NO;
    self.cueLabel.hidden = NO;
    self.cueLabel.text = @"请尽快接受他的视频邀请";
    self.backBtn.hidden = NO;
    self.muteBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.giftBtn.hidden = YES;
    self.speakerBtn.hidden = YES;
    
    //拿到发起者姓名
    //    self.nameLabel.text = self.nickName;
    
    //    NSString *nick = [NTESSessionUtil showNick:self.callInfo.caller inSession:nil];
    //    self.connectingLabel.text = [nick stringByAppendingString:@"的来电"];
    
    [self.backBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn addTarget:self action:@selector(didClickVideoBay:) forControlEvents:UIControlEventTouchUpInside];
    
}

//连接对方界面
- (void)connectingInterface{
    
    self.acceptBtn.hidden = YES;
    self.backBtn.hidden = YES;
    self.nameLabel.hidden = YES;
    self.headImage.hidden = YES;
    self.priceLabel.hidden = YES;
    self.cueLabel.hidden = NO;
    self.cueLabel.text = @"正在连接对方...请稍后...";
    self.ausgLabel.hidden = YES;
    self.hungUpBtn.hidden   = YES;
    self.muteBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.giftBtn.hidden = YES;
    self.speakerBtn.hidden = YES;
    
    //    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    //    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
}

//接听中界面(视频)
- (void)videoCallingInterface{
    
    //网络状态
    NIMNetCallNetStatus status = [[NIMAVChatSDK sharedSDK].netCallManager netStatus:self.peerUid];
    [self.netStatusView refreshWithNetState:status];
    
    self.acceptBtn.hidden = YES;
    self.hungUpBtn.hidden   = NO;
    self.headImage.hidden = YES;
    self.nameLabel.hidden = YES;
    self.priceLabel.hidden = YES;
    self.cueLabel.hidden = YES;
    self.ausgLabel.hidden = YES;
    
    self.backBtn.hidden = YES;
    self.muteBtn.hidden = NO;
    self.switchCameraBtn.hidden = NO;
    self.speakerBtn.hidden = NO;
    self.giftBtn.hidden = NO;
    
    
    self.muteBtn.selected = self.callInfo.isMute;
    self.speakerBtn.selected = !self.callInfo.useSpeaker;
    
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
    self.localVideoLayer.hidden = NO;
    
    //点击背景清空屏幕
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.bigVideoView addGestureRecognizer:singleTap];
    
}


#pragma mark - 拿取视频数据源方法
- (void)initRemoteGLView :(int)type{
#if defined (NTESUseGLView)
    _remoteGLView = [[NTESGLView alloc] init];
    [_remoteGLView setContentMode:[[NTESBundleSetting sharedConfig] videochatRemoteVideoContentMode]];
    [_remoteGLView setBackgroundColor:[UIColor clearColor]];
    _remoteGLView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //切换大小视图画面
    if (self.type == 0) {
        _remoteGLView.frame = _smallVideoView.bounds;
        [_smallVideoView addSubview:_remoteGLView];
        self.type = 1;
        if (self.localView == self.smallVideoView) {
            self.localView = self.bigVideoView;
            if (self.localVideoLayer) {
                [self onLocalDisplayviewReady:self.localVideoLayer];
            }
        }
    }else{
        _remoteGLView.frame = _bigVideoView.bounds;
        [_bigVideoView addSubview:_remoteGLView];
        self.type = 0;
        if (self.localView == self.bigVideoView) {
            self.localView = self.smallVideoView;
            if (self.localVideoLayer) {
                [self onLocalDisplayviewReady:self.localVideoLayer];
            }
        }
        
    }
    
    
#endif
}


#pragma mark - NIMNetCallManagerDelegate

//本地摄像头预览层回调
-(void)onLocalDisplayviewReady:(UIView *)displayView{
    if (_calleeBasy) {
        return;
    }
    if (self.localVideoLayer) {
        [self.localVideoLayer removeFromSuperview];
    }
    self.localVideoLayer = displayView;
    displayView.frame = self.localView.bounds;
    [self.localView.layer addSublayer:displayView.layer];
    
}


#if defined(NTESUseGLView)
- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    if (([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) && !self.oppositeCloseVideo) {
        
        if (!_remoteGLView) {
            [self initRemoteGLView: self.type];
        }
        [_remoteGLView render:yuvData width:width height:height];
    }
}
#else
- (void)onRemoteImageReady:(CGImageRef)image{
    if (self.oppositeCloseVideo) {
        return;
    }
    self.bigVideoView.contentMode = UIViewContentModeScaleAspectFill;
    self.bigVideoView.image = [UIImage imageWithCGImage:image];
}
#endif


//收到对方网络通话控制信息，用于方便通话双方沟通信息
- (void)onControl:(UInt64)callID
             from:(NSString *)user
             type:(NIMNetCallControlType)control{
    [super onControl:callID from:user type:control];
    switch (control) {
        case NIMNetCallControlTypeToAudio:
            //            [self switchToAudio];
            break;
        case NIMNetCallControlTypeCloseVideo:
            //            [self resetRemoteImage];
            self.oppositeCloseVideo = YES;
            [SVProgressHUD showErrorSVP:@"对方关闭了摄像头"];
            break;
        case NIMNetCallControlTypeOpenVideo:
            self.oppositeCloseVideo = NO;
            [SVProgressHUD showErrorSVP:@"对方开启了摄像头"];
            break;
        default:
            break;
    }
}



//点对点通话建立成功
-(void)onCallEstablished:(UInt64)callID
{
    if (self.callInfo.callID == callID) {
        [super onCallEstablished:callID];
        
        self.durationLabel.hidden = NO;
        self.durationLabel.text = self.durationDesc;
        
        //        if (self.localView == self.bigVideoView) {
        //            self.localView = self.smallVideoView;
        //
        //            if (self.localVideoLayer) {
        //                [self onLocalPreviewReady:self.localVideoLayer];
        //            }
        //        }
    }
    
    
}
//当前通话网络状态
- (void)onNetStatus:(NIMNetCallNetStatus)status user:(NSString *)user
{
    NSLog(@"当前网络通话状态： %ld",(long)status);
    if ([user isEqualToString:self.peerUid]) {
        [self.netStatusView refreshWithNetState:status];
    }
}

//通话时长
- (void)onNTESTimerFired:(NTESTimerHolder *)holder{
    [super onNTESTimerFired:holder];
    self.durationLabel.text = self.durationDesc;
    
}


//显示时间
- (NSString*)durationDesc{
    if (!self.callInfo.startTime) {
        return @"";
    }
    
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    NSTimeInterval duration = time - self.callInfo.startTime;
    
    return [NSString stringWithFormat:@"%02d:%02d",(int)duration/60,(int)duration%60];
}

//- (void)resetRemoteImage{
//#if defined (NTESUseGLView)
//    [self.remoteGLView render:nil width:0 height:0];
//#endif
//
//    self.bigVideoView.image = [UIImage imageNamed:@"netcall_bkg"];
//}

#pragma mark - 相应点击事件处理
//点击接听按钮
-(void)didClickGet: (UIButton* )sender{
    
    BOOL accept = (sender == self.acceptBtn);
    //防止用户在点了接收后又点拒绝的情况
    [self response:accept];
    
}
//点击拒绝按钮

-(void)didClickVideoBay: (UIButton* )sender{
    [self response:NO];
}


//点击静音按钮
-(void)muteDidChick: (UIButton* )sender{
    
    self.callInfo.isMute = !self.callInfo.isMute;
    //    self.player.volume = !self.callInfo.isMute;
    [[NIMAVChatSDK sharedSDK].netCallManager setMute:self.callInfo.isMute];
    self.muteBtn.selected = self.callInfo.isMute;
    
}
//切换摄像头
-(void)switchCamerDidChick: (UIButton* )sender{
    
    if (self.cameraType == NIMNetCallCameraFront) {
        self.cameraType = NIMNetCallCameraBack;
    }else{
        self.cameraType = NIMNetCallCameraFront;
    }
    [[NIMAVChatSDK sharedSDK].netCallManager switchCamera:self.cameraType];
    self.switchCameraBtn.selected = (self.cameraType == NIMNetCallCameraBack);
    
}
//礼物按钮
-(void)giftDidChick: (UIButton *)sender{
    
}
//切换扬声器
-(void)speakerDidChick: (UIButton* )sender{
    
    self.callInfo.useSpeaker = !self.callInfo.useSpeaker;
    self.speakerBtn.selected = !self.callInfo.useSpeaker;
    [[NIMAVChatSDK sharedSDK].netCallManager setSpeaker:self.callInfo.useSpeaker];
}
//小视图点击事件
-(void)Actiondo: (id)sender{
    
    [self initRemoteGLView: self.type];
    //    NSLog(@"点击了小视图");
    
    
    
}
//大视图点击清空屏幕事件
- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
    if (!_isTouch) {
        NSLog(@"隐藏");
        self.hungUpBtn.hidden = YES;
        self.muteBtn.hidden = YES;
        self.switchCameraBtn.hidden = YES;
        self.giftBtn.hidden = YES;
        self.speakerBtn.hidden = YES;
        self.smallVideoView.hidden = YES;
        self.netStatusView.hidden = YES;
        self.durationLabel.hidden = YES;
        _isTouch = YES;
        
    }else{
        NSLog(@"显示");
        self.hungUpBtn.hidden = NO;
        self.muteBtn.hidden = NO;
        self.switchCameraBtn.hidden = NO;
        self.giftBtn.hidden = NO;
        self.speakerBtn.hidden = NO;
        self.smallVideoView.hidden = NO;
        self.netStatusView.hidden = NO;
        self.durationLabel.hidden = NO;
        _isTouch = NO;
    }
    
}

#pragma mark - 懒加载
//懒加载
//大背景
-(UIImageView* )bigVideoView{
    if (!_bigVideoView) {
        _bigVideoView = [[UIImageView alloc]init];
        [_bigVideoView setImage:[UIImage imageNamed:@"netcall_bkg"]];
    }
    return _bigVideoView;
}
//小背景
-(UIImageView* )smallVideoView{
    if (!_smallVideoView) {
        _smallVideoView = [[UIImageView alloc]init];
        
    }
    return _smallVideoView;
}
//-(UIView* )localView{
//    if (!_localView) {
//        _localView = [[UIView alloc]init];
//    }
//    return _localView;
//}

//发起视频界面 挂断电话 按钮
-(UIButton* )hungUpBtn{
    if (!_hungUpBtn) {
        _hungUpBtn = [[UIButton alloc]init];
        [_hungUpBtn setImage:[UIImage imageNamed:@"icon7"] forState:UIControlStateNormal];
    }
    return _hungUpBtn;
}

//发起视频头像
-(UIImageView* )headImage{
    if (!_headImage) {
        _headImage = [[UIImageView alloc]init];
        //拿到发起者头像地址
        NSURL *url = [NSURL URLWithString:self.headURLStr];
        [self.headImage sd_setImageWithURL:url placeholderImage: [UIImage imageNamed:@"headImage"]];
        _headImage.layer.cornerRadius = 75*WIDTH_SIZE;
        _headImage.layer.masksToBounds = YES;
    }
    return _headImage;
}
//用户姓名
-(UILabel* )nameLabel{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        
        if (self.nickName) {
            _nameLabel.text = self.nickName;
        }else{
            _nameLabel.text = @"美女用户";
        }
        
    }
    return _nameLabel;
}
//发起视频价格
-(UILabel* )priceLabel{
    if (!_priceLabel) {
        _priceLabel = [[UILabel alloc]init];
        _priceLabel.font = [UIFont systemFontOfSize:12];
        _priceLabel.textColor = [UIColor redColor];
        _priceLabel.textAlignment = NSTextAlignmentCenter;
        _priceLabel.text = @"2金币/分钟";
    }
    return _priceLabel;
}
//中间提示Label
-(UILabel* )cueLabel{
    if (!_cueLabel) {
        _cueLabel = [[UILabel alloc]init];
        _cueLabel.textAlignment = NSTextAlignmentCenter;
        _cueLabel.textColor = [UIColor whiteColor];
        _cueLabel.font = [UIFont systemFontOfSize:12];
        
    }
    return _cueLabel;
}

//左上角 八叉关闭页面
-(UIButton* )backBtn{
    if (!_backBtn) {
        _backBtn = [[UIButton alloc]init];
        [_backBtn setImage:[UIImage imageNamed:@"chatroom_back_normal"] forState:UIControlStateNormal];
    }
    return _backBtn;
}

//通话时长
-(UILabel* )durationLabel{
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc]init];
        _durationLabel.font = [UIFont systemFontOfSize:14];
        _durationLabel.textColor = [UIColor whiteColor];
    }
    return _durationLabel;
}
//网络状态
-(NTESVideoChatNetStatusView* )netStatusView{
    if (!_netStatusView) {
        _netStatusView = [[NTESVideoChatNetStatusView alloc]init];
        _netStatusView.backgroundColor = [UIColor clearColor];
    }
    return _netStatusView;
}
//接听按钮
-(UIButton* )acceptBtn{
    if (!_acceptBtn) {
        _acceptBtn = [[UIButton alloc]init];
        [_acceptBtn setImage:[UIImage imageNamed:@"icon7"] forState:UIControlStateNormal];
        [_acceptBtn addTarget:self action:@selector(didClickGet:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _acceptBtn;
    
}
//静音按钮
-(UIButton* )muteBtn{
    if (!_muteBtn) {
        _muteBtn = [[UIButton alloc]init];
        [_muteBtn setImage:[UIImage imageNamed:@"video_icon2"] forState:UIControlStateNormal];
        [_muteBtn setImage:[UIImage imageNamed:@"video_icon2_n"] forState:UIControlStateSelected];
        [_muteBtn addTarget:self action:@selector(muteDidChick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _muteBtn;
}
//切换摄像头
-(UIButton* )switchCameraBtn{
    if (!_switchCameraBtn) {
        _switchCameraBtn = [[UIButton alloc]init];
        [_switchCameraBtn setImage:[UIImage imageNamed:@"video_icon1"] forState:UIControlStateNormal];
        [_switchCameraBtn setImage:[UIImage imageNamed:@"video_icon1_n"] forState:UIControlStateSelected];
        [_switchCameraBtn addTarget:self action:@selector(switchCamerDidChick:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _switchCameraBtn;
}
//礼物按钮
-(UIButton* )giftBtn{
    if (!_giftBtn) {
        int type = [[[NSUserDefaults standardUserDefaults]valueForKey:@"type"] intValue];
        if (type == 0) {
            _giftBtn = [[UIButton alloc]init];
            [_giftBtn setImage:[UIImage imageNamed:@"video_icon3"] forState:UIControlStateNormal];
            [_giftBtn addTarget:self action:@selector(giftDidChick:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    return _giftBtn;
}
//切换扬声器按钮
-(UIButton* )speakerBtn{
    if (!_speakerBtn) {
        _speakerBtn = [[UIButton alloc]init];
        [_speakerBtn setImage:[UIImage imageNamed:@"video_icon4"] forState:UIControlStateNormal];
        [_speakerBtn setImage:[UIImage imageNamed:@"video_icon4_n"] forState:UIControlStateSelected];
        [_speakerBtn addTarget:self action:@selector(speakerDidChick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _speakerBtn;
}




@end
