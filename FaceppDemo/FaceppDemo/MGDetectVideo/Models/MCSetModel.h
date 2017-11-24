//
//  MCSetModel.h
//  MGSDKV2Test
//
//  Created by 张英堂 on 2016/10/17.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "BaseModel.h"

typedef NS_ENUM(NSInteger, LogoType) {
    LogoTypeImage = 1,
    LogoTypeText,
    LogoTypeSelect,
    LogoTypeSpace
};
typedef NS_ENUM(NSInteger, SelectStatus) {
    SelectStatusBool = 1,
    SelectStatusInt,
    SelectStatusFloat,
    SelectStatusSize,
    SelectStatusSting
};

@interface MCSetModel : BaseModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *imageName;

@property (nonatomic, assign) BOOL boolValue;
@property (nonatomic, assign) NSInteger intValue;
@property (nonatomic, assign) CGFloat floatValue;
@property (nonatomic, assign) CGSize sizeValue;
@property (copy, nonatomic) NSString *stringValue;

@property (copy, nonatomic) NSString *videoPreset;

@property (nonatomic, assign) BOOL changeTitle;

@property (nonatomic, assign) LogoType type;
@property (nonatomic, assign) SelectStatus status;


- (void)setOpen;


+ (instancetype)modelWithTitle:(NSString *)title
                          type:(LogoType)type
                        status:(SelectStatus)status;

@end
