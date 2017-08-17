//
//  BufferReader.m
//  FaceDetectionProcessor
//
//  Created by Vitaliy Malakhovskiy on 7/3/14.
//  Copyright (c) 2014 Vitaliy Malakhovskiy. All rights reserved.
//

#import "VideoBufferReader.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoBufferReader () {
    struct DelegateMethods {
        unsigned int didGetNextVideoSample   : 1;
        unsigned int didGetErrorRedingSample : 1;
        unsigned int didFinishReadingSample  : 1;
    } _delegateMethods;
    
}

@property (nonatomic, weak) id <VideoBufferReaderDelegate> delegate;
@property (nonatomic, strong) AVAssetReader *reader;
@end

@implementation VideoBufferReader

- (instancetype)initWithDelegate:(id<VideoBufferReaderDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
        _delegateMethods.didGetNextVideoSample = [self.delegate respondsToSelector:@selector(bufferReader:didGetNextVideoSample:)];
        _delegateMethods.didGetErrorRedingSample = [self.delegate respondsToSelector:@selector(bufferReader:didGetErrorRedingSample:)];
        _delegateMethods.didFinishReadingSample = [self.delegate respondsToSelector:@selector(bufferReader:didFinishReadingAsset:)];
    }
    return self;
}

- (void)startReading:(NSString *)video {
    
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:video ofType:@""];
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    NSError *error = nil;
    _reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];


    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (!videoTracks.count) {
        error = [NSError errorWithDomain:@"AVFoundation error" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"Can't read video track" }];
        return;
    }
    
    AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
    NSDictionary *settings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] };
    AVAssetReaderTrackOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:settings];
    if ([_reader canAddOutput:trackOutput]) {
        [_reader addOutput:trackOutput];
    }
    
    
    [_reader startReading];

    CMSampleBufferRef buffer = NULL;
    BOOL continueReading = YES;
    while (continueReading) {
        AVAssetReaderStatus status = [_reader status];
        switch (status) {
            case AVAssetReaderStatusUnknown: {
            } break;
            case AVAssetReaderStatusReading: {
                buffer = [trackOutput copyNextSampleBuffer];

                if (!buffer) {
                    break;
                }

                if (_delegateMethods.didGetNextVideoSample) {
                    [self.delegate bufferReader:self didGetNextVideoSample:buffer];
                }
            } break;
            case AVAssetReaderStatusCompleted: {
                if (_delegateMethods.didFinishReadingSample) {
                    [self.delegate bufferReader:self didFinishReadingAsset:asset];
                    [_reader cancelReading];
                }
                continueReading = NO;
            } break;
            case AVAssetReaderStatusFailed: {
                if (_delegateMethods.didFinishReadingSample) {
                    [self.delegate bufferReader:self didFinishReadingAsset:asset];
                }
                [_reader cancelReading];
                continueReading = NO;
            } break;
            case AVAssetReaderStatusCancelled: {
                continueReading = NO;
            } break;
        }
        if (buffer) {
            CMSampleBufferInvalidate(buffer);
            CFRelease(buffer);
            buffer = NULL;
        }
    }
}

- (void)cancelReading {
    [_reader cancelReading];
//    _reader = nil;
    if ([_delegate respondsToSelector:@selector(bufferReaderDidCancelled)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate bufferReaderDidCancelled];
        });
    }
}

NS_INLINE NSDictionary *CVPixelFormatOutputSettings() {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] };
}

@end
