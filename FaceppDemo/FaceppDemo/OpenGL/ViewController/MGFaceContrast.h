//
//  MGFaceContrast.h
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGFaceContrastModel.h"

@interface MGFaceContrast : UIViewController

+ (instancetype)storyboardInstance;

@property (nonatomic, strong) NSArray *models;

@end
