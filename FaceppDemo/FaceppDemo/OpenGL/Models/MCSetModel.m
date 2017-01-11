//
//  MCSetModel.m
//  MGSDKV2Test
//
//  Created by 张英堂 on 2016/10/17.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MCSetModel.h"

@implementation MCSetModel


+ (instancetype)modelWithTitle:(NSString *)title
                          type:(LogoType)type
                        status:(SelectStatus)status{
    MCSetModel *model = [[MCSetModel alloc] init];
    model.title = title;
    model.type = type;
    model.status = status;
    
    return model;
}

- (void)setOpen{
    if (self.status == SelectStatusBool) {
        if (self.boolValue != YES) {
            self.boolValue = YES;
        }
    }
    
}

@end
