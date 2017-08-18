//
//  LSAudioController.m
//  YouYue_ios
//
//  Created by HCMac on 2017/5/11.
//  Copyright © 2017年 HuiChuang. All rights reserved.
//

#import "LSAudioController.h"
#import "NetCallChatInfo.h"
#import "LSLabel.h"



@interface LSAudioController ()


//背景图片
@property(nonatomic,strong)UIImageView* backgroundImage;
//用户头像
@property(nonatomic,strong)UIImageView* headImage;
//用户姓名
@property(nonatomic,strong)UILabel* nameLabel;
//价格
@property(nonatomic,strong)UILabel* priceLabel;
//文字提示
@property(nonatomic,strong)UILabel* cueLabel;
//重要警告
@property(nonatomic,strong)LSLabel* ausgLabel;
//请求界面/聊天页面 挂断按钮
@property(nonatomic,strong)UIButton* hungUpBtn;
//静音
@property(nonatomic,strong)UIButton* muteBtn;
//切换扬声器
@property(nonatomic,strong)UIButton* speakerBtn;
//时间提示
@property(nonatomic,strong)UILabel* durationLabel;
//返回
@property(nonatomic,strong)UIButton* backBtn;


@end

@implementation LSAudioController


//父类方法
-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.callInfo.callType = NIMNetCallTypeAudio;
    }
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置UI
    [self initUI];
    
}

-(void)initUI{
    
    //设置背景图片
    [self.view addSubview:self.backgroundImage];
    [self.backgroundImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    //头像
    [self.view addSubview:self.headImage];
    [self.headImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.offset(150*HEIGHT_SIZE);
        make.width.height.offset(150*HEIGHT_SIZE);
    }];
    //姓名
    [self.view addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headImage.mas_bottom).offset(80*HEIGHT_SIZE);
        make.centerX.equalTo(self.view);
    }];
    //价格
    [self.view addSubview:self.priceLabel];
    [self.priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(25*HEIGHT_SIZE);
        make.centerX.equalTo(self.view);
    }];
    //提示
    [self.view addSubview:self.cueLabel];
    [self.cueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.priceLabel.mas_bottom).offset(50*HEIGHT_SIZE);
        make.centerX.equalTo(self.view);
    }];
    //警告
    [self.view addSubview:self.ausgLabel];
    [self.ausgLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cueLabel.mas_bottom).offset(30*HEIGHT_SIZE);
        make.centerX.equalTo(self.view);
        make.width.offset(550*WIDTH_SIZE);
        make.height.offset(250*HEIGHT_SIZE);
    }];
    //挂断
    [self.view addSubview:self.hungUpBtn];
    [self.hungUpBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-100*HEIGHT_SIZE);
    }];
    //返回按钮
    [self.view addSubview: self.backBtn];
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(35*WIDTH_SIZE);
        make.top.offset(45*HEIGHT_SIZE);
    }];
    
    //静音
    [self.view addSubview:self.muteBtn];
    [self.muteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(ScreenWidh/3);
        make.bottom.offset(-300*HEIGHT_SIZE);
        
    }];
    //扬声器
    [self.view addSubview:self.speakerBtn];
    [self.speakerBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-ScreenWidh/3);
        make.bottom.equalTo(self.muteBtn);
        
    }];
    //通话时间
    [self.view addSubview:self.durationLabel];
    [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(25*HEIGHT_SIZE);
        make.centerX.equalTo(self.view);
    }];
    
    
}

#pragma mark - Call Life
- (void)startByCaller{
    [super startByCaller];
    [self startInterface];
}

- (void)startByCallee{
    [super startByCallee];
    [self waitToCallInterface];
}

- (void)onCalling{
    [super onCalling];
    [self audioCallingInterface];
}

- (void)waitForConnectiong{
    [super onCalling];
    [self connectingInterface];
}

#pragma mark - Interface
//正在接听中界面
- (void)startInterface{
    
    self.hungUpBtn.hidden  = NO;
    self.headImage.hidden = NO;
    self.nameLabel.hidden = NO;
    self.priceLabel.hidden = NO;
    self.cueLabel.hidden = NO;
    self.cueLabel.text = @"她即将接受你的邀请";
    self.ausgLabel.hidden = NO;
    self.muteBtn.hidden = YES;
    self.speakerBtn.hidden = YES;
    self.durationLabel.hidden = YES;
    self.backBtn.hidden = YES;
    
    [self.hungUpBtn setImage:[UIImage imageNamed:@"icon7"] forState:UIControlStateNormal];
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
    
}

//选择是否接听界面
- (void)waitToCallInterface{
    self.hungUpBtn.hidden   = NO;
    self.nameLabel.hidden = NO;
    self.headImage.hidden = NO;
    self.priceLabel.hidden = NO;
    self.cueLabel.hidden = NO;
    self.cueLabel.text = @"请尽快接受他的语音邀请";
    self.ausgLabel.hidden = NO;
    self.muteBtn.hidden = YES;
    self.speakerBtn.hidden = YES;
    self.durationLabel.hidden = YES;
    self.backBtn.hidden = NO;
    
    [self.hungUpBtn setImage:[UIImage imageNamed:@"icon7"] forState:UIControlStateNormal];
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(didClickGet:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.backBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn addTarget:self action:@selector(didClickAudioBay:) forControlEvents:UIControlEventTouchUpInside];
    
    
}

//连接对方界面
- (void)connectingInterface{
    
    self.nameLabel.hidden = YES;
    self.headImage.hidden = YES;
    self.priceLabel.hidden = YES;
    self.cueLabel.hidden = NO;
    self.cueLabel.text = @"正在连接对方...请稍后...";
    self.ausgLabel.hidden = YES;
    self.hungUpBtn.hidden = YES;
    self.muteBtn.hidden = YES;
    self.speakerBtn.hidden = YES;
    self.durationLabel.hidden = YES;
    self.backBtn.hidden = YES;
    
    
}

//接听中界面(音频)
- (void)audioCallingInterface{
    
    //    NSString *peerUid = ([[NIMSDK sharedSDK].loginManager currentAccount] == self.callInfo.caller) ? self.callInfo.callee : self.callInfo.caller;
    ////
    //    NIMNetCallNetStatus status = [[NIMAVChatSDK sharedSDK].netCallManager netStatus:peerUid];
    //    [self.netStatusView refreshWithNetState:status];
    
    self.hungUpBtn.hidden   = NO;
    self.headImage.hidden = NO;
    self.nameLabel.hidden = NO;
    self.priceLabel.hidden = YES;
    self.cueLabel.hidden = YES;
    self.ausgLabel.hidden = YES;
    self.muteBtn.hidden = NO;
    self.speakerBtn.hidden = NO;
    self.durationLabel.hidden = NO;
    self.backBtn.hidden = YES;
    
    self.muteBtn.selected    = self.callInfo.isMute;
    self.speakerBtn.selected = self.callInfo.useSpeaker;
    
    [self.hungUpBtn setImage:[UIImage imageNamed:@"icon7"] forState:UIControlStateNormal];
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
}


//点对点通话建立成功
-(void)onCallEstablished:(UInt64)callID
{
    
    if (self.callInfo.callID == callID) {
        [super onCallEstablished:callID];
        
        self.durationLabel.hidden = NO;
        self.durationLabel.text = self.durationDesc;
    }
}

//当前通话网络状态
//- (void)onNetStatus:(NIMNetCallNetStatus)status user:(NSString *)user
//{
//    if ([user isEqualToString:self.peerUid]) {
////        [self.netStatusView refreshWithNetState:status];
//    }
//}
//通话时长
#pragma mark - M80TimerHolderDelegate
- (void)onNTESTimerFired:(NTESTimerHolder *)holder{
    [super onNTESTimerFired:holder];
    self.durationLabel.text = self.durationDesc;
}

#pragma mark -  Misc
- (NSString*)durationDesc{
    if (!self.callInfo.startTime) {
        return @"";
    }
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    NSTimeInterval duration = time - self.callInfo.startTime;
    
    return [NSString stringWithFormat:@"%02d:%02d",(int)duration/60,(int)duration%60];
}



//接受请求
-(void)didClickGet: (UIButton* )sender{
    
    BOOL accept = (sender == self.hungUpBtn);
    //防止用户在点了接收后又点拒绝的情况
    [self response:accept];
}

//点击拒绝按钮
-(void)didClickAudioBay: (UIButton* )sender{
    
    
    [self response:NO];
}


//点击静音按钮
-(void)muteDidChick: (UIButton* )sender{
    
    self.callInfo.isMute = !self.callInfo.isMute;
    //    self.player.volume = !self.callInfo.isMute;
    [[NIMAVChatSDK sharedSDK].netCallManager setMute:self.callInfo.isMute];
    self.muteBtn.selected = self.callInfo.isMute;
    
}

//切换扬声器
-(void)speakerDidChick: (UIButton* )sender{
    
    self.callInfo.useSpeaker = !self.callInfo.useSpeaker;
    self.speakerBtn.selected = self.callInfo.useSpeaker;
    [[NIMAVChatSDK sharedSDK].netCallManager setSpeaker:self.callInfo.useSpeaker];
}




#pragma mark - lazy
//懒加载

//背景图片
-(UIImageView* )backgroundImage{
    if (!_backgroundImage) {
        _backgroundImage = [[UIImageView alloc]init];
        [_backgroundImage setImage:[UIImage imageNamed:@"netcall_bkg"]];
    }
    return _backgroundImage;
}

//左上角 八叉关闭页面
-(UIButton* )backBtn{
    if (!_backBtn) {
        _backBtn = [[UIButton alloc]init];
        [_backBtn setImage:[UIImage imageNamed:@"chatroom_back_normal"] forState:UIControlStateNormal];
    }
    return _backBtn;
}

//头像
-(UIImageView* )headImage{
    if (!_headImage) {
        _headImage = [[UIImageView alloc]init];
        //配置头像
        NSURL *url = [NSURL URLWithString:self.headURLStr];
        [self.headImage sd_setImageWithURL:url placeholderImage: [UIImage imageNamed:@"headImage"]];
        _headImage.layer.cornerRadius = 75*WIDTH_SIZE;
        _headImage.layer.masksToBounds = YES;
    }
    return _headImage;
}
//姓名
-(UILabel*)nameLabel{
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
//价格
-(UILabel*)priceLabel{
    if (!_priceLabel) {
        _priceLabel = [[UILabel alloc]init];
        _priceLabel.font = [UIFont systemFontOfSize:12];
        _priceLabel.textColor = [UIColor redColor];
        _priceLabel.textAlignment = NSTextAlignmentCenter;
        _priceLabel.text = @"1金币/每分钟";
        
    }
    return _priceLabel;
}
//提示
-(UILabel*)cueLabel{
    if (!_cueLabel) {
        _cueLabel = [[UILabel alloc]init];
        _cueLabel.textColor = [UIColor whiteColor];
        _cueLabel.font = [UIFont systemFontOfSize:12];
        _cueLabel.textAlignment = NSTextAlignmentCenter;
        
    }
    return _cueLabel;
}
//警告
-(LSLabel*)ausgLabel{
    if (!_ausgLabel) {
        _ausgLabel = [[LSLabel alloc]init];
        _ausgLabel.text = @"根据相关规定，互联网直播服务使用者不得利用互联网直播服务从事危害国家安全、破坏社会稳定、扰乱社会秩序、侵犯他人合法权益、传播淫秽色情等法律法规禁止的活动，不得利用互联网直播服务制作、复制、发布、传播法律法规禁止的信息内容。";
        _ausgLabel.textColor = [UIColor whiteColor];
        _ausgLabel.backgroundColor = [UIColor colorWithRed:(27)/255.0 green:(27)/255.0 blue:(28)/255.0 alpha:0.5];
        _ausgLabel.font = [UIFont systemFontOfSize:12];
        _ausgLabel.numberOfLines = 0;
        _ausgLabel.textInsets = UIEdgeInsetsMake(0, 5, 0, 5);
        
    }
    return _ausgLabel;
}

//挂断按钮
-(UIButton* )hungUpBtn{
    if (!_hungUpBtn) {
        _hungUpBtn = [[UIButton alloc]init];
        
    }
    return _hungUpBtn;
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
//切换扬声器按钮
-(UIButton* )speakerBtn{
    if (!_speakerBtn) {
        _speakerBtn = [[UIButton alloc]init];
        [_speakerBtn setImage:[UIImage imageNamed:@"video_icon4_n"] forState:UIControlStateNormal];
        [_speakerBtn setImage:[UIImage imageNamed:@"video_icon4"] forState:UIControlStateSelected];
        [_speakerBtn addTarget:self action:@selector(speakerDidChick:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _speakerBtn;
}
//通话时间
-(UILabel* )durationLabel{
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc]init];
        _durationLabel.font = [UIFont systemFontOfSize:14];
        _durationLabel.textColor = [UIColor whiteColor];
        
    }
    return _durationLabel;
}

@end
