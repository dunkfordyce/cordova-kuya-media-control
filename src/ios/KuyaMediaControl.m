#import "KuyaMediaControl.h"
#import <Cordova/CDV.h>

#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>


@implementation KuyaMediaControl

@synthesize nameMap = _nameMap;

-(void) pluginInitialize
{
    NSLog(@"KuyaMediaControl pluginInitialize()");
    
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
    
}

- (void)updateNowPlaying:(CDVInvokedUrlCommand *)command
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
    
        NSMutableDictionary* in_info = [command.arguments objectAtIndex:0];
        NSMutableDictionary* out_info = [[NSMutableDictionary alloc] init];
        
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
        
        NSString* art_url = [out_info objectForKey:MPMediaItemPropertyArtwork];
        if( art_url ) {
            [out_info removeObjectForKey:MPMediaItemPropertyArtwork];
            
            //UIImage *image;
            
            
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
                artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
                [out_info setObject:artwork forKey:MPMediaItemPropertyArtwork];
                NSLog(@"set image to %@", image);
            }
        }
        
        /*
        [out_info setObject:[NSNumber numberWithInt:100] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [out_info setObject:[NSNumber numberWithInt:200] forKey:MPMediaItemPropertyPlaybackDuration];
        [out_info setObject:[NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        */
        
        NSLog(@"setting %@", out_info);
        
        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
        center.nowPlayingInfo = out_info;
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
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true]
                                    callbackId:command.callbackId];
        
    });
}

@end
