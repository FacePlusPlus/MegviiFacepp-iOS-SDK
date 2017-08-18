//
//  MCSetCell.h
//  MGSDKV2Test
//
//  Created by 张英堂 on 2016/10/17.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseCollectionCell.h"

@class MCSetModel;

@interface MCSetCell : BaseCollectionCell

@property (nonatomic, strong) MCSetModel *dataModel;


- (void)refurbish;


@end
