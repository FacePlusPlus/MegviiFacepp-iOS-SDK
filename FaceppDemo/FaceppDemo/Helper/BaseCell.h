//
//  BaseCell.h
//  KoalaPhoto
//
//  Created by 张英堂 on 14/12/22.
//  Copyright (c) 2014年 visionhacker. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BaseModel;

@interface BaseCell : UITableViewCell


@property (nonatomic, strong) BaseModel *dataModel;

+ (CGFloat)cellHigth;

@end
