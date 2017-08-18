//
//  SVProgressHUD+Ext.h
//  clepil
//
//  Created by ksm on 2017/2/23.
//  Copyright © 2017年 KOUSO COSMATIC CO.LTD. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>

@interface SVProgressHUD (Ext)


//错误
+(void)showErrorSVP: (NSString* )string;
//加载
+(void)showWithSVP: (NSString* )string;
//对勾
+(void)showSuccessSVP: (NSString* )string;


@end
