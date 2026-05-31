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
            [self.sets updateColors:vcon.bgdc tab:vcon.tabc txt:vcon.txtc sel:vcon.selc crs:vcon.crsc inp:vcon.inpc];
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

- (void)makeProc:(NSString *)text iidx:(NSInteger)iidx vobj:(ViewController *)vobj {
    NSInteger indx = iidx;

    if (vobj != nil) {
        indx = [self.vcon indexOfObject:vobj];
    }

    if ((indx == NSNotFound) || (indx <= -1) || (indx >= [self.winl count]) || (indx >= [self.flag count])) { return; }

    NSNumber *wide = [self.wide objectAtIndex:indx];
    NSNumber *high = [self.high objectAtIndex:indx];
    NSWindow *wino = [self.winl objectAtIndex:indx];
    ViewController *vcon = [self.vcon objectAtIndex:indx];

    long leng = [self.proc count];

    MainProc *proc = [[MainProc alloc] init];
    [self.proc addObject:proc];

    NSLog(@"MAKE [%@] [%ld][%ld] [N] [%f][%f]", text, indx, leng, wide.floatValue, high.floatValue);

    [proc initProc:vcon widx:(int)indx indx:(int)leng wide:wide.floatValue high:high.floatValue wino:wino];
    [proc winz:text wide:wide.floatValue high:high.floatValue];

    [self.flag replaceObjectAtIndex:(int)indx withObject:@(3)];
    [self winr:text wide:wide.floatValue high:high.floatValue rsiz:0];
}

- (void)winr:(NSString *)text wide:(CGFloat)wide high:(CGFloat)high rsiz:(int)rsiz {
    for (int x = 0; x < [self.winl count]; ++x) {
        if ((x >= [self.flag count])) { continue; }
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
                        [proc winz:text wide:wide high:high];
                        NSLog(@"WINR [%@] [%d][%d] [U] [%d][%d]", text, x, z, proc.rows.intValue, proc.cols.intValue);
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
        NSWindow *wino = [self.winl objectAtIndex:x];
        CGFloat wide = 750.0, high = 350.0;
        if (x < [self.flag count]) { continue; }
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
                    NSColor *defSel = [NSColor colorWithRed:0.37 green:0.51 blue:0.93 alpha:0.75];
                    NSColor *defCrs = [NSColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:0.55];
                    NSColor *defInp = [NSColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.00];
                    [self.sets loadColors:defBgd tab:defTab txt:defTxt sel:defSel crs:defCrs inp:defInp];
                }
            }
            [self.flag addObject:@(1)];
            [self makeProc:@"iniw" iidx:x vobj:nil];
        }
        NSLog(@"LOAD [%d] [%d] [%@]", x, init, strf);
    }
    return 0;
}

- (void)inpt:(NSEvent *)objc {
    int flag = 0;
    MainProc *last = nil;
    NSWindow *wino = objc.window;
    if ((!wino) || (wino != [NSApp keyWindow])) { return; }
    NSUInteger widx = [self.winl indexOfObject:wino];
    if ((widx == NSNotFound) || (widx >= [self.vcon count])) { return; }
    for (int x = 0; x < [self.proc count]; ++x) {
        MainProc *proc = [self.proc objectAtIndex:x];
        //NSLog(@"NSEventMaskKeyDown Proc Key: '%@' to Loop Index: %d | Window Index Match: %d | Proc Link Match: %d | Proc Objc Index: %d | Proc View Index: %d | True Key Win ptr: %p [%d]", objc.characters, x, (int)widx, proc.widx.intValue, proc.vidx.intValue, proc.vcon.indx.intValue, wino, flag);
        if (proc.stop.intValue == 0) {
            if ((proc.widx.intValue == widx) && (proc.vidx.intValue == proc.vcon.indx.intValue)) {
                if (flag == 0) { [proc inpt:objc indx:0 letr:0]; flag = 1; }
            }
            last = proc;
        }
    }
    if (flag == 0) {
        if (last != nil) { [last inpt:objc indx:0 letr:0]; }
        else { exit(0); }
    }
}

- (void)makeNewWindow:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        id initialController = [storyboard instantiateControllerWithIdentifier:@"MainView"];

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
    self.winl = [[NSMutableArray alloc] init];

    for (NSWindow *window in [NSArray arrayWithArray:[NSApp windows]]) {
        [window close];
    }
    [self makeNewWindow:nil];

    NSLog(@"INIT [%ld]", [self.winl count]);

    [self updateDockIcon];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self menu];
    });

    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        NSWindow *wino = event.window;
        if (!wino) { return event; }
        id winc = wino.windowController;
        if ([winc isKindOfClass:NSClassFromString(@"SettingsController")]) { return event; }
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
            [proc stop:@"wind"];
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
    NSLog(@"RESI [%f][%f] [%d]", widf, higf, rsiz);
    if (user) { [self winr:@"rsiz" wide:widf high:higf rsiz:rsiz]; }
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
    NSLog(@"WIMO [%f][%f]", widf, higf);
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
    NSImage *icon = [NSImage imageNamed:@"icon.png"];
    if (!icon) { return; }

    BOOL rots = [[NSUserDefaults standardUserDefaults] boolForKey:@"roti"];

    CGFloat angl = (!rots) ? 0.0 : 15.0;
    CGFloat fact = (0.93 * 0.97);

    NSSize size = icon.size;

    CGFloat wide = (size.width * fact);
    CGFloat high = (size.height * fact);
    CGFloat offx = ((size.width - wide) / 2.0);
    CGFloat offy = ((size.height - high) / 2.0);
    NSRect drawingRect = NSMakeRect(offx, offy, wide, high);

    NSImage *icor = [[NSImage alloc] initWithSize:size];
    [icor lockFocus];

    NSAffineTransform *form = [NSAffineTransform transform];
    [form translateXBy:(size.width / 2.0) yBy:(size.height / 2.0)];
    [form rotateByDegrees:angl];
    [form translateXBy:(-size.width / 2.0) yBy:(-size.height / 2.0)];
    [form concat];

    [icon drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [icor unlockFocus];

    [NSApp setApplicationIconImage:icor];
}

@end
