//
//  MGFaceModelArray.m
//  LandMask
//
//  Created by 张英堂 on 16/8/17.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGFaceModelArray.h"

@implementation MGFaceModelArray

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timeUsed = 0;
        self.detectRect = CGRectZero;
    }
    return self;
}

- (void)addModel:(MGFaceInfo *)model{
    [self.faceArray addObject:model];
}

- (MGFaceInfo *)modelWithIndex:(NSUInteger)index{
    MGFaceInfo *model = [self.faceArray objectAtIndex:index];

    return model;
}

-(NSMutableArray<MGFaceInfo *> *)faceArray{
    if (!_faceArray) {
        _faceArray = [NSMutableArray arrayWithCapacity:5];
    }
    return _faceArray;
}

-(NSUInteger)count{
    return self.faceArray.count;
}

- (NSString *)getDebugString{
    
    NSMutableString *tempString = [NSMutableString string];
    [tempString appendFormat:@"关键点:%.2f ms", self.timeUsed];
    [tempString appendFormat:@"\n3D角度:%.2f ms", self.AttributeTimeUsed];
    
    NSMutableString *conficeString = [NSMutableString string];

    if (self.count >= 1) {
        MGFaceInfo *model = [self modelWithIndex:0];
        [conficeString appendFormat:@"\n质量:%.2f", model.confidence];
        [conficeString appendFormat:@"\n年龄:%.2f", model.age];
        NSString *gender = model.gender == 1 ? @"男":@"女";
        [conficeString appendFormat:@"\n性别:%@", gender];
    }

    [tempString appendString:conficeString];
    
    return tempString;
}

@end
