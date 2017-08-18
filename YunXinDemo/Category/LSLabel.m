//
//  LSLabel.m
//  YouYue_ios
//
//  Created by 刘帅 on 2017/5/10.
//  Copyright © 2017年 HuiChuang. All rights reserved.
//

#import "LSLabel.h"

@implementation LSLabel

- (instancetype)init {
    if (self = [super init]) {
        _textInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _textInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _textInsets)];
}

@end
