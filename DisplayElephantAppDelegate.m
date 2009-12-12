//
//  DisplayElephantAppDelegate.m
//  DisplayElephant
//
//  Created by Jon Nall on 12/11/09.
//  Copyright 2009 Newisys. All rights reserved.
//

#import "DisplayElephantAppDelegate.h"

@implementation DisplayElephantAppDelegate

@synthesize window;

void DisplayChangedCallback (
                             CGDirectDisplayID display,
                             CGDisplayChangeSummaryFlags flags,
                             void *userInfo
                             )
{
    if(flags & (kCGDisplayAddFlag | kCGDisplayRemoveFlag) == 0)
    {
        // A screen wasn't added or removed
        return;
    }

    CGDirectDisplayID activeDisplays[16];
    CGDisplayCount displayCount;
    
    CGDisplayErr result = CGGetActiveDisplayList(16,
                                                &(activeDisplays[0]),
                                                &displayCount);
    if(result != kCGErrorSuccess)
    {
        NSLog(@"Unable to acquire active display list: %d", result);
        return;
    }
    
    DisplayElephantAppDelegate* delegate = (DisplayElephantAppDelegate*)userInfo;
    [delegate saveWindowPositions];
}

-(void)saveWindowPositions
{    
    // Ultimately, create mapping of
    // BundleName -> [Array of WindowInfo {Name, Frame}]
    
    // Get all of the PIDs of the currently running applications
    NSMutableDictionary* pidMap = [NSMutableDictionary dictionary];
    
    for(NSDictionary* appInfo in [[NSWorkspace sharedWorkspace] launchedApplications])
    {
        [pidMap setObject:appInfo
                   forKey:[appInfo objectForKey:@"NSApplicationProcessIdentifier"]];
    }

    // displayInfo is the ultimate dictionary we're building
    NSMutableDictionary* displayInfo = [NSMutableDictionary dictionaryWithCapacity:[pidMap count]];

    // Acquire all windows that are visible and not weird OS UI stuff
    NSArray* allWindows = (NSArray*)CGWindowListCopyWindowInfo(
                                                               kCGWindowListOptionAll |
                                                               kCGWindowListExcludeDesktopElements |
                                                               kCGWindowListOptionOnScreenOnly,
                                                               kCGNullWindowID
                                                               );    
    for(NSDictionary* winInfo in allWindows)
    {
        // Check that windowName is some valid, non-empty string.
        NSString* windowName = [winInfo objectForKey:(NSString*)kCGWindowName];
        
        windowName = [windowName stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceCharacterSet]];

        if(windowName == nil || [windowName length] == 0)
        {
            // Ignore windows without names
            continue;
        }
        
        // Get the window's pid and match it up against the pidMap dictionary
        NSNumber* pid = [winInfo objectForKey:(NSString*)kCGWindowOwnerPID];
        NSMutableDictionary* appInfo = [pidMap objectForKey:pid];
        if(appInfo == nil)
        {
            continue;
        }
        
        // Get the bundleName. This is how we'll identify an app
        NSString* bundleID = [appInfo objectForKey:@"NSApplicationBundleIdentifier"];
        assert(bundleID != nil);

        // Create a windows array if need be. One entry per window in a given app
        NSMutableArray* windows = [displayInfo objectForKey:bundleID];
        if(windows == nil)
        {
            windows = [NSMutableArray array];
            [displayInfo setObject:windows
                            forKey:bundleID];
        }
        
        // Save the name and frame for this window
        NSDictionary* frame = [winInfo objectForKey:(NSString*)kCGWindowBounds];
        NSDictionary* curWinInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                    windowName, @"name",
                                    frame, @"frame",
                                    nil];
        [windows addObject:curWinInfo];
    }
    
    NSLog(@"%@", displayInfo);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    CGError result =  CGDisplayRegisterReconfigurationCallback (
                                                                DisplayChangedCallback,
                                                                self
                                                                );
    if(result != kCGErrorSuccess)
    {
        NSLog(@"Unable to register display callback: %d", result);
    }
    
    [self saveWindowPositions];
}

@end
