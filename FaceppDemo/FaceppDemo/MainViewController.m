//
//  MainViewController.m
//  FaceppDemo
//
//  Created by 张英堂 on 2017/1/11.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "MainViewController.h"
#import "MGFaceLicenseHandle.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    /** 进行联网授权版本判断，联网授权就需要进行网络授权 */
    BOOL needLicense = [MGFaceLicenseHandle getNeedNetLicense];
    
    if (needLicense) {
        [MGFaceLicenseHandle licenseForNetwokrFinish:^(bool License, NSDate *sdkDate) {
            
            NSLog(@"本次联网授权是否成功 %d, SDK 过期时间：%@", License, sdkDate);
        }];
    }else{
        NSDate *date = [MGFaceLicenseHandle getLicenseDate];
        NSLog(@"SDK 为非联网授权版本！过期时间为:%@", date);
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
