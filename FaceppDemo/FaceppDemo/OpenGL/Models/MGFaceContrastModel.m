//
//  MGFaceContrastModel.m
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "MGFaceContrastModel.h"
#import "MGConvertImage.h"

static NSString *faceCount = @"MGFaceContrastModelFaceCount";

@implementation MGFaceContrastModel

- (instancetype)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer faceInfo:(MGFaceInfo *)faceInfo{
    if (self = [super init]) {
        _feature = faceInfo.featureData;
        UIImage *image = [MGConvertImage convertSampleBufferToImage:sampleBuffer];
        _image = [MGConvertImage imageFromImage:image inRect:faceInfo.rect];
        CGPoint point = [faceInfo.points[33] CGPointValue];
        _center = CGPointMake(point.y, point.x);
        _trackID = faceInfo.trackID;
    }
    return self;
}

- (void)getName{
    if (![[NSUserDefaults standardUserDefaults] integerForKey:faceCount]) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:faceCount];
    }
    NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:faceCount];
    count ++;
    _name = [NSString stringWithFormat:@"user_%ld",count];
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:faceCount];
}


- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.feature forKey:@"feature"];
    [aCoder encodeObject:self.image forKey:@"image"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.selected] forKey:@"selected"];
}


- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.feature = [aDecoder decodeObjectForKey:@"feature"];
        self.image = [aDecoder decodeObjectForKey:@"image"];
        self.selected = [aDecoder decodeObjectForKey:@"selected"];
    }
    return self;
}




@end
