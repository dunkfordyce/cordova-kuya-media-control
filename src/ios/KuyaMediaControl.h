#import <Cordova/CDV.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>

@interface KuyaMediaControl : CDVPlugin {
    NSDictionary* nameMap;
    MPMediaItemArtwork* artwork;
    UIImage* image;
    NSMutableDictionary* cached_info;
}

@property (retain) NSDictionary* nameMap;
@property (retain) MPMediaItemArtwork* artwork;
@property (retain) UIImage *image;
@property (retain) NSMutableDictionary* cached_info;

- (void) pluginInitialize;
- (void) updateNowPlaying:(CDVInvokedUrlCommand*)command;

@end
