#import <Cordova/CDV.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>
#import <AVFoundation/AVPlayer.h>

@interface KuyaMediaControl : CDVPlugin {
    NSDictionary* nameMap;
    MPMediaItemArtwork* artwork;
    UIImage* image;
    NSMutableDictionary* cached_info;
    AVPlayer* player;
    NSTimer* timer;
}

@property (retain) NSDictionary* nameMap;
@property (retain) MPMediaItemArtwork* artwork;
@property (retain) UIImage *image;
@property (retain) NSMutableDictionary* cached_info;
@property (retain) AVPlayer* player;
@property (retain) NSTimer* timer;

+ (KuyaMediaControl*) kuyaMediaControl;
- (void) pluginInitialize;
- (void) updateNowPlaying:(CDVInvokedUrlCommand*) command;
- (void) load:(CDVInvokedUrlCommand*) command;
- (void) play:(CDVInvokedUrlCommand*) command;
- (void) pause:(CDVInvokedUrlCommand*) command;
- (void) duration:(CDVInvokedUrlCommand*) command;
- (NSString*) format_float:(Float64) v;
- (void)receiveRemoteEvent:(UIEvent *)receivedEvent;

@end
