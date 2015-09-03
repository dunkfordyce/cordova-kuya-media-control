#import "KuyaMediaControl.h"
#import <Cordova/CDV.h>

#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>

#import <AVFoundation/AVPlayerItem.h>
#import <AVFoundation/AVTime.h>
#import <AVFoundation/AVFoundation.h>

#import <CoreMedia/CMTime.h>
#import <Math.h>


@implementation KuyaMediaControl

@synthesize nameMap = _nameMap;
@synthesize artwork = _artwork;
@synthesize image   = _image;
@synthesize cached_info = _cached_info;
@synthesize player  = _player;
@synthesize timer = _timer;


static KuyaMediaControl* kuyaMediaControl = nil;

+(KuyaMediaControl*) kuyaMediaControl
{
    /*if( !kuyaMediaControl ) {
        kuyaMediaControl = [[KuyaMediaControl alloc] init];
    }*/
    
    return kuyaMediaControl;
}


-(void) pluginInitialize
{
    NSLog(@"KuyaMediaControl pluginInitialize() %@", self);
    
    kuyaMediaControl = self;
    
    
    nameMap = [ [NSDictionary alloc] initWithObjectsAndKeys :
                                MPMediaItemPropertyTitle, @"title",
                                MPMediaItemPropertyAlbumTitle, @"album_title",
                                MPMediaItemPropertyArtist, @"artist",
                                MPMediaItemPropertyPlaybackDuration, @"playback_duration",
                                MPNowPlayingInfoPropertyElapsedPlaybackTime, @"elapsed_playback_time",
                                MPMediaItemPropertyAlbumTrackNumber, @"album_track_number",
                                MPMediaItemPropertyAlbumTrackCount, @"album_track_count",
                                MPMediaItemPropertyArtwork, @"artwork",
                                MPNowPlayingInfoPropertyPlaybackRate, @"playback_rate",
                                nil
                             ];
    
    MPRemoteCommandCenter* remote = [MPRemoteCommandCenter sharedCommandCenter];
    remote.playCommand.enabled = YES;
    [remote.nextTrackCommand addTarget:self action:@selector(remote_next:)];
    [remote.previousTrackCommand addTarget:self action:@selector(remote_prev:)];
    [remote.playCommand addTarget:self action:@selector(remote_play:)];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok;
    NSError *setCategoryError = nil;
    ok = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    if (!ok) {
        NSLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, setCategoryError);
    }
    
}

- (void)updateNowPlaying:(CDVInvokedUrlCommand *)command
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
    
        NSMutableDictionary* in_info = [command.arguments objectAtIndex:0];
        bool update = [[command.arguments objectAtIndex:1] boolValue];
        NSMutableDictionary* out_info = update ? self.cached_info : [[NSMutableDictionary alloc] init];
    
        for (NSString* key in in_info) {
            NSString* mapped = [nameMap objectForKey:key];
            if( mapped ) {
                [out_info setValue:[in_info objectForKey:key] forKey:mapped];
            } else {
                [self.commandDelegate
                    sendPluginResult:[CDVPluginResult
                                        resultWithStatus:CDVCommandStatus_ERROR
                                        messageAsString:[NSString
                                                stringWithFormat:@"Invalid property %@, valid properties %@",
                                                key,
                                                [[nameMap allKeys]componentsJoinedByString:@" "]
                                        ]
                                     ]
                    callbackId:command.callbackId
                ];
                return;
            }
            
        }
        
        NSString* art_url = [in_info objectForKey:@"artwork"];
        if( art_url ) {
            //UIImage *image;
            //art_url = @"http://vignette4.wikia.nocookie.net/fantendo/images/5/52/Mushroom2.PNG/revision/latest?cb=20111123224555";
            
            if ([art_url hasPrefix: @"http://"] || [art_url hasPrefix: @"https://"]) {
                NSURL *imageURL = [NSURL URLWithString:art_url];
                NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
                image = [UIImage imageWithData:imageData];
            }
            // cover is full path to local file
            else if ([art_url hasPrefix: @"file://"]) {
                NSString *fullPath = [art_url stringByReplacingOccurrencesOfString:@"file://" withString:@""];
                if( [[NSFileManager defaultManager] fileExistsAtPath:fullPath] ) {
                    image = [UIImage imageNamed:fullPath];
                }
            }
            // cover is relative path to local file
            else {
                NSString *basePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                NSString *fullPath = [NSString stringWithFormat:@"%@%@", basePath, art_url];
                if( [[NSFileManager defaultManager] fileExistsAtPath:fullPath] ) {
                    image = [UIImage imageNamed:fullPath];
                }
            }
            
            if( image ) {
                NSData *pngData = UIImagePNGRepresentation(image); // Convert it in to PNG data
                image = [UIImage imageWithData:pngData]; // Result image
                
                artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
                [out_info setObject:artwork forKey:MPMediaItemPropertyArtwork];
                NSLog(@"set image to %@", image);
            } else {
                [out_info removeObjectForKey: @"artwork"];
            }
        }
        
        /*
        [out_info setObject:[NSNumber numberWithInt:100] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [out_info setObject:[NSNumber numberWithInt:200] forKey:MPMediaItemPropertyPlaybackDuration];
        [out_info setObject:[NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        */
        
        NSLog(@"setting %@ update %@", out_info, update ? @"True" : @"false");
        
        self.cached_info = out_info;
        
        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
        center.nowPlayingInfo = self.cached_info;
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true]
                                    callbackId:command.callbackId];
        
        NSNumber *current = [out_info objectForKey:MPMediaItemPropertyAlbumTrackNumber];
        NSNumber *total = [out_info objectForKey:MPMediaItemPropertyAlbumTrackCount];
        
        if(  current != nil && total != nil ) {
            NSLog(@"fixing forward/back");
            MPRemoteCommandCenter* remote = [MPRemoteCommandCenter sharedCommandCenter];
            
            remote.previousTrackCommand.enabled = ([current intValue] > 1 ? YES : NO);
            
            remote.nextTrackCommand.enabled = ([current intValue] < [total intValue] ? YES : NO);
            
            
        }

        /*
        center.nowPlayingInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                 artist, MPMediaItemPropertyArtist,
                                 title, MPMediaItemPropertyTitle,
                                 album, MPMediaItemPropertyAlbumTitle,
                                 artwork, MPMediaItemPropertyArtwork,
                                 duration, MPMediaItemPropertyPlaybackDuration,
                                 elapsed, MPNowPlayingInfoPropertyElapsedPlaybackTime,
                                 [NSNumber numberWithInt:1], MPNowPlayingInfoPropertyPlaybackRate, nil];
         */
        
        
        
    });
    
}

- (void) load:(CDVInvokedUrlCommand*)command
{
    NSString *url = [command.arguments objectAtIndex:0];
    
    if( self.player ) {
        [self.player removeObserver:self forKeyPath: @"status"];
        [self.player removeObserver:self forKeyPath: @"currentItem.loadedTimeRanges"];
        [self.player removeObserver:self forKeyPath: @"currentItem.seekableTimeRanges"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:player];
        [self.player pause];
        self.player = nil;
        
        //[[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    if( self.timer ) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    self.player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:url]];
    
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    
    [self.player addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    [self.player addObserver:self
             forKeyPath:@"currentItem.loadedTimeRanges"
                options:NSKeyValueObservingOptionNew
                context:NULL];
    
    [self.player addObserver:self
                  forKeyPath:@"currentItem.seekableTimeRanges"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
    

    
    [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(playerItemDidReachEnd:)
         name:AVPlayerItemDidPlayToEndTimeNotification
         object:player];
    
    
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                               messageAsBool:true
                                            ]
                                callbackId:command.callbackId
     ];
}

- (void) duration:(CDVInvokedUrlCommand*) command
{
    if( !self.player) {
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_ERROR
                           messageAsString:@"no player"
                           ]
               callbackId:command.callbackId
         ];
    }
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                             messageAsDouble:CMTimeGetSeconds(self.player.currentItem.duration)
                                            ]
                                callbackId:command.callbackId
     ];
}

-(void)remote_play: (MPRemoteCommandHandlerStatus *)event{
    [self.commandDelegate evalJs: [NSString stringWithFormat:@"cordova.fireDocumentEvent('KuyaMediaControl_button', {button: '%@', source: 'remote'})", @"play"]];
}

-(void)remote_prev: (MPRemoteCommandHandlerStatus *)event{
    [self.commandDelegate evalJs: [NSString stringWithFormat:@"cordova.fireDocumentEvent('KuyaMediaControl_button', {button: '%@', source: 'remote'})", @"prevTrack"]];
}

-(void)remote_next: (MPRemoteCommandHandlerStatus *)event{
   [self.commandDelegate evalJs: [NSString stringWithFormat:@"cordova.fireDocumentEvent('KuyaMediaControl_button', {button: '%@', source: 'remote'})", @"nextTrack"]];
}



- (void) play:(CDVInvokedUrlCommand*)command
{
    if( [self _play] < 0 ) {
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_ERROR
                           messageAsString:@"no player"
                           ]
         callbackId:command.callbackId
         ];
    } else {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true]
                                    callbackId:command.callbackId];

    }
}


- (int) _play
{
    if( !self.player ) {
        return -1;
    }
    
    if( !self.timer ) {
        [self.player play];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                      target:self
                                                    selector:@selector(updateProgress:)
                                                    userInfo:nil
                                                     repeats:YES
                      ];
    }
    
    [self.cached_info setValue: [NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    center.nowPlayingInfo = self.cached_info;
    
    return 0;
    }

- (void) pause:(CDVInvokedUrlCommand*)command
{
    if( [self _pause] < 0 ) {
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_ERROR
                           messageAsString:@"no player"
                           ]
         callbackId:command.callbackId
         ];
    } else {
        [self.commandDelegate sendPluginResult:[CDVPluginResult
                                                resultWithStatus:CDVCommandStatus_OK
                                                messageAsBool:true
                                                ]
                                    callbackId:command.callbackId];
    }
}

- (int) _pause
{
    if( !self.player ) {
        return -1;
    }
    
    if( self.timer ) {
        [self.player pause];
        [self.timer invalidate];
        self.timer = nil;
    }
    
    [self.cached_info setValue: [NSNumber numberWithInt:0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    center.nowPlayingInfo = self.cached_info;
    return 0;
}

- (void) seek:(CDVInvokedUrlCommand*)command
{
    if( !self.player ) {
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult
                           resultWithStatus:CDVCommandStatus_ERROR
                           messageAsString:@"no player"
                           ]
         callbackId:command.callbackId
         ];
    }
    
    NSNumber* seek_n = [command.arguments objectAtIndex:0];
    Float64 seek = [seek_n floatValue];
    
    [self.player seekToTime:CMTimeMakeWithSeconds(seek, 1)];
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true]
                                callbackId:command.callbackId];
}

- (NSString*)format_float:(Float64) v
{
    if( isnan(v) ) {
        return @"NaN";
    }
    
    return [NSString stringWithFormat:@"%f", v];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.player && [keyPath isEqualToString:@"status"]) {
        if (self.player.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayer Failed");
            [self.commandDelegate evalJs: @"cordova.fireDocumentEvent('KuyaMediaControl_status', {status: 'failed'})"];
        } else if (self.player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            [self.commandDelegate evalJs: @"cordova.fireDocumentEvent('KuyaMediaControl_status', {status: 'readyToPlay'})"];
            //[self.player play];
        } else if (self.player.status == AVPlayerItemStatusUnknown) {
             NSLog(@"AVPlayer Unknown");
            [self.commandDelegate evalJs: @"cordova.fireDocumentEvent('KuyaMediaControl_status', {status: 'unknown'})"];
        }
    } else if( object == self.player && [keyPath isEqualToString:@"currentItem.loadedTimeRanges"] ) {
        NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
        if (timeRanges && [timeRanges count]) {
            
            NSMutableArray *js = [[NSMutableArray alloc] init];
            
            for (NSValue* v in timeRanges) {
                CMTimeRange timerange = [v CMTimeRangeValue];
                
                [js addObject: [NSString stringWithFormat:@"{start: %@, duration: %@}",
                                [self format_float:CMTimeGetSeconds(timerange.start) ],
                                [self format_float:CMTimeGetSeconds(timerange.duration)]
                                ]];
                
                NSLog(@" . . . %.5f -> %.5f", CMTimeGetSeconds(timerange.start), CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration)));
            }
            
            [self.commandDelegate evalJs: [NSString
                                           stringWithFormat:@"cordova.fireDocumentEvent('KuyaMediaControl_loaded', {ranges: [%@]})",
                                           [js componentsJoinedByString:@", "]
                                           ]
            ];
        }
    } else if( object == self.player && [keyPath isEqualToString:@"currentItem.seekableTimeRanges"] ) {
        NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
        if (timeRanges && [timeRanges count]) {
            
            NSMutableArray *js = [[NSMutableArray alloc] init];
            
            for (NSValue* v in timeRanges) {
                CMTimeRange timerange = [v CMTimeRangeValue];
                
                [js addObject: [NSString stringWithFormat:@"{start: %@, duration: %@}",
                                [self format_float:CMTimeGetSeconds(timerange.start) ],
                                [self format_float:CMTimeGetSeconds(timerange.duration)]
                                ]];
                
                NSLog(@" . . . %.5f -> %.5f", CMTimeGetSeconds(timerange.start), CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration)));
            }
            
            [self.commandDelegate evalJs: [NSString
                                           stringWithFormat:@"cordova.fireDocumentEvent('KuyaMediaControl_seekable', {ranges: [%@]})",
                                           [js componentsJoinedByString:@", "]
                                           ]
             ];
        }
    }
}

- (void) updateProgress:(NSTimer*)timer
{
    NSLog(@"update %f %f", CMTimeGetSeconds(self.player.currentItem.duration), CMTimeGetSeconds(self.player.currentItem.currentTime));
    [self.commandDelegate evalJs: [NSString
                                   stringWithFormat:@"cordova.fireDocumentEvent('KuyaMediaControl_progress', {duration: %@, time: %@})",
                                   [self format_float:CMTimeGetSeconds(self.player.currentItem.duration)],
                                   [self format_float:CMTimeGetSeconds(self.player.currentItem.currentTime)]
                                   ]
    ];
    
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    
    [self.cached_info setValue: [NSNumber numberWithInt:CMTimeGetSeconds(self.player.currentItem.duration)] forKey:MPMediaItemPropertyPlaybackDuration];
    [self.cached_info setValue: [NSNumber numberWithInt:CMTimeGetSeconds(self.player.currentItem.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    center.nowPlayingInfo = self.cached_info;
}

- (void) playerItemDidReachEnd: (NSNotification *)notification
{
    [self _pause];
    [self.commandDelegate evalJs: @"cordova.fireDocumentEvent('KuyaMediaControl_status', {status: 'finished'})"];
    
}

- (void)receiveRemoteEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type != UIEventTypeRemoteControl) {
        NSLog(@"not our event type");
        return;
    }
    
    NSString *subtype = @"other";
    
    switch (receivedEvent.subtype) {
        case UIEventSubtypeRemoteControlPreviousTrack:
        case UIEventSubtypeRemoteControlNextTrack:
        case UIEventSubtypeRemoteControlPlay:
            // these are all handled seperatly on each button
            return;
            
        case UIEventSubtypeRemoteControlTogglePlayPause:
            subtype = @"playpause";
            break;
        case UIEventSubtypeRemoteControlPause:
            subtype = @"pause";
            break;
                default:
            break;
    }
    NSLog(@"got event %@ %@", subtype, self);
    [self.commandDelegate evalJs: [NSString stringWithFormat:@"cordova.fireDocumentEvent('KuyaMediaControl_button', {button: '%@', source: 'switch'})", subtype]];
    NSLog(@"cordova.fireDocumentEvent('KuyaMediaControl_button', {button: '%@'})", subtype);
}

@end
