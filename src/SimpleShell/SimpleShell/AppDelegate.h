//
//  AppDelegate.h
//  SimpleShell
//
//  Created by jon on 2026-05-30.
//

#import <Cocoa/Cocoa.h>

#import "ViewController.h"
#import "AppDelegate.h"

#import "SettingsController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (strong) NSMutableArray<NSNumber *> *flag;
@property (strong) NSMutableArray<NSNumber *> *wide;
@property (strong) NSMutableArray<NSNumber *> *high;

@property (strong) NSMutableArray<ViewController *> *vcon;
@property (strong) NSMutableArray<MainProc *> *proc;

@property (strong) NSMutableArray<NSWindow *> *winl;

@property (strong) SettingsController *sets;

- (int)loop;

- (void)openPreferencesWindow:(id)sender;
- (void)makeNewWindow:(id)sender;
- (void)updateDockIcon;

@end
