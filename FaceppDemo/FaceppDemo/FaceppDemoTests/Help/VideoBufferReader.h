//
//  BufferReader.h
//  FaceDetectionProcessor
//
//  Created by Vitaliy Malakhovskiy on 7/3/14.
//  Copyright (c) 2014 Vitaliy Malakhovskiy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@class AVAsset;
@protocol VideoBufferReaderDelegate;

@interface VideoBufferReader : NSObject

- (instancetype)initWithDelegate:(id <VideoBufferReaderDelegate>)delegate;

- (void)startReading:(NSString *)video;

- (void)cancelReading;

@end



@protocol VideoBufferReaderDelegate <NSObject>

- (void)bufferReader:(VideoBufferReader *)reader didFinishReadingAsset:(AVAsset *)asset;
- (void)bufferReader:(VideoBufferReader *)reader didGetNextVideoSample:(CMSampleBufferRef)bufferRef;
- (void)bufferReader:(VideoBufferReader *)reader didGetErrorRedingSample:(NSError *)error;
- (void)bufferReaderDidCancelled;

@end
