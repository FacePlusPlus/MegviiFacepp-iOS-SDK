//
//  MGFaceContrastCell.m
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "MGFaceContrastCell.h"

@interface MGFaceContrastCell ()
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UIButton *selectBtn;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) UITapGestureRecognizer *nameTap;
@end

@implementation MGFaceContrastCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self addNameAction];
}

- (void)setModel:(MGFaceContrastModel *)model{
    _selectBtn.selected = model.selected;
    if (_selectBtn.selected) {
        [_selectBtn setBackgroundImage:[UIImage imageNamed:@"selected"] forState:UIControlStateNormal];
    } else {
        [_selectBtn setBackgroundImage:[UIImage imageNamed:@"unSelected"] forState:UIControlStateNormal];
    }
    _icon.image = model.image;
    _nameLabel.text = model.name;
    _model = model;
}

- (void)nameAction{
    if ([_delegate respondsToSelector:@selector(nameDidEdit:)]) {
        [_delegate nameDidEdit:_model];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (IBAction)selectBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    _model.selected = sender.selected;
    if (sender.selected) {
        [sender setBackgroundImage:[UIImage imageNamed:@"selected"] forState:UIControlStateNormal];
    } else {
        [sender setBackgroundImage:[UIImage imageNamed:@"unSelected"] forState:UIControlStateNormal];
    }
    if ([_delegate respondsToSelector:@selector(modelDidSelected:)]) {
        [_delegate modelDidSelected:_model];
    }
}

- (void)addNameAction{
    _nameTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(nameAction)];
    _nameLabel.userInteractionEnabled = YES;
    [_nameLabel addGestureRecognizer:_nameTap];
}

@end
