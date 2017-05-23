//
//  MGFaceContrastModel.h
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MGImageData.h"
#import "MGFaceInfo.h"

@interface MGFaceContrastModel : NSObject <NSCoding>

- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer faceInfo:(MGFaceInfo *)faceInfo;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSData *feature;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) BOOL selected;

//@property (nonatomic, copy) NSString *maybeName;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) NSInteger trackID;

- (void)getName;

@end
