//
//  MGMarkSetViewController.m
//  LandMask
//
//  Created by 张英堂 on 16/8/17.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGMarkSetViewController.h"
#import "MarkVideoViewController.h"

#import "MCSetModel.h"
#import "MCSetCell.h"
#import "YTMacro.h"

static NSString *const cellIdentifier = @"com.megvii.funcVC.cell";

@interface MGMarkSetViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation MGMarkSetViewController

- (void)hardCode{
    MCSetModel *record = [MCSetModel modelWithTitle:@"录像" type:LogoTypeImage status:SelectStatusBool];
    record.boolValue = NO;
    record.imageName = @"record";
    MCSetModel *model3d = [MCSetModel modelWithTitle:@"3D模型" type:LogoTypeImage status:SelectStatusBool];
    model3d.boolValue = NO;
    model3d.imageName = @"3D";
    MCSetModel *debug = [MCSetModel modelWithTitle:@"调试信息" type:LogoTypeImage status:SelectStatusBool];
    debug.boolValue = NO;
    debug.imageName = @"debug";
    MCSetModel *rect = [MCSetModel modelWithTitle:@"区域选择" type:LogoTypeImage status:SelectStatusBool];
    rect.boolValue = NO;
    rect.imageName = @"area";
    MCSetModel *count = [MCSetModel modelWithTitle:@"关键点个数" type:LogoTypeImage status:SelectStatusBool];
    count.boolValue = NO;
    count.imageName = @"81";
    MCSetModel *camera = [MCSetModel modelWithTitle:@"前置摄像头" type:LogoTypeImage status:SelectStatusBool];
    camera.boolValue = NO;
    camera.imageName = @"side";
    camera.changeTitle = YES;
    MCSetModel *minFace = [MCSetModel modelWithTitle:@"最小人脸" type:LogoTypeText status:SelectStatusInt];
    minFace.intValue = 100;
    MCSetModel *time = [MCSetModel modelWithTitle:@"检测间隔" type:LogoTypeText status:SelectStatusInt];
    time.intValue = 40;
    MCSetModel *info = [MCSetModel modelWithTitle:@"人脸属性" type:LogoTypeImage status:SelectStatusBool];
    info.boolValue = NO;
    info.imageName = @"faceinfo";
    MCSetModel *size = [MCSetModel modelWithTitle:@"相机分辨率" type:LogoTypeSelect status:SelectStatusSize];
    size.sizeValue = CGSizeMake(480, 640);
    size.videoPreset = AVCaptureSessionPreset640x480;
    
    self.dataArray = @[record, model3d, debug, rect, count, camera, minFace, time, info, size];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self creatView];
    [self hardCode];
}

- (void)creatView{
    self.title = @"人脸识别演示";
    
    CGFloat cellWidth = (WIN_WIDTH-80)/3;
    CGFloat cellHight = cellWidth*0.9;
    
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    [self.collectionView registerNib:[UINib nibWithNibName:@"MCSetCell" bundle:nil]
          forCellWithReuseIdentifier:cellIdentifier];

    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.itemSize = CGSizeMake(cellWidth, cellHight);
    
    self.collectionView.collectionViewLayout = flowLayout;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.dataArray.count;
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    MCSetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    MCSetModel *model = self.dataArray[indexPath.row];
    [cell setDataModel:model];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    MCSetModel *model = self.dataArray[indexPath.row];
    
    switch (model.type) {
        case LogoTypeImage:
        {
            [self boolCellAction:model cell:indexPath];
        }
            break;
        case LogoTypeText:
        {
            [self showTextAction:model cell:indexPath];
        }
            break;
        case LogoTypeSelect:
        {
            [self showvideoSizeList:nil];
        }
            break;
        default:
            break;
    }
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    return nil;
}

- (IBAction)startDetectFace:(id)sender{
    MCSetModel *record = self.dataArray[0];
    MCSetModel *face3D = self.dataArray[1];
    MCSetModel *debug = self.dataArray[2];
    MCSetModel *rect = self.dataArray[3];
    MCSetModel *count = self.dataArray[4];
    MCSetModel *camera = self.dataArray[5];
    MCSetModel *sizeModel = self.dataArray[6];
    MCSetModel *space = self.dataArray[7];
    MCSetModel *info = self.dataArray[8];
    MCSetModel *size = self.dataArray[9];
    
    int pointCount = count.boolValue == NO ? 81 : 106;
    int faceSize = (int)sizeModel.intValue;
    int internal = (int)space.intValue;
    BOOL recording = record.boolValue;
    BOOL hasDetectBox = rect.boolValue;
    
    MGDetectROI detectROI = MGDetectROIMake(0, 0, 0, 0);
    CGRect detectRect = CGRectNull;
    if (hasDetectBox) {
        CGFloat angeleW = size.sizeValue.width * 0.8;
        CGFloat angeleL = size.sizeValue.width * 0.1;
        CGFloat angeleT = (size.sizeValue.height-angeleW)*0.5;
        detectROI = MGDetectROIMake(angeleT, angeleL, angeleW+angeleT, angeleW+angeleL);
        detectRect = CGRectMake(detectROI.bottom,
                                detectROI.right,
                                detectROI.bottom,
                                detectROI.left);
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    MGFacepp *markManager = [[MGFacepp alloc] initWithModel:modelData
                                              faceppSetting:^(MGFaceppConfig *config) {
                                                  config.minFaceSize = faceSize;
                                                  config.interval = internal;
                                                  config.orientation = 90;
                                                  config.detectionMode = MGFppDetectionModeTrackingRobust;
                                                  config.detectROI = detectROI;
                                                  config.pixelFormatType = PixelFormatTypeRGBA;

                                              }];
    
    
    AVCaptureDevicePosition device = [self getCamera:camera.boolValue];
    MGVideoManager *videoManager = [MGVideoManager videoPreset:size.videoPreset
                                                devicePosition:device
                                                   videoRecord:recording
                                                    videoSound:NO];
    
    MarkVideoViewController *videoController = [[MarkVideoViewController alloc] initWithNibName:nil bundle:nil];
    videoController.detectRect = detectRect;
    videoController.videoSize = size.sizeValue;
    videoController.videoManager = videoManager;
    videoController.markManager = markManager;
    videoController.debug = debug.boolValue;
    videoController.pointsNum = pointCount;
    videoController.show3D = face3D.boolValue;
    videoController.faceInfo = info.boolValue;
    
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:videoController];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}

#pragma mark - cell action
- (void)showTextAction:(MCSetModel *)model cell:(NSIndexPath *)cellIndex{
    if (model.type == LogoTypeText) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:model.title message:@"最小值为 1，最大值为 1000" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = [NSString stringWithFormat:@"%zi", model.intValue];
            [textField setKeyboardType:UIKeyboardTypeNumberPad];
        }];
        UIAlertAction *finishAction = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSInteger textValue = abs([alertController.textFields[0].text intValue]);
            textValue = (textValue >= 1000 ? 1000 : textValue);
            textValue = (textValue == 0 ? 1 : textValue);
            
            model.intValue = textValue;
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex]];
        }];
        [alertController addAction:finishAction];
        
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)boolCellAction:(MCSetModel *)model cell:(NSIndexPath *)cellIndex{
    if (model.status == SelectStatusBool) {
        model.boolValue = !model.boolValue;
        
        if (model.changeTitle == YES) {
            if (model.boolValue == YES) {
                model.title = @"后置摄像头";
            }else{
                model.title = @"前置摄像头";
            }
        }
        
        if (cellIndex.row == 8 && model.boolValue == YES) {
            NSIndexPath *debuPath = [NSIndexPath indexPathForRow:2 inSection:0];
            MCSetModel *debug = self.dataArray[2];
            [debug setOpen];
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex, debuPath]];
            
        }else{
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex]];
        }
    }
}

- (void)showvideoSizeList:(id)sender {
    //@"1920*1080"
    UIAlertView *alertView =[[UIAlertView alloc] initWithTitle:@"请选择"
                                                       message:@"视频的相机分辨率"
                                                      delegate:self
                                             cancelButtonTitle:@"取消"
                                             otherButtonTitles:@"640*480", @"960*540", @"1280*720",  @"1920*1080", nil];
    [alertView show];
}

#pragma mark - setting change
- (void)getVideoSize:(NSUInteger)index button:(NSIndexPath *)cellIndex model:(MCSetModel *)model{
    NSString *tempVideoSize;
    CGSize videoSize;
    switch (index) {
        case 1:
        {
            tempVideoSize = AVCaptureSessionPreset640x480;
            videoSize = CGSizeMake(480, 640);
        }
            break;
        case 2:
        {
            tempVideoSize = AVCaptureSessionPresetiFrame960x540;
            videoSize = CGSizeMake(540, 960);
        }
            break;
        case 3:
        {
            tempVideoSize = AVCaptureSessionPreset1280x720;
            videoSize = CGSizeMake(720, 1280);
        }
            break;
        case 4:
        {
            tempVideoSize = AVCaptureSessionPreset1920x1080;
            videoSize = CGSizeMake(1080, 1920);
        }
            break;
        default:
        {
            tempVideoSize = AVCaptureSessionPreset640x480;
            videoSize = CGSizeMake(480, 640);
        }
            break;
    }
    model.videoPreset = tempVideoSize;
    model.sizeValue = videoSize;
    
    [self.collectionView reloadItemsAtIndexPaths:@[cellIndex]];
}

- (AVCaptureDevicePosition)getCamera:(BOOL)index{
    AVCaptureDevicePosition tempVideo;
    if (index == NO) {
        tempVideo = AVCaptureDevicePositionFront;
    }else{
        tempVideo = AVCaptureDevicePositionBack;
    }
    return tempVideo;
}

#pragma mark - alertView delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:9 inSection:0];
        
        MCSetModel *presetModel = self.dataArray[9];
        [self getVideoSize:buttonIndex button:indexPath model:presetModel];
    }
}

#pragma mark -
-(BOOL)fd_prefersNavigationBarHidden{
    return NO;
}

@end
