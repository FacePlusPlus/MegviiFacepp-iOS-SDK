//
//  MGFaceListViewController.h
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGFaceCompareModel.h"

@interface MGFaceListViewController : UIViewController

+ (instancetype)storyboardInstance;

@property (nonatomic, strong) NSArray *models;

@end
