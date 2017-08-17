//
//  TextModel.h
//  MGSDKV2Test
//
//  Created by 张英堂 on 2016/10/21.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "BaseModel.h"

@interface TextModel : BaseModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *text;


+ (instancetype)modelWith:(NSString *)title text:(NSString *)text;
@end
