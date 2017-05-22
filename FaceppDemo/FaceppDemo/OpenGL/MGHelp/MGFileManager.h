//
//  MGFileManager.h
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/22.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MGFileManager : NSObject

+ (void)saveModels:(NSArray *)models;

+ (NSArray *)getModels;

@end
