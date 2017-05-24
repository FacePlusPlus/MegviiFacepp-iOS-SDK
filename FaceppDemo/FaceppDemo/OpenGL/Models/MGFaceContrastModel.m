//
//  MGFaceContrastModel.m
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "MGFaceContrastModel.h"
#import <MGBaseKit/MGImage.h>

static NSString *faceCount = @"MGFaceContrastModelFaceCount";

@implementation MGFaceContrastModel

- (instancetype)initWithImage:(UIImage *)image faceInfo:(MGFaceInfo *)faceInfo{
    if (self = [super init]) {
        _feature = faceInfo.featureData;
        
        // 将检测出的人脸框放大
        float x = faceInfo.rect.origin.x;
        float y = faceInfo.rect.origin.y;
        float width = faceInfo.rect.size.width;
        float height = faceInfo.rect.size.height;
        CGRect rect = CGRectMake(x-width/2, y-height/5 , width*1.8, height*1.4);
        
        _image = [MGImage croppedImage:image rect:rect];
        _image = [UIImage imageWithCGImage:[_image CGImage]
                                     scale:[_image scale]
                               orientation:UIImageOrientationLeftMirrored];
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
