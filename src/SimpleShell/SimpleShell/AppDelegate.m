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

#define MINW 750.0
#define MINH 350.0

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

- (void)winr:(NSString *)text indx:(int)indx wide:(CGFloat)wide high:(CGFloat)high rsiz:(int)rsiz {
    if ((indx >= [self.flag count])) { return; }
    ViewController *vcon = [self.vcon objectAtIndex:indx];
    NSWindow *wino = [self.winl objectAtIndex:indx];
    CGFloat oldw = [self.wide objectAtIndex:indx].floatValue;
    CGFloat oldh = [self.high objectAtIndex:indx].floatValue;
    CGFloat dirw = self.dirw.floatValue;
    CGFloat dirh = self.dirh.floatValue;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (vcon != nil) {
            CGFloat neww = (rsiz != 0) ? wide : oldw;
            CGFloat newh = (rsiz != 0) ? high : oldh;
            CGFloat fntw = 0.0;
            CGFloat fnth = 0.0;
            for (int y = 0; y < [self.proc count]; ++y) {
                MainProc *proc = [self.proc objectAtIndex:y];
                if ((proc.widx.intValue == indx) && (proc.vcon != nil) && (proc.stop.intValue == 0)) {
                    fntw = MAX(fntw, proc.vcon.fntw.floatValue);
                    fnth = MAX(fnth, proc.vcon.fnth.floatValue);
                }
            }
            if (rsiz == 9) {
                if (fntw > 0.0) {
                    CGFloat addw = 0.0;
                    if ((neww - dirw) > 1.33) { addw += fntw; }
                    neww = ((floor(neww / fntw) * fntw) + addw);
                }
                if (fnth > 0.0) {
                    CGFloat addh = 0.0;
                    if ((newh - dirh) > 1.33) { addh += fnth; }
                    newh = ((floor(newh / fnth) * fnth) + addh);
                }
            }
            NSRect winf = [wino frame];
            NSRect scrn = [[wino screen] visibleFrame];
            CGFloat topz = ((scrn.size.height - newh) + scrn.origin.y);
            CGFloat topy = ((scrn.size.height - winf.size.height) + scrn.origin.y);
            CGFloat offy = (topy - winf.origin.y);
            CGFloat adjx = winf.origin.x;
            CGFloat adjy = (topz - offy);
            if (rsiz != 0) {
                [self.wide replaceObjectAtIndex:indx withObject:@(neww)];
                [self.high replaceObjectAtIndex:indx withObject:@(newh)];
                [wino setFrame:NSMakeRect(adjx, adjy, neww, newh) display:YES];
            }
            for (int y = 0; y < [self.proc count]; ++y) {
                MainProc *proc = [self.proc objectAtIndex:y];
                if ((proc.widx.intValue == indx) && (proc.vcon != nil) && (proc.stop.intValue == 0)) {
                    [proc winz:text wide:neww high:newh];
                    NSLog(@"WINR [%@][%d] [%d][%d] [U] [%f][%f] [%f][%f] [%d][%d] [%f][%f]", text, rsiz, indx, y, dirw, dirh, neww, newh, proc.rows.intValue, proc.cols.intValue, proc.vcon.fntw.floatValue, proc.vcon.fnth.floatValue);
                }
            }
        }
    });
}

- (void)makeProc:(NSString *)text iidx:(NSInteger)iidx vobj:(ViewController *)vobj {
    NSInteger vidx = iidx;

    if (vobj != nil) {
        vidx = [self.vcon indexOfObject:vobj];
    }

    if ((vidx == NSNotFound) || (vidx <= -1) || (vidx >= [self.winl count]) || (vidx >= [self.flag count])) { return; }

    int rsiz = 2;
    int indx = ((int)vidx);

    NSNumber *wide = [self.wide objectAtIndex:indx];
    NSNumber *high = [self.high objectAtIndex:indx];
    NSWindow *wino = [self.winl objectAtIndex:indx];
    ViewController *vcon = [self.vcon objectAtIndex:indx];

    long leng = [self.proc count];

    MainProc *proc = [[MainProc alloc] init];
    [self.proc addObject:proc];

    NSLog(@"MAKE [%@] [%d] [%ld] [N] [%f][%f]", text, indx, leng, wide.floatValue, high.floatValue);

    [proc initProc:vcon widx:(int)indx indx:(int)leng wide:wide.floatValue high:high.floatValue wino:wino];
    [proc winz:text wide:wide.floatValue high:high.floatValue];

    [self.flag replaceObjectAtIndex:(int)indx withObject:@(3)];
    [self winr:text indx:indx wide:wide.floatValue high:high.floatValue rsiz:rsiz];
}

- (int)iniw:(int)init {
    NSString *strf = [[NSUserDefaults standardUserDefaults] stringForKey:@"main"];
    for (int x = 0; x < [self.winl count]; ++x) {
        NSWindow *wino = [self.winl objectAtIndex:x];
        CGFloat wide = MINW, high = MINH;
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
                    NSColor *defBgd = [NSColor colorWithRed:0.01 green:0.11 blue:0.17 alpha:0.91];
                    NSColor *defTab = [NSColor colorWithRed:0.21 green:0.45 blue:0.69 alpha:0.55];
                    NSColor *defTxt = [NSColor colorWithRed:0.99 green:0.85 blue:0.69 alpha:0.91];
                    NSColor *defSel = [NSColor colorWithRed:0.37 green:0.51 blue:0.93 alpha:0.75];
                    NSColor *defCrs = [NSColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:0.55];
                    NSColor *defInp = [NSColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:0.00];
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
    NSUInteger widx = [self.winl indexOfObject:wino];
    if ((!wino) || (widx == NSNotFound) || (widx >= [self.vcon count])) { return; }
    for (int x = 0; x < [self.proc count]; ++x) {
        MainProc *proc = [self.proc objectAtIndex:x];
        //NSLog(@"NSEventMaskKeyDown Proc Key: '%@' to Loop Index: %d | Window Index Match: %d | Proc Link Match: %d | Proc Objc Index: %d | Proc View Index: %d | True Key Win ptr: %p [%d]", objc.characters, x, (int)widx, proc.widx.intValue, proc.vidx.intValue, proc.vcon.indx.intValue, wino, flag);
        if (proc.stop.intValue == 0) {
            if ((proc.widx.intValue == widx) && (proc.vidx.intValue == proc.vcon.indx.intValue)) {
                if (flag == 0) { [proc inpt:objc letr:0]; flag = 1; }
            }
            last = proc;
        }
    }
    if (flag == 0) {
        if (last != nil) { [last inpt:objc letr:0]; }
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
        } else if ([initialController isKindOfClass:[NSViewController class]]) {
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
                NSLog(@"NEWW [%d] [%p]", x, [self.winl objectAtIndex:x]);
            }
        }

        [self iniw:0];

        if ([self.winl count] > 1) {
            NSWindow *prevWindow = [self.winl objectAtIndex:self.winl.count - 2];
            NSPoint topLeft = NSMakePoint(NSMinX(prevWindow.frame), NSMaxY(prevWindow.frame));
            NSPoint cascadedPoint = [wino cascadeTopLeftFromPoint:topLeft];
            [wino setFrameTopLeftPoint:cascadedPoint];
        }

        [wino makeKeyAndOrderFront:sender];
        if ([wino.contentViewController isKindOfClass:[ViewController class]]) {
            ViewController *vcon = (ViewController *)wino.contentViewController;
            [wino makeFirstResponder:vcon.view];
        }

        self.last = wino;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.357 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.last) {
                NSLog(@"WINT [%@]", self.last);
                [self.last makeKeyAndOrderFront:sender];
                if ([self.last.contentViewController isKindOfClass:[ViewController class]]) {
                    ViewController *vcon = (ViewController *)self.last.contentViewController;
                    [self.last makeFirstResponder:vcon.view];
                }
            }
        });

        NSLog(@"WINW [%lu] [%@]", [self.winl count], wino);
    });
}

- (void)stopAllTabs:(id)sender {
    int plen = ((int)[self.proc count]);
    NSUInteger pidx = [self.proc indexOfObject:sender];
    if ((pidx == NSNotFound) || (pidx >= plen)) { return; }
    int idxn = (int)pidx;
    MainProc *sent = (MainProc *)sender;
    for (int x = (plen - 1); x > -1; --x) {
        MainProc *proc = [self.proc objectAtIndex:x];
        if ((proc.wino == sent.wino) && (proc.vcon == sent.vcon)) {
            NSLog(@"TABS [%d] [%d]", idxn, x);
            [proc halt:@"tabs"];
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.dirw = @0;
    self.dirh = @0;

    self.flag = [NSMutableArray array];
    self.wide = [NSMutableArray array];
    self.high = [NSMutableArray array];
    self.proc = [NSMutableArray array];
    self.vcon = [NSMutableArray array];
    self.winl = [NSMutableArray array];

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
        NSUInteger widx = [self.winl indexOfObject:wino];
        NSWindow *wink = [NSApp keyWindow];
        //id responder = wino.firstResponder;
        //id controller = wino.contentViewController.view;
        //NSLog(@"NSEventMaskKeyDown Init Key: '%@' | Event Win ptr: %p (Responder: %p) | Tracking Win idx: %ld (Controller: %p) | Key Win ptr: %p", event.characters, wino, responder, widx, controller, wink);
        if ((widx != NSNotFound) && (wino == wink) && (wino.isKeyWindow)) {
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
    NSNumber *flag = [self.flag objectAtIndex:widx];
    [self.flag replaceObjectAtIndex:widx withObject:@(-1)];
    if (flag.intValue > 0) {
        NSRect temp = winn.frame;
        NSString *strf = NSStringFromRect(temp);
        [[NSUserDefaults standardUserDefaults] setObject:strf forKey:@"main"];
        NSLog(@"SAVE [%lu] [%@]", (unsigned long)widx, strf);
    }
    int leng = ((int)([self.proc count]) - 1);
    for (int x = leng; x > -1; --x) {
        MainProc *proc = [self.proc objectAtIndex:x];
        if (proc.widx.intValue == widx) {
            [proc halt:@"winx"];
        }
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    NSWindow *winn = notification.object;
    NSUInteger widx = [self.winl indexOfObject:winn];
    if ((widx == NSNotFound) || (widx >= [self.flag count])) { return; }
    int indx = ((int)widx);
    NSWindow *wino = [self.winl objectAtIndex:indx];
    NSNumber *flag = [self.flag objectAtIndex:indx];
    NSNumber *wide = [self.wide objectAtIndex:indx];
    NSNumber *high = [self.high objectAtIndex:indx];
    if (flag.floatValue == 0) { return; }
    NSRect frme = [wino frame];
    CGFloat widf = wide.floatValue;
    CGFloat higf = high.floatValue;
    int rsiz = 0;
    NSEvent *evnt = [NSApp currentEvent];
    BOOL user = ((evnt != nil) && (evnt.type == NSEventTypeLeftMouseDragged));
    if (user) {
        widf = frme.size.width;
        higf = frme.size.height;
        if (self.dirw.intValue == 0) { self.dirw = @(wide.floatValue); }
        if (self.dirh.intValue == 0) { self.dirh = @(high.floatValue); }
        rsiz = 1;
    }
    NSLog(@"RESI [%f][%f] -> [%f][%f] [%d] [%f][%f]", wide.floatValue, high.floatValue, widf, higf, rsiz, self.dirw.floatValue, self.dirh.floatValue);
}

- (void)windowDidEndLiveResize:(NSNotification *)notification {
    NSWindow *winn = notification.object;
    NSUInteger widx = [self.winl indexOfObject:winn];
    if ((widx == NSNotFound) || (widx >= [self.flag count])) { return; }
    int indx = ((int)widx);
    NSWindow *wino = [self.winl objectAtIndex:indx];
    NSNumber *flag = [self.flag objectAtIndex:indx];
    NSNumber *wide = [self.wide objectAtIndex:indx];
    NSNumber *high = [self.high objectAtIndex:indx];
    if (flag.floatValue == 0) { return; }
    NSRect frme = [wino frame];
    CGFloat widf = frme.size.width;
    CGFloat higf = frme.size.height;
    int rsiz = 9;
    NSLog(@"REND [%f][%f] -> [%f][%f] [%d] [%f][%f]", wide.floatValue, high.floatValue, widf, higf, rsiz, self.dirw.floatValue, self.dirh.floatValue);
    [self winr:@"rend" indx:indx wide:widf high:higf rsiz:rsiz];
    self.dirw = @(0);
    self.dirh = @(0);
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)fsiz {
    NSUInteger widx = [self.winl indexOfObject:sender];
    if ((widx == NSNotFound) || (widx >= [self.wide count])) { return fsiz; }
    int indx = ((int)widx);
    NSEvent *evnt = [NSApp currentEvent];
    BOOL user = ((evnt != nil) && (evnt.type == NSEventTypeLeftMouseDragged));
    if (user) {
        return fsiz;
    }
    CGFloat wide = [[self.wide objectAtIndex:indx] floatValue];
    CGFloat high = [[self.high objectAtIndex:indx] floatValue];
    NSLog(@"WINR DROP [%f] vs [%f]", fsiz.width, wide);
    return NSMakeSize(wide, high);
}

- (void)windowDidMove:(NSNotification *)notification {
    NSWindow *winn = notification.object;
    NSUInteger widx = [self.winl indexOfObject:winn];
    if ((widx == NSNotFound) || (widx >= [self.flag count])) { return; }
    int indx = ((int)widx);
    NSNumber *flag = [self.flag objectAtIndex:indx];
    if (flag.floatValue == 0) { return; }
    NSLog(@"WIMO [%d] [%f][%f] [%f][%f]", indx, winn.frame.origin.x, winn.frame.origin.y, winn.frame.size.width, winn.frame.size.height);
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
