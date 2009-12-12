//
//  DisplayElephantAppDelegate.h
//  DisplayElephant
//
//  Created by Jon Nall on 12/11/09.
//  Copyright 2009 Newisys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DisplayElephantAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;
-(void)saveWindowPositions;
@end
