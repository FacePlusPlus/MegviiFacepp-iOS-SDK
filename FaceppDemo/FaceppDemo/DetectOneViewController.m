//
//  DetectOneViewController.m
//  FaceppDemo
//
//  Created by 张英堂 on 2016/11/8.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "DetectOneViewController.h"
#import "MGFacepp.h"
#import "MGFaceInfo.h"

@interface DetectOneViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *detectImage;
@property (weak, nonatomic) IBOutlet UILabel *messageView;

@property (nonatomic, strong) MGFacepp *markManager;

@end

@implementation DetectOneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    MGFacepp *markManager = [[MGFacepp alloc] initWithModel:modelData
                                              faceppSetting:^(MGFaceppConfig *config) {
                                                  config.orientation = 90;
                                              }];
    self.markManager = markManager;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startDetect:(id)sender {
    UIImage *image = [UIImage imageNamed:@"IMG_2393.JPG"];
    self.detectImage.image = image;
    
    
    MGImageData *imageData = [[MGImageData alloc] initWithImage:image];
    
    [self.markManager beginDetectionFrame];
    
    NSArray *faceArray = [self.markManager detectWithImageData:imageData];
    
    if (faceArray.count > 0) {
        MGFaceInfo *faceInfo = faceArray[0];
        [self.markManager GetGetLandmark:faceInfo isSmooth:YES pointsNumber:106];
        [self.markManager GetAttribute3D:faceInfo];

    }else{
        NSLog(@"IMG_2393.JPG 未检测到人脸");
    }
    [self.markManager endDetectionFrame];
    
    
    
    NSString *tempString = @"";
    if (faceArray.count > 0) {
        MGFaceInfo *info1 = faceArray[0];
        
        tempString = [NSString stringWithFormat:@"age:%.2f \npitch:%.2f \nyaw:%.2f \nroll:%.2f", info1.age, info1.pitch, info1.yaw, info1.roll];
        
        NSLog(@"%@", NSStringFromCGRect(info1.rect));
    }
    
    NSString *faceLog = [NSString stringWithFormat:@"人脸数量:%zi\n%@", faceArray.count, tempString];
    self.messageView.text = faceLog;
    
    NSLog(@"%@", faceArray);
}


@end
