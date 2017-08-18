//
//  NetCallChatInfo.h
//  NIM
//
//  Created by chris on 15/5/12.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetCallChatInfo : NSObject

@property(nonatomic,strong) NSString *caller;//接听通话

@property(nonatomic,strong) NSString *callee;//发起通话

@property(nonatomic,assign) UInt64 callID;//通话成功ID

@property(nonatomic,assign) NIMNetCallMediaType callType;//音频还是视频

@property(nonatomic,assign) NSTimeInterval startTime;

@property(nonatomic,assign) BOOL isStart;

@property(nonatomic,assign) BOOL isMute;//是否静音

@property(nonatomic,assign) BOOL useSpeaker;//扬声器

@property(nonatomic,assign) BOOL disableCammera;

@property(nonatomic,assign) BOOL localRecording;

@property(nonatomic,assign) BOOL otherSideRecording;

@property(nonatomic,assign) BOOL audioConversation;

@end
