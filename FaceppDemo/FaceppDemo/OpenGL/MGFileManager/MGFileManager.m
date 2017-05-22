//
//  MGFileManager.m
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/22.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "MGFileManager.h"

static NSString *fileName = @"fileName";

@implementation MGFileManager

- (NSString *)filePath:(NSString *)fileName{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *document = [paths lastObject];
    return [NSString stringWithFormat:@"%@/%@",document,fileName];
}

- (void)saveModels:(NSArray *)models{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createFileAtPath:[self filePath:fileName] contents:nil attributes:nil];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:models];
    [data writeToFile:[self filePath:fileName] atomically:NO];
}

- (NSArray *)getModels{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSData *data = [fileManager contentsAtPath:[self filePath:fileName]];
    return (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end
