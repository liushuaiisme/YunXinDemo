//
//  SVProgressHUD+Ext.m
//  clepil
//
//  Created by ksm on 2017/2/23.
//  Copyright © 2017年 KOUSO COSMATIC CO.LTD. All rights reserved.
//

#import "SVProgressHUD+Ext.h"

@implementation SVProgressHUD (Ext)




+(void)showErrorSVP: (NSString* )string{
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showErrorWithStatus:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        
    });
    
}
+(void)showWithSVP: (NSString* )string{
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showWithStatus:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        
    });
}

+(void)showSuccessSVP: (NSString* )string{
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD showSuccessWithStatus:string];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        
    });
    
}



@end
