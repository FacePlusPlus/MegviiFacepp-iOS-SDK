//
//  MGFaceContrastCell.h
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGFaceContrastModel.h"

@protocol MGFaceContrastCellDelegate <NSObject>

- (void)nameDidEdit:(MGFaceContrastModel *)model;

- (void)modelDidSelected:(MGFaceContrastModel *)model;

@end

@interface MGFaceContrastCell : UITableViewCell

@property (nonatomic, weak) id <MGFaceContrastCellDelegate> delegate;

@property (nonatomic, strong) MGFaceContrastModel *model;

@end
