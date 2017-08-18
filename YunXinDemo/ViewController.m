//
//  ViewController.m
//  YunXinDemo
//
//  Created by HCMac on 2017/7/6.
//  Copyright © 2017年 demo. All rights reserved.
//

#import "ViewController.h"

#import "LSAudioController.h"
#import "LSVideoController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//点击语音聊天
- (IBAction)didClickAudio:(id)sender {
    
    //这个参数 自己修改成创建好的 云信账号
    LSAudioController* vc =[[LSAudioController alloc]initWithCallee:NIMCount2];
    //这两个参数是我用来传递姓名头像地址
    vc.nickName = @"被叫宝宝";
    vc.headURLStr = @"suibiansuibian";
    
    [self presentViewController:vc animated:YES completion:nil];
}


//点击视频聊天
- (IBAction)didClickVideo:(id)sender {
    //这个参数 自己修改成创建好的 云信账号
    LSVideoController* vc =[[LSVideoController alloc]initWithCallee:NIMCount2];
    //这两个参数是我用来传递姓名头像地址
    vc.nickName = @"被叫宝宝";
    vc.headURLStr = @"suibiansuibian";
    
    
    [self presentViewController:vc animated:YES completion:nil];
    
    
}



@end
