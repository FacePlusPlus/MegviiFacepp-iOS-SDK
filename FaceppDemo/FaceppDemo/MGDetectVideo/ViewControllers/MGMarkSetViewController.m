//
//  MGMarkSetViewController.m
//  LandMask
//
//  Created by 张英堂 on 16/8/17.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGMarkSetViewController.h"
#import "MGVideoViewController.h"
#import "MCSetModel.h"
#import "MCSetCell.h"
#import "MGHeader.h"


static NSString *const cellIdentifier = @"com.megvii.funcVC.cell";
#define KTrackingTag 100
#define KResolutionTag 101


@interface MGMarkSetViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation MGMarkSetViewController

- (void)hardCode{
    MCSetModel *record = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title1", nil) type:LogoTypeImage status:SelectStatusBool];
    record.boolValue = NO;
    record.imageName = @"record";
    MCSetModel *model3d = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title2", nil) type:LogoTypeImage status:SelectStatusBool];
    model3d.boolValue = NO;
    model3d.imageName = @"3D";
    MCSetModel *debug = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title3", nil) type:LogoTypeImage status:SelectStatusBool];
    debug.boolValue = NO;
    debug.imageName = @"debug";
    MCSetModel *rect = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title4", nil) type:LogoTypeImage status:SelectStatusBool];
    rect.boolValue = NO;
    rect.imageName = @"area";
    MCSetModel *count = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title11", nil) type:LogoTypeImage status:SelectStatusBool];
    count.boolValue = NO;
    count.imageName = @"81";
    MCSetModel *camera = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title6", nil) type:LogoTypeImage status:SelectStatusBool];
    camera.boolValue = NO;
    camera.imageName = @"side";
    camera.changeTitle = YES;
    MCSetModel *minFace = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title8", nil) type:LogoTypeText status:SelectStatusInt];
    minFace.intValue = 100;
    MCSetModel *time = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title10", nil) type:LogoTypeText status:SelectStatusInt];
    time.intValue = 40;
    MCSetModel *info = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title5", nil) type:LogoTypeImage status:SelectStatusBool];
    info.boolValue = NO;
    info.imageName = @"faceinfo";
    MCSetModel *size = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title12", nil) type:LogoTypeSelect status:SelectStatusSize];
    size.sizeValue = CGSizeMake(480, 640);
    size.videoPreset = AVCaptureSessionPreset640x480;
    MCSetModel *Tracking = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title13", nil) type:LogoTypeText status:SelectStatusSting];
    Tracking.boolValue = NO;
    Tracking.stringValue = @"NO";
    MCSetModel *Mode = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title14", nil) type:LogoTypeSelect status:SelectStatusSting];
    Mode.stringValue = NSLocalizedString(@"icon_title15", nil);
    Mode.intValue = 1;
    
    // 人脸检测
    MCSetModel *faceCompare = [MCSetModel modelWithTitle:NSLocalizedString(@"icon_title_face_compare", nil)
                                                     type:LogoTypeImage
                                                   status:SelectStatusBool];
    faceCompare.boolValue = NO;
    faceCompare.imageName = @"faceCompare";
    
    self.dataArray = @[record, model3d, debug, rect, count, camera, minFace, time, info, size, Tracking, Mode, faceCompare];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self creatView];
    [self hardCode];
}

- (void)creatView{
    self.title = NSLocalizedString(@"icon_title19", nil);
    
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 禁用录像
    if (indexPath.row == 0) {
        return;
    }
    
    MCSetModel *model = self.dataArray[indexPath.row];
    switch (model.type) {
        case LogoTypeImage:
            [self boolCellAction:model cell:indexPath];
            break;
        case LogoTypeText:
            [self showTextAction:model cell:indexPath];
            break;
        case LogoTypeSelect:
            if (model.status == SelectStatusSize) {
                [self showvideoSizeList:nil];
            }else{
                [self showTrackingList:nil];
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
    AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) {
        [self showAVAuthorizationStatusDeniedAlert];
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (granted) {
                    [self showDetectViewController];
                } else {
                    [self showAVAuthorizationStatusDeniedAlert];
                }
            });
        }];
    } else {
        [self showDetectViewController];
    }
}

- (void)showAVAuthorizationStatusDeniedAlert{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"alert_title_camera",nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"alert_action_ok",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showDetectViewController{
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
    MCSetModel *tracking = self.dataArray[10];
    MCSetModel *trackingMode = self.dataArray[11];
    MCSetModel *faceCompare = self.dataArray[12];

    int pointCount = count.boolValue == NO ? 81 : 106;
    int faceSize = (int)sizeModel.intValue;
    int internal = (int)space.intValue;
    BOOL recording = record.boolValue;
    BOOL hasDetectBox = rect.boolValue;
    
    MGDetectROI detectROI = MGDetectROIMake(0, 0, 0, 0);
    CGRect detectRect = CGRectNull;
    if (hasDetectBox) {
        CGFloat angeleW = size.sizeValue.width * 0.5;
        CGFloat angeleL = (size.sizeValue.width - angeleW)/2;
        CGFloat angeleT = (size.sizeValue.height-angeleW)/2;
        detectROI = MGDetectROIMake(angeleT, angeleL, angeleW+angeleT, angeleW+angeleL);
        detectRect = CGRectMake(detectROI.bottom,
                                detectROI.right,
                                detectROI.bottom,
                                detectROI.left);
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    int maxFaceCount = 0;
    if (tracking.boolValue) {
        maxFaceCount = 1;
    }
    
    MGFacepp *markManager = [[MGFacepp alloc] initWithModel:modelData
                                               maxFaceCount:maxFaceCount
                                              faceppSetting:^(MGFaceppConfig *config) {
                                                  config.minFaceSize = faceSize;
                                                  config.interval = internal;
                                                  config.orientation = 90;
                                                  switch (trackingMode.intValue) {
                                                      case 1:
                                                          config.detectionMode = MGFppDetectionModeTrackingFast;
                                                          break;
                                                      case 2:
                                                          config.detectionMode = MGFppDetectionModeTrackingRobust;
                                                          break;
                                                      case 3:
                                                          config.detectionMode = MGFppDetectionModeTrackingRect;
                                                          break;
                                                          
                                                      default:
                                                          config.detectionMode = MGFppDetectionModeTrackingFast;
                                                          break;
                                                  }
                                                  
                                                  config.detectROI = detectROI;
                                                  config.pixelFormatType = PixelFormatTypeRGBA;
                                              }];

    
    AVCaptureDevicePosition device = [self getCamera:camera.boolValue];
    MGVideoManager *videoManager = [MGVideoManager videoPreset:size.videoPreset
                                                devicePosition:device
                                                   videoRecord:recording
                                                    videoSound:NO];
    
    MGVideoViewController *videoController = [[MGVideoViewController alloc] initWithNibName:nil bundle:nil];
    videoController.detectRect = detectRect;
    videoController.videoSize = size.sizeValue;
    videoController.videoManager = videoManager;
    videoController.markManager = markManager;
    videoController.debug = debug.boolValue;
    videoController.pointsNum = pointCount;
    videoController.show3D = face3D.boolValue;
    videoController.faceInfo = info.boolValue;
    videoController.faceCompare = faceCompare.boolValue;
    switch (trackingMode.intValue) {
        case 1:
            videoController.detectMode = MGFppDetectionModeTrackingFast;
            break;
        case 2:
            videoController.detectMode = MGFppDetectionModeTrackingRobust;
            break;
        case 3:
            videoController.detectMode = MGFppDetectionModeTrackingRect;
            break;
            
        default:
            videoController.detectMode = MGFppDetectionModeTrackingFast;
            break;
    }
    
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:videoController];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}

#pragma mark - cell action
- (void)showTextAction:(MCSetModel *)model cell:(NSIndexPath *)cellIndex{
    if (model.status == SelectStatusInt) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:model.title
                                                                       message:NSLocalizedString(@"alert_message4", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = [NSString stringWithFormat:@"%zi", model.intValue];
            [textField setKeyboardType:UIKeyboardTypeNumberPad];
        }];
        UIAlertAction *finishAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"alert_message3", nil)
                                                               style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSInteger textValue = abs([alert.textFields[0].text intValue]);
            textValue = (textValue >= 1000 ? 1000 : textValue);
            textValue = (textValue == 0 ? 1 : textValue);
            
            model.intValue = textValue;
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex]];
        }];
        [alert addAction:finishAction];
        
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }else if(model.status == SelectStatusSting){
        model.boolValue = !model.boolValue;
        if (model.boolValue == YES) {
            model.stringValue = @"YES";
        }else{
            model.stringValue = @"NO";
        }
        [self.collectionView reloadItemsAtIndexPaths:@[cellIndex]];
    }
}

- (void)boolCellAction:(MCSetModel *)model cell:(NSIndexPath *)cellIndex{
    if (model.status == SelectStatusBool) {
        model.boolValue = !model.boolValue;
        
        if (model.changeTitle == YES) {
            if (model.boolValue == YES) {
                model.title = NSLocalizedString(@"icon_title7", nil);
            }else{
                model.title = NSLocalizedString(@"icon_title6", nil);
            }
        }
        
        if (cellIndex.row == 2 && model.boolValue == NO) {
            NSIndexPath *indexPath8 = [NSIndexPath indexPathForRow:8 inSection:0];
            MCSetModel *model = self.dataArray[8];
            model.boolValue = NO;
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex, indexPath8]];
        }
        
        if (cellIndex.row == 8 && model.boolValue == YES) {
            NSIndexPath *debuPath = [NSIndexPath indexPathForRow:2 inSection:0];
            MCSetModel *debug = self.dataArray[2];
            [debug setOpen];
            
            NSIndexPath *indexPath12 = [NSIndexPath indexPathForRow:12 inSection:0];
            MCSetModel *model12 = self.dataArray[12];
            model12.boolValue = NO;
            
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex, debuPath, indexPath12]];
        } else {
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex]];
        }
        
        if (cellIndex.row == 12 &&model.boolValue == YES) {
            NSIndexPath *debuPath = [NSIndexPath indexPathForRow:2 inSection:0];
            MCSetModel *debug = self.dataArray[2];
            debug.boolValue = NO;
            
            NSIndexPath *indexPath8 = [NSIndexPath indexPathForRow:8 inSection:0];
            MCSetModel *model8 = self.dataArray[8];
            model8.boolValue = NO;
            
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex, debuPath, indexPath8]];
        } else {
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex]];
        }
        
        if (cellIndex.row == 2 && model.boolValue == YES) {
            NSIndexPath *indexPath12 = [NSIndexPath indexPathForRow:12 inSection:0];
            MCSetModel *model12 = self.dataArray[12];
            model12.boolValue = NO;
            
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex, indexPath12]];
        } else {
            [self.collectionView reloadItemsAtIndexPaths:@[cellIndex]];
        }
    }
}

- (void)showTrackingList:(id)sender {
    UIAlertView *alertView =[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title2", nil)
                                                       message:NSLocalizedString(@"icon_title14", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"alert_title", nil)
                                             otherButtonTitles:NSLocalizedString(@"icon_title15", nil),
                                                               NSLocalizedString(@"icon_title16", nil),
                                                               NSLocalizedString(@"icon_title22", nil),
//                                                               NSLocalizedString(@"icon_title21", nil),
                                                                 nil];
    [alertView setTag:KTrackingTag];
    [alertView show];
}

- (void)showvideoSizeList:(id)sender {
    UIAlertView *alertView =[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title2", nil)
                                                       message:NSLocalizedString(@"icon_title12", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"alert_title", nil)
                                             otherButtonTitles:@"640*480", @"960*540", @"1280*720",  @"1920*1080", nil];
    [alertView setTag:KResolutionTag];
    [alertView show];
}

#pragma mark - setting change
- (void)getTrackingMode:(NSUInteger)index button:(NSIndexPath *)cellIndex model:(MCSetModel *)model{
    model.intValue = index;
    NSString *mode;
    switch (index) {
        case 1:
            mode = NSLocalizedString(@"icon_title15", nil);
            break;
        case 2:
            mode = NSLocalizedString(@"icon_title16", nil);
            break;
        case 3:
            mode = NSLocalizedString(@"icon_title22", nil);
            break;
        default:
            mode = NSLocalizedString(@"icon_title15", nil);
            break;
    }
    model.stringValue = mode;
    
    [self.collectionView reloadItemsAtIndexPaths:@[cellIndex]];
}

- (void)getVideoSize:(NSUInteger)index button:(NSIndexPath *)cellIndex model:(MCSetModel *)model{
    NSString *tempVideoSize;
    CGSize videoSize;
    switch (index) {
        case 1:
            tempVideoSize = AVCaptureSessionPreset640x480;
            videoSize = CGSizeMake(480, 640);
            break;
        case 2:
            tempVideoSize = AVCaptureSessionPresetiFrame960x540;
            videoSize = CGSizeMake(540, 960);
            break;
        case 3:
            tempVideoSize = AVCaptureSessionPreset1280x720;
            videoSize = CGSizeMake(720, 1280);
            break;
        case 4:
            tempVideoSize = AVCaptureSessionPreset1920x1080;
            videoSize = CGSizeMake(1080, 1920);
            break;
        default:
            tempVideoSize = AVCaptureSessionPreset640x480;
            videoSize = CGSizeMake(480, 640);
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
        if (alertView.tag == KResolutionTag) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:9 inSection:0];
            MCSetModel *presetModel = self.dataArray[9];
            [self getVideoSize:buttonIndex button:indexPath model:presetModel];
        }else if(alertView.tag == KTrackingTag){
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:11 inSection:0];
            MCSetModel *presetModel = self.dataArray[11];
            
            [self getTrackingMode:buttonIndex button:indexPath model:presetModel];
        }
    }
}

#pragma mark -
-(BOOL)fd_prefersNavigationBarHidden{
    return NO;
}

@end
