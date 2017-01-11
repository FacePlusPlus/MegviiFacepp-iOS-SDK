//
//  NSDate+MGDate.m
//  LandMask
//
//  Created by 张英堂 on 16/8/25.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "NSDate+MGDate.h"

@implementation NSDate (MGDate)

- (NSString *)chageShortString{
    return [self dateWithFormat:@"yyyy-MM-dd"];
}

- (NSString *)dateWithFormat:(NSString *)format{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone localTimeZone];
    [dateFormatter setDateFormat:format];
    NSString *string = [dateFormatter stringFromDate:self];
    return string;
}


@end
