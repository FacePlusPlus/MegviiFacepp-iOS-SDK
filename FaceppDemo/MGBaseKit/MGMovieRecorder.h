
/*
 File: MovieRecorder.h
 Abstract: Real-time movie recorder which is totally non-blocking
 Version: 2.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */


#import <Foundation/Foundation.h>
#import <CoreMedia/CMFormatDescription.h>
#import <CoreMedia/CMSampleBuffer.h>


typedef NS_ENUM( NSInteger, MovieRecorderStatus ) {
    MovieRecorderStatusIdle = 0,
    MovieRecorderStatusPreparingToRecord,
    MovieRecorderStatusRecording,
    MovieRecorderStatusFinishingRecordingPart1, // waiting for inflight buffers to be appended
    MovieRecorderStatusFinishingRecordingPart2, // calling finish writing on the asset writer
    MovieRecorderStatusFinished,	// terminal state
    MovieRecorderStatusFailed		// terminal state
}; // internal state machine


@protocol MovieRecorderDelegate;

@interface MGMovieRecorder : NSObject

/**
 *  录像器 当前状态
 */
@property (nonatomic, assign, readonly) MovieRecorderStatus status;

/**
 *  log 开关，默认开启
 */
@property (nonatomic, assign) BOOL recorderLog;

+ (instancetype)movieRecorderWithSaveURL:(NSURL *)URL;

- (instancetype)initWithURL:(NSURL *)URL;

- (void)setDelegate:(id<MovieRecorderDelegate>)delegate
      callbackQueue:(dispatch_queue_t)delegateCallbackQueue; // delegate is weak referenced


// Only one audio and video track each are allowed.
- (void)addVideoTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription
                                       transform:(CGAffineTransform)transform
                                        settings:(NSDictionary *)videoSettings; // see AVVideoSettings.h for settings keys/values


- (void)addAudioTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription
                                        settings:(NSDictionary *)audioSettings; // see AVAudioSettings.h for settings keys/values


- (void)prepareToRecord; // Asynchronous, might take several hundred milliseconds. When finished the delegate's recorderDidFinishPreparing: or recorder:didFailWithError: method will be called.
- (void)finishRecording; // Asynchronous, might take several hundred milliseconds. When finished the delegate's recorderDidFinishRecording: or recorder:didFailWithError: method will be called.

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)appendVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer
          withPresentationTime:(CMTime)presentationTime;

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;


@end



@protocol MovieRecorderDelegate <NSObject>

@required
- (void)movieRecorderDidFinishPreparing:(MGMovieRecorder *)recorder;
- (void)movieRecorder:(MGMovieRecorder *)recorder didFailWithError:(NSError *)error;
- (void)movieRecorderDidFinishRecording:(MGMovieRecorder *)recorder;

@end



