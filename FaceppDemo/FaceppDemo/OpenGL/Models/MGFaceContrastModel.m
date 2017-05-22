//
//  MGFaceContrastModel.m
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "MGFaceContrastModel.h"

@implementation MGFaceContrastModel

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
