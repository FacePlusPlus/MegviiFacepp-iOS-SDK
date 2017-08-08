//
//  MainViewController.m
//  FaceppDemo
//
//  Created by 张英堂 on 2017/1/11.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "MainViewController.h"
#import "MGFaceLicenseHandle.h"

#import "MGFacepp.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UILabel *messageView;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if MG_USE_ONLINE_AUTH

    /** 进行联网授权版本判断，联网授权就需要进行网络授权 */
    BOOL needLicense = [MGFaceLicenseHandle getNeedNetLicense];
    
    if (1) {
        [MGFaceLicenseHandle licenseForNetwokrFinish:^(bool License, NSDate *sdkDate) {
            NSLog(@"本次联网授权是否成功 %d, SDK 过期时间：%@", License, sdkDate);
        }];
    }
#else
    NSLog(@"SDK 为非联网授权版本！");
#endif
    NSDictionary *tempDic = @{@"0":@"Track",
                              @"1":@"Detect",
                              @"2":@"Pose3d",
                              @"3":@"EyeStatus",
                              @"4":@"MouseStatus",
                              @"5":@"Minority",
                              @"6":@"Blurness",
                              @"7":@"AgeGender",
                              @"8":@"ExtractFeature",};
    
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    MGAlgorithmInfo *sdkInfo = [MGFacepp getSDKAlgorithmInfoWithModel:modelData];
    
    NSMutableString *tempString = [NSMutableString stringWithString:@""];
    
    [tempString appendFormat:@"\n%@: %@",NSLocalizedString(@"debug_message1", nil), sdkInfo.needNetLicense?@"YES":@"NO"];
    [tempString appendFormat:@"\n%@: %@",NSLocalizedString(@"debug_message2", nil),sdkInfo.version];
    [tempString appendFormat:@"\n%@: {\n", NSLocalizedString(@"debug_message3", nil)];
    
    for (int i = 0; i < sdkInfo.SDKAbility.count; i++) {
        NSNumber *tempValue = (NSNumber *)sdkInfo.SDKAbility[i];
        NSInteger function = [tempValue integerValue];
        
        NSString *temp = [tempDic valueForKey:[NSString stringWithFormat:@"%zi", function]];
        [tempString appendFormat:@"    %@", temp];
        [tempString appendString:@",\n"];
    }
    [tempString appendString:@"}"];

    [self.messageView setText:tempString];

    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"navigationBar_back", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
