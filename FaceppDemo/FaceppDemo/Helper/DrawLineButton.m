//
//  DrawLineButton.m
//  MGSDKV2Test
//
//  Created by 张英堂 on 16/9/9.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "DrawLineButton.h"

@implementation DrawLineButton

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {

    [self.layer setMasksToBounds:YES];
    [self.layer setCornerRadius:0.0]; //设置矩圆角半径
    [self.layer setBorderWidth:2.0f];   //边框宽度
    [self.layer setBorderColor:[UIColor whiteColor].CGColor];//边框颜色

}

@end
