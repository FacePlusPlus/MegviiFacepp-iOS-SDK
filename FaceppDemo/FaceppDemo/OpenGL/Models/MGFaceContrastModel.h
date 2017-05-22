//
//  MGFaceContrastModel.h
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MGFaceContrastModel : NSObject <NSCoding>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSData *feature;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) BOOL selected;

@end
