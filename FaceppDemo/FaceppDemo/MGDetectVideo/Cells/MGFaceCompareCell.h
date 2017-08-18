//
//  MGFaceCompareCell.h
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGFaceCompareModel.h"

@protocol MGFaceCompareCellDelegate <NSObject>

- (void)nameDidEdit:(MGFaceCompareModel *)model;

- (void)modelDidSelected:(MGFaceCompareModel *)model;

@end

@interface MGFaceCompareCell : UITableViewCell

@property (nonatomic, weak) id <MGFaceCompareCellDelegate> delegate;

@property (nonatomic, strong) MGFaceCompareModel *model;

@end
