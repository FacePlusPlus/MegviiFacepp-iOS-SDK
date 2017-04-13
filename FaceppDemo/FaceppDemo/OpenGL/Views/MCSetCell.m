//
//  MCSetCell.m
//  MGSDKV2Test
//
//  Created by 张英堂 on 2016/10/17.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MCSetCell.h"
#import "MCSetModel.h"
#import "YTMacro.h"

@interface MCSetCell ()
{
    CAShapeLayer *_lineShape;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *textView;

@end


@implementation MCSetCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.textView.adjustsFontSizeToFitWidth = YES;

}

-(void)setDataModel:(MCSetModel *)dataModel{
    if (_dataModel != dataModel) {
        _dataModel = dataModel;
    }
    
    [self freshenView:_dataModel];
}

- (void)refurbish{
    
    [self freshenView:self.dataModel];
}

- (void)freshenView:(MCSetModel *)dataModel{
    if (dataModel != nil) {
        self.titleView.text = dataModel.title;
        
        switch (dataModel.type) {
            case LogoTypeImage:
            {
                if (dataModel.status == SelectStatusBool) {
                    [self.imageView setHidden:NO];
                    [self.textView setHidden:YES];
                    
                    NSString *tempImageName = [NSString stringWithFormat:@"%@-%zi",dataModel.imageName, dataModel.boolValue];
                    UIImage *tempImage = [UIImage imageNamed:tempImageName];
                    [self.imageView setImage:tempImage];
                }else if(dataModel.status == SelectStatusSting){
                    [self.imageView setHidden:YES];
                    [self.textView setHidden:NO];
                    
                    self.textView.text = dataModel.stringValue;
                }
            }
                break;
            case LogoTypeText:
            {
                [self.imageView setHidden:YES];
                [self.textView setHidden:NO];
                
                NSString *showString;
                if (dataModel.status == SelectStatusInt) {
                    showString = [NSString stringWithFormat:@"%zi", dataModel.intValue];
                }else if (dataModel.status == SelectStatusFloat){
                    showString = [NSString stringWithFormat:@"%.2f", dataModel.floatValue];
                }else if(dataModel.status == SelectStatusSting){
                    showString = dataModel.stringValue;
                }
                self.textView.text = showString;
            }
                break;
                case LogoTypeSelect:
            {
                if (dataModel.status == SelectStatusSize) {
                    [self.imageView setHidden:NO];
                    [self.textView setHidden:YES];
                    
                    NSString *tempImageName = [NSString stringWithFormat:@"%.0f_%.0f",dataModel.sizeValue.height, dataModel.sizeValue.width];
                    UIImage *tempImage = [UIImage imageNamed:tempImageName];
                    [self.imageView setImage:tempImage];
                    
                }else if(dataModel.status == SelectStatusSting){
                    [self.imageView setHidden:YES];
                    [self.textView setHidden:NO];
                    
                    self.textView.text = dataModel.stringValue;
                }
                
            }
                break;
            default:
            {
                [self.imageView setHidden:YES];
                [self.textView setHidden:YES];
            }
                break;
        }
        
        if (dataModel.type != LogoTypeSpace) {
            [self drawLine];
        }
    }
}

- (void)drawLine{
    if (_lineShape == nil) {
        CGMutablePathRef linepath = nil;
        
        linepath = CGPathCreateMutable();
        _lineShape = [CAShapeLayer layer];
        
        _lineShape.lineWidth = 2.0f;
        _lineShape.lineCap = kCALineCapRound;
        _lineShape.strokeColor = YT_ColorWithRGB(224, 224, 224, 1).CGColor;
        
        CGPathMoveToPoint(linepath, NULL, CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds));
        CGPathAddLineToPoint(linepath, NULL, CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds));
        
        _lineShape.path = linepath;
        CGPathRelease(linepath);
    }
    
    [self.layer addSublayer:_lineShape];
}

- (void)clearLine{
    if (_lineShape != nil) {
        [_lineShape removeFromSuperlayer];
    }
}

@end
