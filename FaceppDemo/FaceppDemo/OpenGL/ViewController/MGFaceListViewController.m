//
//  MGFaceListViewController.m
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "MGFaceListViewController.h"
#import "MGFaceCompareCell.h"
#import "MGFileManager.h"

@interface MGFaceListViewController () <UITableViewDelegate, UITableViewDataSource, MGFaceCompareCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *okBtn;

@end

@implementation MGFaceListViewController

+ (instancetype)storyboardInstance{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MGFaceListViewController" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"MGFaceListViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"viewController_title_choose_face", nil);
    _bottomView.backgroundColor = [UIColor colorWithRed:41/255. green:135/255. blue:192/255. alpha:1];
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [_cancelBtn setTitle:NSLocalizedString(@"button_title_cancel_all", nil) forState:UIControlStateNormal];
    [_cancelBtn setTitle:NSLocalizedString(@"button_title_cancel_all", nil) forState:UIControlStateHighlighted];
    [_okBtn setTitle:NSLocalizedString(@"alert_action_ok", nil) forState:UIControlStateNormal];
    [_okBtn setTitle:NSLocalizedString(@"alert_action_ok", nil) forState:UIControlStateHighlighted];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate - 
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 110;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MGFaceCompareCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.model = _models[indexPath.row];
    cell.delegate = self;
    return cell;
}


#pragma amrk - MGFaceCompareCellDelegate -

- (void)nameDidEdit:(MGFaceCompareModel *)model{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"alert_title_input_user_name", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"alert_action_ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *name = alert.textFields.firstObject;
        NSString *str = name.text;
        if (str.length > 0) {
            model.name = str;
            [self.tableView reloadData];
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"alert_title", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)modelDidSelected:(MGFaceCompareModel *)model{
    NSLog(@"");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cancelBtnAction:(UIButton *)sender {
    for (MGFaceCompareModel *model in _models) {
        model.selected = NO;
    }
    [self.tableView reloadData];
}

- (IBAction)okBtnAction:(UIButton *)sender {
    NSMutableArray *arr = [NSMutableArray array];
    for (MGFaceCompareModel *model in _models) {
        if (model.selected == YES) {
            [arr addObject:model];
        }
    }
    [MGFileManager saveModels:arr];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
