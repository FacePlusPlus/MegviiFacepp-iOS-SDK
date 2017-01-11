//
//  YTLogManager.m
//  BankCardTest
//
//  Created by 张英堂 on 15/12/9.
//  Copyright © 2015年 megvii. All rights reserved.
//

#import "MGLogManager.h"
#import "MGBaseDefine.h"

static NSString *const YTLogfolderName = @"com.megvii.log";

@interface MGLogManager ()

@property (nonatomic, strong) NSString *logBasePath;
@property (nonatomic, strong) NSFileManager *fileManager;

@end


@implementation MGLogManager

+(instancetype)sharedInstance{
    static MGLogManager *logManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logManager = [[MGLogManager alloc] init];
    });
    return logManager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *path = [paths objectAtIndex:0];
        self.logBasePath = [NSTemporaryDirectory() stringByAppendingPathComponent:YTLogfolderName];
        self.fileManager = [NSFileManager defaultManager];
        
        BOOL isDir = NO;
        BOOL existed = [self.fileManager fileExistsAtPath:self.logBasePath isDirectory:&isDir];
        if ( !(isDir == YES && existed == YES) )
        {
            [self.fileManager createDirectoryAtPath:self.logBasePath
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:nil];
        }
        
    }
    return self;
}

- (void)addLog:(NSString *)logString fileName:(NSString *)fileName{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *path = [self.logBasePath stringByAppendingPathComponent:fileName];
        
        NSFileHandle *outFile = [NSFileHandle fileHandleForWritingAtPath:path];
        if(outFile == nil)
        {
            MGLog(@"****目标文件不存在，重新创建\n");
            NSError *error;
            [logString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                MGLog(@"%@: 写入失败%@", NSStringFromClass([self class]), error);
            }else {
                MGLog(@"%@: 写入成功", NSStringFromClass([self class]));
            }
        }else{
            [outFile seekToEndOfFile];
            
            NSData *writeBuffer = [logString dataUsingEncoding:NSUTF8StringEncoding];
            [outFile writeData:writeBuffer];
            
            [outFile closeFile];
        }
    });
}

@end
