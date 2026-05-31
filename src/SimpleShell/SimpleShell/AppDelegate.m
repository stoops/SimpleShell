//
//  AppDelegate.m
//  SimpleShell
//
//  Created by jon on 2026-05-30.
//

#import <Foundation/Foundation.h>
#import <util.h>

#import "ViewController.h"
#import "MainProc.h"
#import "AppDelegate.h"

@implementation AppDelegate

- (void)sign:(int)pidn {
    kill(pidn, SIGHUP);
    usleep(135000);
    kill(pidn, SIGTERM);
    usleep(135000);
    kill(pidn, SIGKILL);
}

- (void)stop:(MainProc *)proc pref:(NSString *)pref {
    if (proc.pidn.intValue > 0) {
        NSLog(@"KILL [%d] [%d] [%@]", proc.widx.intValue, proc.pidn.intValue, pref);
        [self sign:proc.pidn.intValue];
        proc.pidn = @(-1);
    }
    if (proc.mfdn.intValue > 0) {
        NSLog(@"MFDN [%d] [%d] [%@]", proc.widx.intValue, proc.mfdn.intValue, pref);
        close(proc.mfdn.intValue);
        proc.mfdn = @(-1);
    }
    if (proc.sfdn.intValue > 0) {
        NSLog(@"SFDN [%d] [%d] [%@]", proc.widx.intValue, proc.sfdn.intValue, pref);
        close(proc.sfdn.intValue);
        proc.sfdn = @(-1);
    }
    proc.stop = @(9);
}

- (void)menu {
    NSMenu *mainMenu = [NSApp mainMenu];
    if (!mainMenu) {
        mainMenu = [[NSMenu alloc] init];
        [NSApp setMainMenu:mainMenu];
    }
    NSMenuItem *appMenuItem = [mainMenu itemAtIndex:0];
    if (!appMenuItem) {
        appMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
        [mainMenu addItem:appMenuItem];
    }
    NSMenu *appMenu = [appMenuItem submenu];
    if (!appMenu) {
        appMenu = [[NSMenu alloc] initWithTitle:@"SimpleShell"];
        [appMenuItem setSubmenu:appMenu];
    }
    BOOL hasPrefs = NO;
    for (NSMenuItem *item in appMenu.itemArray) {
        if (item.action == @selector(openPreferencesWindow:)) {
            hasPrefs = YES;
            break;
        }
    }
    if (!hasPrefs) {
        NSMenuItem *prefsItem = [[NSMenuItem alloc] initWithTitle:@"Settings" action:@selector(openPreferencesWindow:) keyEquivalent:@","];
        [prefsItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
        [prefsItem setTarget:self];
        [appMenu insertItem:prefsItem atIndex:0];
    }
}

- (void)openPreferencesWindow:(id)sender {
    if (!self.sets) {
        self.sets = [[SettingsController alloc] init];
        if (self.vcon != nil) {
            self.sets.vcon = self.vcon;
        }
    }
    for (int x = 0; x < [self.winl count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        if (vcon != nil) {
            [self.sets updateColors:vcon.bgdc tab:vcon.tabc txt:vcon.txtc sel:vcon.selc csr:vcon.csrc];
        }
    }
    [self.sets showWindow:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (int)pros:(int)indx stop:(int)stop {
    int numb = 0;
    for (int x = 0; x < [self.proc count]; ++x) {
        MainProc *proc = [self.proc objectAtIndex:x];
        if (proc.widx.intValue == indx) {
            if (stop == 1) { ++numb; }
            else if (proc.stop.intValue == 0) { ++numb; }
        }
    }
    return numb;
}

- (int)loop {
    while (1) {
        for (int x = 0; x < [self.winl count]; ++x) {
            if (x >= [self.flag count]) { continue; }
            NSNumber *flag = [self.flag objectAtIndex:x];
            NSNumber *wide = [self.wide objectAtIndex:x];
            NSNumber *high = [self.high objectAtIndex:x];
            NSWindow *wino = [self.winl objectAtIndex:x];
            ViewController *vcon = [self.vcon objectAtIndex:x];
            if (flag.intValue >= 1) {
                if (flag.intValue == 1) {
                    [self.flag replaceObjectAtIndex:x withObject:@(2)];
                }
                if (([self pros:x stop:1] < 1) || (vcon.flag.intValue == 1)) {
                    vcon.flag = @(2);
                    int leng = ((int)[self.proc count]);
                    for (int z = leng; z < (leng + 1); ++z) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            MainProc *proc = [[MainProc alloc] init];
                            NSLog(@"MAKE [%d][%d] [N] [%f][%f]", x, z, wide.floatValue, high.floatValue);
                            [proc initProc:vcon widx:x indx:z wide:wide.floatValue high:high.floatValue wino:wino];
                            [proc wins:@"iniw" wide:wide.floatValue high:high.floatValue];
                            [self.proc addObject:proc];
                            if (flag.intValue == 2) {
                                [self.flag replaceObjectAtIndex:x withObject:@(3)];
                            }
                            [self winr:@"iniw" wide:[self.wide objectAtIndex:x].floatValue high:[self.high objectAtIndex:x].floatValue rsiz:0];
                        });
                    }
                }
            }
            if (flag.intValue >= 4) {
                for (int y = 0; y < [vcon.remo count]; ++y) {
                    int indx = [vcon.remo objectAtIndex:y].intValue;
                    if (indx < [self.proc count]) {
                        MainProc *proc = [self.proc objectAtIndex:indx];
                        [self stop:proc pref:@"remo"];
                    }
                }
                for (int y = 0; y < [self.proc count]; ++y) {
                    MainProc *proc = [self.proc objectAtIndex:y];
                    if (proc.widx.intValue == x) {
                        int stat = proc.stop.intValue;
                        if ((stat == 2) || (stat == 1)) {
                            [proc.vcon tabx:(proc.vidx.intValue - 1)];
                            [self stop:proc pref:@"stop"];
                        }
                        if (stat == 2) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [wino close];
                            });
                        }
                    }
                }
            }
        }
        usleep(357000);
    }
    return 0;
}

- (void)winr:(NSString *)text wide:(CGFloat)wide high:(CGFloat)high rsiz:(int)rsiz {
    for (int x = 0; x < [self.winl count]; ++x) {
        if (x >= [self.flag count]) { continue; }
        ViewController *vcon = [self.vcon objectAtIndex:x];
        NSWindow *wino = [self.winl objectAtIndex:x];
        if (vcon != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSRect winf = [wino frame];
                NSRect scrn = [[wino screen] visibleFrame];
                CGFloat topz = ((scrn.size.height - high) + scrn.origin.y);
                CGFloat topy = ((scrn.size.height - winf.size.height) + scrn.origin.y);
                CGFloat offy = (topy - winf.origin.y);
                CGFloat adjx = winf.origin.x;
                CGFloat adjy = (topz - offy);
                [self.wide replaceObjectAtIndex:x withObject:@(wide)];
                [self.high replaceObjectAtIndex:x withObject:@(high)];
                if (rsiz != 1) {
                    [wino setFrame:NSMakeRect(adjx, adjy, wide, high) display:YES];
                }
                for (int z = 0; z < [self.proc count]; ++z) {
                    MainProc *proc = [self.proc objectAtIndex:z];
                    if (proc.widx.intValue == x) {
                        [proc wins:text wide:wide high:high];
                        NSLog(@"WINR [%d][%d] [U] [%d][%d]", x, z, proc.rows.intValue, proc.cols.intValue);
                    }
                }
                [self.flag replaceObjectAtIndex:x withObject:@(4)];
            });
        }
    }
}

- (int)iniw:(int)init {
    NSString *strf = [[NSUserDefaults standardUserDefaults] stringForKey:@"main"];
    for (int x = 0; x < [self.winl count]; ++x) {
        if (x < [self.flag count]) { continue; }
        NSWindow *wino = [self.winl objectAtIndex:x];
        CGFloat wide = 750.0, high = 350.0;
        if (init != 1) {
            [self.wide addObject:@(wide)];
            [self.high addObject:@(high)];
            [wino setMovable:YES];
            [wino setTitle:@"SimpleShell"];
            [wino setFrameAutosaveName:@"main"];
            [wino setMinSize:NSMakeSize(wide, high)];
            [wino setOpaque:YES];
            [wino setTitlebarAppearsTransparent:YES];
            [wino setMovableByWindowBackground:YES];
            [wino setTitleVisibility:NSWindowTitleHidden];
            [wino setBackgroundColor:[NSColor clearColor]];
            [wino setDelegate:self];
            wino.styleMask |= NSWindowStyleMaskFullSizeContentView;
            if (strf) {
                NSRect frme = NSRectFromString(strf);
                [self.wide replaceObjectAtIndex:x withObject:@(frme.size.width)];
                [self.high replaceObjectAtIndex:x withObject:@(frme.size.height)];
                [wino setFrame:frme display:YES];
            }
            if ([wino.contentViewController isKindOfClass:[ViewController class]]) {
                ViewController *vcon = (ViewController *)wino.contentViewController;
                if (vcon != nil) {
                    [self.vcon addObject:vcon];
                    if (!self.sets) {
                        self.sets = [[SettingsController alloc] init];
                        self.sets.vcon = self.vcon;
                    }
                    NSColor *defBgd = [NSColor colorWithRed:0.01 green:0.11 blue:0.19 alpha:0.91];
                    NSColor *defTab = [NSColor colorWithRed:0.01 green:0.55 blue:0.55 alpha:0.31];
                    NSColor *defTxt = [NSColor colorWithRed:0.99 green:0.79 blue:0.59 alpha:0.91];
                    NSColor *defSel = [NSColor colorWithRed:0.99 green:0.79 blue:0.59 alpha:0.35];
                    NSColor *defCsr = [NSColor colorWithRed:0.99 green:0.79 blue:0.59 alpha:0.35];
                    [self.sets loadColors:defBgd tab:defTab txt:defTxt sel:defSel csr:defCsr];
                }
            }
            [self.flag addObject:@(1)];
        }
        NSLog(@"LOAD [%d] [%d] [%@]", x, init, strf);
    }
    return 0;
}

- (void)inpt:(NSEvent *)objc {
    NSWindow *wino = objc.window;
    if ((!wino) || (wino != [NSApp keyWindow])) { return; }
    NSUInteger widx = [self.winl indexOfObject:wino];
    if ((widx == NSNotFound) || (widx >= [self.vcon count])) { return; }
    for (int x = 0; x < [self.proc count]; ++x) {
        MainProc *proc = [self.proc objectAtIndex:x];
        //NSLog(@"NSEventMaskKeyDown Proc Key: '%@' to Loop Index: %d | Window Index Match: %d | Proc Link Match: %d | Proc Objc Index: %d | Proc View Index: %d | True Key Win ptr: %p", objc.characters, x, (int)widx, proc.widx.intValue, proc.vidx.intValue, proc.vcon.indx.intValue, wino);
        if ((proc.widx.intValue == widx) && (proc.stop.intValue == 0)) {
            if (proc.vidx.intValue == proc.vcon.indx.intValue) {
                [proc inpt:objc indx:0 letr:0];
            }
        }
    }
}

- (void)makeNewWindow:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        id initialController = [storyboard instantiateInitialController];

        NSWindow *wino = nil;
        if ([initialController isKindOfClass:[NSWindowController class]]) {
            NSWindowController *wc = (NSWindowController *)initialController;
            wino = wc.window;
        }
        else if ([initialController isKindOfClass:[NSViewController class]]) {
            NSViewController *vc = (NSViewController *)initialController;
            wino = [NSWindow windowWithContentViewController:vc];
        }

        if (!wino) {
            NSLog(@"ERROR: Could not resolve Window from Storyboard entry point.");
            return;
        }

        if (![self.winl containsObject:wino]) {
            [self.winl addObject:wino];
            for (int x = 0; x < [self.winl count]; ++x) {
                NSLog(@"WNEW [%d] [%p]", x, [self.winl objectAtIndex:x]);
            }
        }

        [self iniw:0];

        if ([wino.contentViewController isKindOfClass:[ViewController class]]) {
            [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
            [wino makeKeyAndOrderFront:sender];
            [wino makeKeyWindow];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([wino.contentViewController isKindOfClass:[ViewController class]]) {
                [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
                [wino makeKeyAndOrderFront:sender];
                [wino makeKeyWindow];
            }
        });

        NSLog(@"MWIN [%lu]", [self.winl count]);
    });
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.flag = [[NSMutableArray alloc] init];
    self.wide = [[NSMutableArray alloc] init];
    self.high = [[NSMutableArray alloc] init];
    self.proc = [[NSMutableArray alloc] init];
    self.vcon = [[NSMutableArray alloc] init];

    NSArray *bootWindows = [NSApplication sharedApplication].windows;
    self.winl = [[NSMutableArray alloc] initWithArray:bootWindows];

    NSLog(@"INIT [%ld]", [self.winl count]);

    NSImage *icon = [NSImage imageNamed:@"icon.png"];
    [NSApp setApplicationIconImage:icon];
    [self updateDockIcon];

    [self iniw:0];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self menu];
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self loop];
    });

    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        NSWindow *wino = event.window;
        //NSUInteger widx = [self.winl indexOfObject:wino];
        //NSWindow *wink = [NSApp keyWindow];
        //NSLog(@"NSEventMaskKeyDown Init Key: '%@' | Event Win ptr: %p (Tracking Index: %ld) | True Key Win ptr: %p | Is Target Match: %@", event.characters, wino, widx, wink, (wino == wink) ? @"YES" : @"NO");
        if ([wino.firstResponder isKindOfClass:NSClassFromString(@"CursorText")]) {
            [self inpt:event];
            return nil;
        }
        return event;
    }];
}

- (void)restoreWindowWithIdentifier:(NSUserInterfaceItemIdentifier)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow * _Nullable, NSError * _Nullable))completionHandler {
    NSLog(@"REWN");
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    int winc = 0, taba = 0;
    NSApplicationTerminateReply rets = NSTerminateNow;
    for (int x = 0; x < [self.winl count]; ++x) {
        if (x >= [self.flag count]) { continue; }
        NSNumber *flag = [self.flag objectAtIndex:x];
        if (flag.intValue < 1) { continue; }
        ++winc;
        int tabc = 0, tabd = 0;
        for (int y = 0; y < [self.proc count]; ++y) {
            MainProc *proc = [self.proc objectAtIndex:y];
            if (proc.widx.intValue != x) { continue; }
            if (proc.stop.intValue == 0) { ++tabc; ++taba; }
            else { ++tabd; }
        }
        NSLog(@"QUIT INFO Window [%d] Tabs Ok [%d] No [%d]", x, tabc, tabd);
        if (tabc > 1) { rets = NSTerminateCancel; }
    }
    NSLog(@"QUIT STAT Windows [%d] Tabs [%d]", winc, taba);
    //if (winc > 1) { rets = NSTerminateCancel; }
    return rets;
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
    NSUInteger widx = [self.winl indexOfObject:sender];
    if ((widx == NSNotFound) || (widx >= [self.flag count])) { return YES; }
    int tabc = [self pros:(int)widx stop:0];
    if (tabc > 1) {
        NSLog(@"TABS [%d] [%d]", (int)widx, tabc);
        return NO;
    }
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    NSWindow *winn = notification.object;
    NSUInteger widx = [self.winl indexOfObject:winn];
    if ((widx == NSNotFound) || (widx >= [self.flag count])) { return; }
    [self.flag replaceObjectAtIndex:widx withObject:@(-1)];
    if (widx == 0) {
        NSString *strf = NSStringFromRect(winn.frame);
        [[NSUserDefaults standardUserDefaults] setObject:strf forKey:@"main"];
        NSLog(@"SAVE [%@]", strf);
    }
    int leng = ((int)([self.proc count]) - 1);
    for (int x = leng; x > -1; --x) {
        MainProc *proc = [self.proc objectAtIndex:x];
        if (proc.widx.intValue == widx) {
            [self stop:proc pref:@"wind"];
            [self.proc removeObjectAtIndex:x];
        }
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    NSWindow *winn = notification.object;
    NSUInteger widx = [self.winl indexOfObject:winn];
    if ((widx == NSNotFound) || (widx >= [self.flag count])) { return; }
    NSWindow *wino = [self.winl objectAtIndex:widx];
    NSNumber *flag = [self.flag objectAtIndex:widx];
    NSNumber *wide = [self.wide objectAtIndex:widx];
    NSNumber *high = [self.high objectAtIndex:widx];
    NSRect frme = [wino frame];
    CGFloat widf = wide.floatValue;
    CGFloat higf = high.floatValue;
    if (flag.floatValue == 0) { return; }
    int rsiz = 0;
    NSEvent *evnt = [NSApp currentEvent];
    BOOL user = ((evnt != nil) && (evnt.type == NSEventTypeLeftMouseDragged));
    if (user) {
        widf = frme.size.width;
        higf = frme.size.height;
        rsiz = 1;
    }
    NSLog(@"WINR [%f][%f] [%d]", widf, higf, rsiz);
    [self winr:@"rsiz" wide:widf high:higf rsiz:rsiz];
}

- (void)windowDidMove:(NSNotification *)notification {
    NSWindow *winn = notification.object;
    NSUInteger widx = [self.winl indexOfObject:winn];
    if ((widx == NSNotFound) || (widx >= [self.flag count])) { return; }
    NSNumber *wide = [self.wide objectAtIndex:widx];
    NSNumber *high = [self.high objectAtIndex:widx];
    NSNumber *flag = [self.flag objectAtIndex:widx];
    CGFloat widf = wide.floatValue;
    CGFloat higf = high.floatValue;
    if (flag.floatValue == 0) { return; }
    NSLog(@"WINM [%f][%f]", widf, higf);
    [self winr:@"wmov" wide:widf high:higf rsiz:1];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)fsiz {
    NSUInteger widx = [self.winl indexOfObject:sender];
    if ((widx == NSNotFound) || (widx >= [self.wide count])) {
        return fsiz;
    }
    NSEvent *evnt = [NSApp currentEvent];
    BOOL user = ((evnt != nil) && (evnt.type == NSEventTypeLeftMouseDragged));
    if (user) {
        return fsiz;
    }
    BOOL deny = YES;
    if (deny) {
        CGFloat wide = [[self.wide objectAtIndex:widx] floatValue];
        CGFloat high = [[self.high objectAtIndex:widx] floatValue];
        NSLog(@"[Intercept] Denied programmatic resize request to wide: %f. Reverting to tracked wide: %f", fsiz.width, wide);
        return NSMakeSize(wide, high);
    }
    return fsiz;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (!flag) {
        [self makeNewWindow:nil];
        return NO;
    }
    return YES;
}

- (void)updateDockIcon {
    NSImage *originalIcon = [NSImage imageNamed:@"icon.png"];
    if (!originalIcon) return;

    BOOL shouldRotate = [[NSUserDefaults standardUserDefaults] boolForKey:@"roti"];

    if (!shouldRotate) {
        [NSApp setApplicationIconImage:originalIcon];
        return;
    }

    CGFloat angle = 15.0;
    CGFloat scaleFactor = 0.91;

    NSSize canvasSize = originalIcon.size;

    CGFloat dstWide = canvasSize.width * scaleFactor;
    CGFloat dstHigh = canvasSize.height * scaleFactor;
    CGFloat offsetX = (canvasSize.width - dstWide) / 2.0;
    CGFloat offsetY = (canvasSize.height - dstHigh) / 2.0;
    NSRect drawingRect = NSMakeRect(offsetX, offsetY, dstWide, dstHigh);

    NSImage *rotatedIcon = [[NSImage alloc] initWithSize:canvasSize];
    [rotatedIcon lockFocus];

    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:canvasSize.width / 2.0 yBy:canvasSize.height / 2.0];
    [transform rotateByDegrees:angle];
    [transform translateXBy:-canvasSize.width / 2.0 yBy:-canvasSize.height / 2.0];
    [transform concat];

    [originalIcon drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [rotatedIcon unlockFocus];

    [NSApp setApplicationIconImage:rotatedIcon];
}

@end
