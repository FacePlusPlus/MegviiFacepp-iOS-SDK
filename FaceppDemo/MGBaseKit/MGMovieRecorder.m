
/*
 File: MovieRecorder.m
 Abstract: Real-time movie recorder which is totally non-blocking
 Version: 2.1
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
 */

#import "MGMovieRecorder.h"

#import <AVFoundation/AVAssetWriter.h>
#import <AVFoundation/AVAssetWriterInput.h>

#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVVideoSettings.h>
#import <AVFoundation/AVAudioSettings.h>


@interface MGMovieRecorder ()
{
    dispatch_queue_t _delegateCallbackQueue;
    dispatch_queue_t _writingQueue;
    
    AVAssetWriter *_assetWriter;
    
    CMFormatDescriptionRef _audioTrackSourceFormatDescription;
    NSDictionary *_audioTrackSettings;
    AVAssetWriterInput *_audioInput;
    
    CMFormatDescriptionRef _videoTrackSourceFormatDescription;
    CGAffineTransform _videoTrackTransform;
    AVAssetWriterInput *_videoInput;
}
@property (nonatomic, assign) BOOL haveStartedSession;

@property (nonatomic, assign) id <MovieRecorderDelegate> delegate;
@property (nonatomic, copy) NSURL *URL;

@end

@implementation MGMovieRecorder

#pragma mark -
#pragma mark init setting

- (instancetype)initWithURL:(NSURL *)URL
{
    if (nil == URL) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _writingQueue = dispatch_queue_create("com.megvii.movierecorder.writing", DISPATCH_QUEUE_SERIAL );
        _videoTrackTransform = CGAffineTransformIdentity;
        self.URL = URL;
        
        self.recorderLog = YES;
    }
    return self;
}

+ (instancetype)movieRecorderWithSaveURL:(NSURL *)URL{
    MGMovieRecorder *recorder = [[MGMovieRecorder alloc] initWithURL:URL];
    return recorder;
}

- (void)addVideoTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription transform:(CGAffineTransform)transform settings:(NSDictionary *)videoSettings
{
    if (NULL == formatDescription) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL format description" userInfo:nil];
        return;
    }
    
    @synchronized(self)
    {
        if (_status != MovieRecorderStatusIdle) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add tracks while not idle" userInfo:nil];
            return;
        }
        
        if (_videoTrackSourceFormatDescription) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add more than one video track" userInfo:nil];
            return;
        }
        
        _videoTrackSourceFormatDescription = (CMFormatDescriptionRef)CFRetain( formatDescription );
        _videoTrackTransform = transform;
    }
}

- (void)addAudioTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription settings:(NSDictionary *)audioSettings
{
    if (NULL == formatDescription) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL AUDIO format description" userInfo:nil];
        return;
    }
    
    @synchronized( self )
    {
        if (_status != MovieRecorderStatusIdle) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add tracks while not idle" userInfo:nil];
            return;
        }
        
        if (_audioTrackSourceFormatDescription) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add more than one audio track" userInfo:nil];
            return;
        }
        
        if (!_audioTrackSettings) {
            _audioTrackSourceFormatDescription = (CMFormatDescriptionRef)CFRetain( formatDescription );
            _audioTrackSettings = [audioSettings copy];
        }
    }
}

- (void)setDelegate:(id<MovieRecorderDelegate>)delegate callbackQueue:(dispatch_queue_t)delegateCallbackQueue; // delegate is weak referenced
{
    if (delegate && (NULL == delegateCallbackQueue) ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Caller must provide a delegateCallbackQueue" userInfo:nil];
    }
    
    @synchronized(self)
    {
        self.delegate = delegate;
        
        if (delegateCallbackQueue != _delegateCallbackQueue) {
            _delegateCallbackQueue = delegateCallbackQueue;
        }
    }
}

- (void)prepareToRecord
{
    @synchronized( self )
    {
        if (_status != MovieRecorderStatusIdle) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Already prepared, cannot prepare again" userInfo:nil];
            return;
        }
        
        [self transitionToStatus:MovieRecorderStatusPreparingToRecord error:nil];
    }
    
    @autoreleasepool
    {
        NSError *error = nil;
        // AVAssetWriter will not write over an existing file.
        [[NSFileManager defaultManager] removeItemAtURL:self.URL error:NULL];
        
        _assetWriter = [[AVAssetWriter alloc] initWithURL:self.URL fileType:AVFileTypeQuickTimeMovie error:&error];
        
        // Create and add inputs
        if (!error && _videoTrackSourceFormatDescription ) {
            [self setupAssetWriterVideoInputWithSourceFormatDescription:_videoTrackSourceFormatDescription
                                                              transform:_videoTrackTransform
                                                               settings:nil
                                                                  error:&error];
        }
        
        if (!error && _audioTrackSourceFormatDescription ) {
            [self setupAssetWriterAudioInputWithSourceFormatDescription:_audioTrackSourceFormatDescription
                                                               settings:_audioTrackSettings
                                                                  error:&error];
        }
        
        if (!error){
            BOOL success = [_assetWriter startWriting];
            if (!success) {
                error = _assetWriter.error;
            }
        }
        
        @synchronized(self)
        {
            if (error) {
                [self transitionToStatus:MovieRecorderStatusFailed error:error];
            }else{
                [self transitionToStatus:MovieRecorderStatusRecording error:nil];
            }
        }
    }
}

#pragma mark - append audio/video buffer
- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
}

- (void)appendVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime
{
    CMSampleBufferRef sampleBuffer = NULL;
    
    CMSampleTimingInfo timingInfo = {0,};
    timingInfo.duration = kCMTimeInvalid;
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    timingInfo.presentationTimeStamp = presentationTime;
    
    OSStatus err = CMSampleBufferCreateForImageBuffer( kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, _videoTrackSourceFormatDescription, &timingInfo, &sampleBuffer );
    if ( sampleBuffer ) {
        [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
        CFRelease(sampleBuffer);
    }
    else {
        NSString *exceptionReason = [NSString stringWithFormat:@"sample buffer create failed (%zi)", err];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:exceptionReason userInfo:nil];
        return;
    }
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (self.status == MovieRecorderStatusRecording) {
        [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
    }
}

- (void)finishRecording
{
    @synchronized(self)
    {
        BOOL shouldFinishRecording = NO;
        switch (_status)
        {
            case MovieRecorderStatusIdle:
            case MovieRecorderStatusPreparingToRecord:
            case MovieRecorderStatusFinishingRecordingPart1:
            case MovieRecorderStatusFinishingRecordingPart2:
            case MovieRecorderStatusFinished:
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not recording" userInfo:nil];
                break;
            case MovieRecorderStatusFailed:
                // From the client's perspective the movie recorder can asynchronously transition to an error state as the result of an append.
                // Because of this we are lenient when finishRecording is called and we are in an error state.
                NSLog( @"Recording has failed, nothing to do" );
                break;
            case MovieRecorderStatusRecording:
            {
                shouldFinishRecording = YES;
            }
                break;
        }
        
        if (shouldFinishRecording) {
            [self transitionToStatus:MovieRecorderStatusFinishingRecordingPart1
                               error:nil];
        }else{
            return;
        }
    }
    
    dispatch_async( _writingQueue, ^{
        
        @autoreleasepool{
            @synchronized(self){
                // We may have transitioned to an error state as we appended inflight buffers. In that case there is nothing to do now.
                if (_status != MovieRecorderStatusFinishingRecordingPart1) {
                    return;
                }
                // It is not safe to call -[AVAssetWriter finishWriting*] concurrently with -[AVAssetWriterInput appendSampleBuffer:]
                // We transition to MovieRecorderStatusFinishingRecordingPart2 while on _writingQueue, which guarantees that no more buffers will be appended.
                [self transitionToStatus:MovieRecorderStatusFinishingRecordingPart2
                                   error:nil];
            }
            
            [_assetWriter finishWritingWithCompletionHandler:^{
                @synchronized(self)
                {
                    NSError *error = _assetWriter.error;
                    if ( error ) {
                        [self transitionToStatus:MovieRecorderStatusFailed error:error];
                    }
                    else {
                        [self transitionToStatus:MovieRecorderStatusFinished error:nil];
                    }
                }
            }];
        }
    } );
}

#pragma mark -
#pragma mark release self

- (void)dealloc
{
    [self teardownAssetWriterAndInputs];
    
    if (_audioTrackSourceFormatDescription) {
        CFRelease(_audioTrackSourceFormatDescription);
    }
    
    if (_videoTrackSourceFormatDescription) {
        CFRelease(_videoTrackSourceFormatDescription);
    }
}

- (void)teardownAssetWriterAndInputs
{
    _videoInput = nil;
    _audioInput = nil;
    _assetWriter = nil;
}

#pragma mark -
#pragma mark Internal

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    if (NULL == sampleBuffer) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL sample buffer" userInfo:nil];
        return;
    }
    
    @synchronized(self) {
        if (_status < MovieRecorderStatusRecording) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not ready to record yet" userInfo:nil];
            return;
        }
    }
    
    CFRetain(sampleBuffer);
    
    dispatch_async(_writingQueue, ^{
        @autoreleasepool{
            @synchronized(self){
                // From the client's perspective the movie recorder can asynchronously transition to an error state as the result of an append.
                // Because of this we are lenient when samples are appended and we are no longer recording.
                // Instead of throwing an exception we just release the sample buffers and return.
                if ( _status > MovieRecorderStatusFinishingRecordingPart1 ) {
                    CFRelease( sampleBuffer );
                    return;
                }
            }
            
            if (NO == _haveStartedSession) {
                [_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                _haveStartedSession = YES;
            }
            
            AVAssetWriterInput *input = (mediaType == AVMediaTypeVideo) ? _videoInput : _audioInput;
            
            if (input.readyForMoreMediaData)
            {
                BOOL success = [input appendSampleBuffer:sampleBuffer];
                if (NO == success) {
                    NSError *error = _assetWriter.error;
                    @synchronized(self) {
                        [self transitionToStatus:MovieRecorderStatusFailed error:error];
                    }
                }
            }else{
                NSLog(@"%@ input not ready for more media data, dropping buffer", mediaType );
            }
            CFRelease(sampleBuffer);
        }
    } );
}

// call under @synchonized( self )
- (void)transitionToStatus:(MovieRecorderStatus)newStatus error:(NSError *)error
{
    BOOL shouldNotifyDelegate = NO;
    
    [self recoderLogWith:@"MovieRecorder state transition: %@->%@", [self stringForStatus:_status], [self stringForStatus:newStatus]];
    
    if(newStatus != _status)
    {
        // terminal states
        if ( (newStatus == MovieRecorderStatusFinished) || (newStatus == MovieRecorderStatusFailed) )
        {
            shouldNotifyDelegate = YES;
            // make sure there are no more sample buffers in flight before we tear down the asset writer and inputs
            
            dispatch_async(_writingQueue, ^{
                [self teardownAssetWriterAndInputs];
                if (newStatus == MovieRecorderStatusFailed) {
                    [[NSFileManager defaultManager] removeItemAtURL:self.URL error:NULL];
                }
            });
            
            if(error){
                [self recoderLogWith:@"MovieRecorder error :%@, code: %zi", error, error.code];
            }
        }else if(newStatus == MovieRecorderStatusRecording){
            shouldNotifyDelegate = YES;
        }
        
        _status = newStatus;
    }
    
    if(shouldNotifyDelegate && self.delegate)
    {
        dispatch_async(_delegateCallbackQueue, ^{
            
            @autoreleasepool{
                switch (newStatus){
                    case MovieRecorderStatusRecording:
                    {
                        [self.delegate movieRecorderDidFinishPreparing:self];
                    }
                        break;
                    case MovieRecorderStatusFinished:
                    {
                        [self.delegate movieRecorderDidFinishRecording:self];
                    }
                        break;
                    case MovieRecorderStatusFailed:
                    {
                        [self.delegate movieRecorder:self didFailWithError:error];
                    }
                        break;
                    default:
                        break;
                }
            }
        } );
    }
}

- (NSString *)stringForStatus:(MovieRecorderStatus)status
{
    NSString *statusString = nil;
    switch (status)
    {
        case MovieRecorderStatusIdle:
            statusString = @"Idle";
            break;
        case MovieRecorderStatusPreparingToRecord:
            statusString = @"PreparingToRecord";
            break;
        case MovieRecorderStatusRecording:
            statusString = @"Recording";
            break;
        case MovieRecorderStatusFinishingRecordingPart1:
            statusString = @"FinishingRecordingPart1";
            break;
        case MovieRecorderStatusFinishingRecordingPart2:
            statusString = @"FinishingRecordingPart2";
            break;
        case MovieRecorderStatusFinished:
            statusString = @"Finished";
            break;
        case MovieRecorderStatusFailed:
            statusString = @"Failed";
            break;
        default:
            statusString = @"Unknown";
            break;
    }
    return statusString;
}

- (BOOL)setupAssetWriterAudioInputWithSourceFormatDescription:(CMFormatDescriptionRef)audioFormatDescription
                                                     settings:(NSDictionary *)audioSettings
                                                        error:(NSError **)errorOut{
    if (nil == audioSettings ) {
        NSLog(@"No audio settings provided, using default audio settings");
        audioSettings = @{AVFormatIDKey : @(kAudioFormatMPEG4AAC)};
    }
    
    if ( [_assetWriter canApplyOutputSettings:audioSettings forMediaType:AVMediaTypeAudio] )
    {
        _audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioSettings sourceFormatHint:audioFormatDescription];
        _audioInput.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:_audioInput])
        {
            [_assetWriter addInput:_audioInput];
        }else{
            if (errorOut) {
                *errorOut = [[self class] cannotSetupInputError];
            }
            return NO;
        }
    }else{
        if (errorOut) {
            *errorOut = [[self class] cannotSetupInputError];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)setupAssetWriterVideoInputWithSourceFormatDescription:(CMFormatDescriptionRef)videoFormatDescription
                                                    transform:(CGAffineTransform)transform
                                                     settings:(NSDictionary *)videoSettings
                                                        error:(NSError **)errorOut{
    float bitsPerPixel = 0;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(videoFormatDescription);
    int numPixels = dimensions.width * dimensions.height;
    int bitsPerSecond = 0;
    
    // Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
    if (numPixels < (640 * 480)) {
        bitsPerPixel = 1.05; // This bitrate approximately matches the quality produced by AVCaptureSessionPresetMedium or Low.
    }else {
        bitsPerPixel = 2.0; // This bitrate approximately matches the quality produced by AVCaptureSessionPresetHigh.
    }
    
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *compressionProperties = @{AVVideoAverageBitRateKey : @(bitsPerSecond),
                                            AVVideoExpectedSourceFrameRateKey : @(30),
                                            AVVideoMaxKeyFrameIntervalKey : @(60)};
    if (nil == videoSettings) {
        NSLog(@"No video settings provided, using default video settings");
        
        videoSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                          AVVideoWidthKey : @(dimensions.width),
                          AVVideoHeightKey : @(dimensions.height),
                          AVVideoCompressionPropertiesKey : compressionProperties};
    }
    
    if ([_assetWriter canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo])
    {
        _videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                     outputSettings:videoSettings
                                                   sourceFormatHint:videoFormatDescription];
        _videoInput.expectsMediaDataInRealTime = YES;
        _videoInput.transform = transform;
        
        if ([_assetWriter canAddInput:_videoInput])
        {
            [_assetWriter addInput:_videoInput];
        }else{
            if (errorOut) {
                *errorOut = [[self class] cannotSetupInputError];
            }
            return NO;
        }
    }else{
        if (errorOut) {
            *errorOut = [[self class] cannotSetupInputError];
        }
        return NO;
    }
    
    return YES;
}

+ (NSError *)cannotSetupInputError
{
    NSString *localizedDescription = NSLocalizedString( @"Recording cannot be started", nil );
    NSString *localizedFailureReason = NSLocalizedString( @"Cannot setup asset writer input.", nil );
    NSDictionary *errorDict = @{ NSLocalizedDescriptionKey : localizedDescription,
                                 NSLocalizedFailureReasonErrorKey : localizedFailureReason };
    return [NSError errorWithDomain:@"com.apple.dts.samplecode" code:0 userInfo:errorDict];
}

- (void)recoderLogWith:(NSString *)format, ...{
    if (self.recorderLog)
    {
        NSLog(@"%@", format);
    }
}




@end
