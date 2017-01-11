//
//  TextModel.m
//  MGSDKV2Test
//
//  Created by 张英堂 on 2016/10/21.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "TextModel.h"

@implementation TextModel

+ (instancetype)modelWith:(NSString *)title text:(NSString *)text{
    TextModel *model = [[TextModel alloc] init];
    model.title = title;
    model.text = text;
    
    
    return model;
}

@end
