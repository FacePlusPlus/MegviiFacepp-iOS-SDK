//
//  TextCell.m
//  MGSDKV2Test
//
//  Created by 张英堂 on 2016/10/21.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "TextCell.h"

@interface TextCell ()
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *textView;

@end

@implementation TextCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self.textView setAdjustsFontSizeToFitWidth:YES];
    [self.titleView setAdjustsFontSizeToFitWidth:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(void)setDataModel:(BaseModel *)dataModel{
    [super setDataModel:dataModel];
    self.model = (TextModel *)dataModel;
}

-(void)setModel:(TextModel *)model{
    if (_model != model) {
        _model = model;
    }
    
    if (_model) {
        self.titleView.text = model.title;
        self.textView.text = model.text;
    }
}


@end
