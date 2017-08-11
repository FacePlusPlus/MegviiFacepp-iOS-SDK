//
//  MGFaceCompareModel.h
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MGImageData.h"
#import "MGFaceInfo.h"

@interface MGFaceCompareModel : NSObject <NSCoding>

- (instancetype)initWithImage:(UIImage *)image faceInfo:(MGFaceInfo *)faceInfo;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSData *feature;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) BOOL selected;

@property (nonatomic, assign) NSInteger trackID;

- (void)getName;

@end
