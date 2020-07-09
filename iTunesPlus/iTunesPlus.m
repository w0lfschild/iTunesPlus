//
//  iTunesPlus.m
//  iTunesPlus
//
//  Created by Wolfgang Baird on 3/18/18.
//Copyright © 2018 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "iTunes.h"
#import "Music.h"

@interface iTunesPlus : NSObject
+ (instancetype)sharedInstance;
- (void)updateTrackInfo:(NSNotification *)notification;
@end

iTunesPlus *plugin;
NSMenu *itunesPlus;
NSImage *myImage;
NSUserDefaults *sharedPrefs;
bool showBadge = true;
int iconArt = 0;
NSString *overlayPath;
NSString *classicPath;
NSString *musicApp;

@implementation iTunesPlus

+ (instancetype)sharedInstance {
    static iTunesPlus *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

+ (void)load {
    plugin = [iTunesPlus sharedInstance];

    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    [dnc addObserver:plugin selector:@selector(updateTrackInfo:) name:@"com.apple.iTunes.playerInfo" object:nil];

    if (!sharedPrefs) sharedPrefs = [NSUserDefaults standardUserDefaults];
    if ([sharedPrefs objectForKey:@"showBadge"] == nil) [sharedPrefs setBool:true forKey:@"showBadge"];
    if ([sharedPrefs objectForKey:@"iconArt"] == nil) [sharedPrefs setInteger:0 forKey:@"iconArt"];

    showBadge = [[sharedPrefs objectForKey:@"showBadge"] boolValue];
    iconArt = (int)[sharedPrefs integerForKey:@"iconArt"];
    
    musicApp = @"iTunes+";
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.Music"]) musicApp = @"Music+";

    [plugin setMenu];

    NSLog(@"%@ loaded into %@ on macOS %@", [self class], NSBundle.mainBundle.bundleIdentifier, NSProcessInfo.processInfo.operatingSystemVersionString);
}

- (void)updateTrackInfo:(NSNotification *)notification {
//    NSDictionary *information = [notification userInfo];
//    NSLog(@"iTunesPlus : track information: %@", information);
    
    if ([musicApp isEqualToString:@"iTunes+"]) {
        // Mojave and below iTunes app support
        
        iTunesApplication *app = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        iTunesEPlS state = app.playerState;
            
        if (state == iTunesEPlSPlaying) {
            iTunesTrack *currentTrack = app.currentTrack;
            if (currentTrack != nil) {
                SBElementArray *artworks = [currentTrack artworks];
                iTunesArtwork *a = artworks[0];
            //        NSLog(@"iTunesPlus : track information: %@", [a rawData]);
                NSImage *img = [[NSImage alloc] initWithData:[a rawData]];
                myImage = img;
                if (iconArt > 0) {
                    if (img != nil) {
                        [NSApp setApplicationIconImage:[self createIconImage:myImage :iconArt]];
                    } else {
                        [NSApp setApplicationIconImage:nil];
                    }
                } else {
                    [NSApp setApplicationIconImage:nil];
                }
            }
        }
    } else {
        // Catalina Music app support
        
        MusicApplication *app = [SBApplication applicationWithBundleIdentifier:@"com.apple.Music"];
        MusicEPlS state = app.playerState;

        if (state == MusicEPlSPlaying) {
            MusicTrack *currentTrack = app.currentTrack;
            if (currentTrack != nil) {
                @try {
                    MusicArtwork *trackArt = currentTrack.artworks.firstObject;
                    NSImage *newArt = [[NSImage alloc] init];
                    
                    // For some reason in the Music app sometimes the expected return of NSImage from trackArt.data
                    // is instead an NSAppleEventDescriptor containing raw data otherwise it's an image like normal.
                    // Also trackArt.rawData appears to be no longer used and empty :(
                    if ([trackArt.data.className isEqualToString:@"NSAppleEventDescriptor"]) {
                        NSAppleEventDescriptor *t = (NSAppleEventDescriptor*)trackArt.data;
                        NSData *d = t.data;
                        newArt = [[NSImage alloc] initWithData:d];
                    } else {
                        newArt = trackArt.data;
                    }
                    
                    myImage = newArt;
                    if (iconArt > 0) {
                        if (newArt != nil) {
                            [NSApp setApplicationIconImage:[self createIconImage:myImage :iconArt]];
                        } else {
                            [NSApp setApplicationIconImage:nil];
                        }
                    } else {
                        [NSApp setApplicationIconImage:nil];
                    }
            
                } @catch (NSException *exception) {
                    NSLog(@"itp exception : %@", exception);
                    [NSApp setApplicationIconImage:nil];
                } @finally {
                    NSLog(@"Fin");
                }
            } else {
                [NSApp setApplicationIconImage:nil];
            }
        }
    }
    
    
}

- (void)setMenu {
    NSMenu* mainMenu = [NSApp mainMenu];
    itunesPlus = [plugin iTunesPlusMenu];
    NSMenuItem* newItem = [[NSMenuItem alloc] initWithTitle:musicApp action:nil keyEquivalent:@""];
    [newItem setSubmenu:itunesPlus];
    [mainMenu insertItem:newItem atIndex:mainMenu.itemArray.count];
}

- (IBAction)setBadges:(id)sender {
    showBadge = !showBadge;
    [sharedPrefs setBool:showBadge forKey:@"showBadge"];
    if (!showBadge)
        [[NSApp dockTile] setBadgeLabel:nil];
    [plugin updateMenu:itunesPlus];
}

- (IBAction)setIconArt:(id)sender {
    NSMenu *menu = [sender menu];
    NSArray *menuArray = [menu itemArray];
    iconArt = (int)[menuArray indexOfObject:sender];
    if (iconArt > 0) {
        NSImage *modifiedIcon = [plugin createIconImage:myImage :iconArt];
        [NSApp setApplicationIconImage:modifiedIcon];
    } else {
        [NSApp setApplicationIconImage:nil];
    }
    [sharedPrefs setInteger:iconArt forKey:@"iconArt"];
    [plugin updateMenu:itunesPlus];
}

- (IBAction)checkUpdate:(id)sender {
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"org.w0lf.mySIMBL" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:nil];
}

- (void)restartMe {
    float seconds = 3.0;
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:@"-c"];
    [args addObject:[NSString stringWithFormat:@"sleep %f; open \"%@\"", seconds, [[NSBundle mainBundle] bundlePath]]];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:args];
    [task launch];
    [NSApp terminate:nil];
}

- (NSImage*)imageRotatedByDegrees:(CGFloat)degrees :(NSImage*)img {
    NSSize size = img.size;
    NSSize newSize = NSMakeSize(size.width + 40, size.height + 40);
    NSImage *rotatedImage = [[NSImage alloc] initWithSize:newSize] ;
    NSAffineTransform *transform = [NSAffineTransform transform] ;
    [transform translateXBy:img.size.width/2 yBy:img.size.height/2];
    [transform rotateByDegrees:degrees] ;
    [transform translateXBy:-size.width/2 yBy:-size.height/2] ;
    [rotatedImage lockFocus] ;
    [transform concat] ;
    [img drawAtPoint:NSMakePoint(15,10) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0] ;
    [rotatedImage unlockFocus] ;
    return rotatedImage;
}

- (NSImage*)roundCorners:(NSImage *)image withRadius:(float)radius andShrink:(float)shrink {
    NSImage *existingImage = image;
    NSSize newSize = [existingImage size];
    NSImage *composedImage = [[NSImage alloc] initWithSize:newSize];

    float imgW = newSize.width;
    float imgH = newSize.height;
    float xShift = (imgW - (imgW * shrink)) / 2;
    float yShift = (imgH - (imgH * shrink)) / 2;

    [composedImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    NSRect imageFrame = NSRectFromCGRect(CGRectMake(xShift, yShift, (imgW * shrink), (imgH * shrink)));
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:imageFrame xRadius:radius yRadius:radius];
    [clipPath setWindingRule:NSEvenOddWindingRule];
    [clipPath addClip];
    [image drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, imgW, imgH) operation:NSCompositeSourceOver fraction:1];
    [composedImage unlockFocus];

    return composedImage;
}

- (NSString*)getOverlayPath:(NSString*)file {
    NSString *result = @"/tmp";
    NSString* bundlePath = [NSBundle bundleWithIdentifier:@"org.w0lf.iTunesPlus"].bundlePath;
    if (bundlePath.length)
        result = [bundlePath stringByAppendingFormat:@"/Contents/Resources/%@.png", file];
    return result;
}

- (NSImage*)addOverlay:(NSString*)pathToOverlay toImage:(NSImage*)input  {
    NSImage *overlay = [NSImage.alloc initByReferencingFile:pathToOverlay];
    NSImage *newImage = [NSImage.alloc initWithSize:input.size];
    [newImage lockFocus];
    CGRect newImageRect = CGRectZero;
    newImageRect.size = newImage.size;
    [input drawInRect:newImageRect];
    [overlay drawInRect:newImageRect];
    [newImage unlockFocus];
    return newImage;
}

- (NSImage*)createIconImage:(NSImage*)stockCover :(int)resultType {
    // 0 = None
    // 1 = square
    // 2 = tilded
    // 3 = classic round
    // 4 = modern round
    // 5 = rounded corners
    
    NSImage *resultIMG = NSImage.new;
    if (resultType == 1)
        resultIMG = stockCover;

    if (resultType == 2) {
        NSSize dims = NSApp.dockTile.size;
//        dims.width *= 0.9;
//        dims.height *= 0.9;
        NSImage *smallImage = [[NSImage alloc] initWithSize: dims];
        [smallImage lockFocus];
        [stockCover setSize: dims];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [stockCover drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, dims.width, dims.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        smallImage = [self imageRotatedByDegrees:8.00 :smallImage];
        resultIMG = smallImage;
    }

    if (resultType == 3) {
        if (![classicPath length])
            classicPath = [self getOverlayPath:@"ClassicOverlay"];
        NSImage *roundedCover = [self roundCorners:stockCover withRadius:stockCover.size.height andShrink:0.9];
        resultIMG = [self addOverlay:classicPath toImage:roundedCover];
    }

    if (resultType == 4) {
        if (![overlayPath length])
            overlayPath = [self getOverlayPath:@"ModernOverlay"];
        NSImage *roundedCover = [self roundCorners:stockCover withRadius:stockCover.size.height andShrink:0.85];
        resultIMG = [self addOverlay:overlayPath toImage:roundedCover];
    }
    
    if (resultType == 5)
        resultIMG = [self roundCorners:stockCover withRadius:stockCover.size.height/6 andShrink:0.8];

    if (resultIMG == nil)
        resultIMG = stockCover;
    
    return resultIMG;
}

- (NSMenu*)dockAddiTunesPlus:(NSMenu*)original {
    // Spotify+ meun item
    NSMenuItem *mainItem = [[NSMenuItem alloc] init];
    [mainItem setTitle:musicApp];

    NSMenu* dockspotplusMenu = [plugin iTunesPlusMenu];
    [mainItem setSubmenu:dockspotplusMenu];
    [self updateMenu:dockspotplusMenu];

    // Add our menu item
    [original addItem:[NSMenuItem separatorItem]];
    [original addItem:mainItem];

    return original;
}

- (NSMenu*)iTunesPlusMenu {
    // Icon art submenu
    NSMenuItem *artMenu = [[NSMenuItem alloc] init];
    [artMenu setTag:101];
    [artMenu setTitle:@"Show icon art"];
    NSMenu *submenuArt = [[NSMenu alloc] init];
    [[submenuArt addItemWithTitle:@"None" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Square" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Tilted" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Classic Circular" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Modern Circular" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    [[submenuArt addItemWithTitle:@"Rounded Corners" action:@selector(setIconArt:) keyEquivalent:@""] setTarget:plugin];
    for (NSMenuItem* item in [submenuArt itemArray]) [item setState:NSControlStateValueOff];
    if (iconArt < submenuArt.itemArray.count) [[[submenuArt itemArray] objectAtIndex:iconArt] setState:NSControlStateValueOn];
    [artMenu setSubmenu:submenuArt];

    // iTunes+ submenu
    NSMenu *submenuRoot = [[NSMenu alloc] init];
    [submenuRoot setTitle:musicApp];
    [submenuRoot addItem:artMenu];
    [[submenuRoot addItemWithTitle:@"Show paused badge" action:@selector(setBadges:) keyEquivalent:@""] setTarget:plugin];
    [submenuRoot.itemArray.lastObject setTag:97];
    [submenuRoot addItem:[NSMenuItem separatorItem]];
    [[submenuRoot addItemWithTitle:@"Check for updates" action:@selector(checkUpdate:) keyEquivalent:@""] setTarget:plugin];
    [submenuRoot addItem:[NSMenuItem separatorItem]];
    [[submenuRoot addItemWithTitle:@"Restart iTunes" action:@selector(restartMe) keyEquivalent:@""] setTarget:plugin];
    return submenuRoot;
}

- (void)updateMenu:(NSMenu*)original {
    if (original) {
        NSMenu* updatedMenu = original;
        [[updatedMenu itemWithTag:97] setState:showBadge];
        NSMenuItem* artMenu = [updatedMenu itemWithTag:101];
        NSArray* artSub = artMenu.submenu.itemArray;
        for (NSMenuItem* obj in artSub) [obj setState:NSControlStateValueOff];
        [artSub[iconArt] setState:NSControlStateValueOn];
    }
}

@end

ZKSwizzleInterface(_iTunesPlusNSAD, AppDelegateShim, NSObject)
@implementation _iTunesPlusNSAD

- (id)applicationDockMenu:(id)arg1 {
    NSMenu* result = ZKOrig(NSMenu*, arg1);
    result = [plugin dockAddiTunesPlus:result];
    return result;
}

@end

