//
//  TYtMacro.h
//

#ifndef text_TYtMacro_h
#define text_TYtMacro_h


    //屏幕宽度 （区别于viewcontroller.view.fream）
    #define WIN_WIDTH  [UIScreen mainScreen].bounds.size.width
    //屏幕高度 （区别于viewcontroller.view.fream）
    #define WIN_HEIGHT [UIScreen mainScreen].bounds.size.height

    //IOS版本
    #define IOS_SysVersion [[UIDevice currentDevice] systemVersion].floatValue
    //是否IPhone4
    #define IsIPhone4 (WIN_HEIGHT) == 480

    #define KDocumentFile NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]

    #define NavigationBarHight 64

//----------------------颜色类---------------------------
    // rgb颜色转换（16进制->10进制）
    #define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
    // color
    #define YT_ColorWithRGB(R, G, B, A) [UIColor colorWithRed:R/255.0f green:G/255.0f blue:B/255.0f alpha:A]
    #define MCTitleColor YT_ColorWithRGB(48, 54, 76, 1)
    //G－C－D
    #define BACK_ACTION(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
    #define MAIN_ACTION(block) dispatch_async(dispatch_get_main_queue(),block)

    //NSUserDefaults 实例化
    #define KUSER_DEFAULT [NSUserDefaults standardUserDefaults]

    #define KNilString @""
    //语言国际化相关
    #define KLocalString(key) NSLocalizedStringFromTable(key, @"MGFaceDetection", nil)

    //block 宏
    typedef void(^VoidBlock)();
    typedef BOOL(^BoolBlock)();
    typedef int (^IntBlock) ();
    typedef id  (^IDBlock)  ();

    typedef void(^VoidBlock_int)(NSUInteger);
    typedef BOOL(^BoolBlock_int)(int);
    typedef int (^IntBlock_int) (int);
    typedef id  (^IDBlock_int)  (int);

    typedef void(^VoidBlock_string)(NSString*);
    typedef BOOL(^BoolBlock_string)(NSString*);
    typedef int (^IntBlock_string) (NSString*);
    typedef id  (^IDBlock_string)  (NSString*);

    typedef void(^VoidBlock_id)(id);
    typedef BOOL(^BoolBlock_id)(id);
    typedef int (^IntBlock_id) (id);
    typedef id  (^IDBlock_id)  (id);

    typedef void(^VoidBlock_bool)(BOOL);

    typedef void(^LoginRequestFinishBlock)(BOOL success, NSString *errorMessage, BOOL needEditPwd);


#endif
