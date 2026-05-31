//
//  MainProc.m
//  SimpleShell
//
//  Created by jon on 2026-06-05.
//

#import <Foundation/Foundation.h>
#import <util.h>

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <sys/ioctl.h>

#import "ViewController.h"
#import "MainProc.h"
#import "AppDelegate.h"

#define MINR 15
#define MINC 75
#define LOCT 95
#define LOCW 135
#define SBWA  63.0
#define SBHA 103.0
#define SBHB  33.0

@interface MainProc ()
- (void)comp:(NSString *)pref mode:(int)mode;
- (unsigned long long)getl;
- (NSAttributedString *)gout:(NSString *)pref mode:(int)mode;
- (void)clrs:(NSString *)pref hist:(int)hist scrn:(int)scrn ctrl:(int)ctrl;
- (void)refw:(NSString *)pref prio:(int)prio keep:(int)keep glob:(int)glob titi:(NSString *)titi;
- (void)refv:(NSString *)text sels:(int)sels indx:(int)indx cidx:(int)cidx datf:(int)datf;
@end

static int screen_movecursor(VTermPos pos, VTermPos oldpos, int visible, void *user) {
    static CFAbsoluteTime last = 0;
    MainProc *self = (__bridge MainProc *)(user);
    CFAbsoluteTime nows = CFAbsoluteTimeGetCurrent();
    if ((nows - last) < 0.015) {
        NSLog(@"DLAY CURS [%f] [%f]", last, nows);
        //return 1;
    }
    __block int indx = 0;
    __block int mode = 0;
    __block int cidx = 0;
    @synchronized (self) {
        self.crow = @(pos.row);
        self.ccol = @(pos.col);
        indx = self.vidx.intValue;
        mode = self.mode.intValue;
        cidx = ((self.crow.intValue << 16) | (self.ccol.intValue & 0xffff));
        NSLog(@"CURS [%d][%d] [%d][%d] [%d]", self.crow.intValue, self.ccol.intValue, self.rows.intValue, self.cols.intValue, self.mode.intValue);
        if (mode == 2) {
            NSLog(@"MODE LOCK [%d] [%d][%d] [%d][%d]", self.mode.intValue, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue);
            self.loco = @([self getl]);
        } else {
            /*if (self.ccol.intValue < self.ocol.intValue) {
                NSLog(@"COLS LOCK [%d] [%d][%d] [%d][%d]", self.mode.intValue, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue);
                self.loco = @([self getl]);
                self.orow = @(self.crow.intValue); self.ocol = @(self.ccol.intValue);
            }*/
            if (self.crow.intValue < self.orow.intValue) {
                NSLog(@"CURS LOCK [%d] [%d][%d] [%d][%d]", self.mode.intValue, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue);
                self.loco = @([self getl]);
                self.orow = @(self.crow.intValue); self.ocol = @(self.ccol.intValue);
            }
        }
        if (mode > 2) {
            cidx = -1;
        }
        if (mode > 1) {
            [self refv:@"curs" sels:mode indx:indx cidx:cidx datf:1];
        }/* else {
            [self refv:@"curs" sels:1 indx:indx cidx:-1 datf:0];
        }*/
        if ((nows - last) > 0.015) {
            [self refv:@"curs" sels:0 indx:indx cidx:-1 datf:0];
        }
    };
    last = nows;
    return 0;
}

static int screen_damage(VTermRect rect, void *user) {
    static CFAbsoluteTime last = 0;
    MainProc *self = (__bridge MainProc *)(user);
    CFAbsoluteTime nows = CFAbsoluteTimeGetCurrent();
    if ((nows - last) < 0.015) {
        NSLog(@"DLAY DISP [%f] [%f]", last, nows);
        return 1;
    }
    __block int indx = 0;
    __block int mode = 0;
    __block int cidx = 0;
    @synchronized (self) {
        indx = self.vidx.intValue;
        mode = self.mode.intValue;
        cidx = ((self.crow.intValue << 16) | (self.ccol.intValue & 0xffff));
        //NSLog(@"DISP [%d] [%d][%d] [%d][%d]", self.mode.intValue, self.crow.intValue, self.ccol.intValue, self.rows.intValue, self.cols.intValue);
        if ((rect.start_row == self.crow.intValue) && (rect.start_col == 0)) {
            NSLog(@"CURK [%d] [%d][%d]", self.mode.intValue, self.crow.intValue, self.ccol.intValue);
            /* ![K */
        }
        if (mode > 2) {
            cidx = -1;
        }
        if (mode > 1) {
            [self refv:@"disp" sels:mode indx:indx cidx:cidx datf:1];
        }/* else {
            [self refv:@"disp" sels:1 indx:indx cidx:-1 datf:0];
        }*/
        if ((nows - last) > 0.015) {
            [self refv:@"disp" sels:0 indx:indx cidx:-1 datf:0];
        }
    };
    last = nows;
    return 0;
}

static int screen_settermprop(VTermProp prop, VTermValue *val, void *user) {
    MainProc *self = (__bridge MainProc *)(user);
    if (prop == VTERM_PROP_ALTSCREEN) {
        __block int indx = 0;
        __block int mode = 0;
        __block int cidx = 0;
        @synchronized (self) {
            int grid = val->boolean;
            NSLog(@"PROP LOCK [%d] [%d] [%d][%d] [%d][%d]", grid, self.mode.intValue, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue);
            self.loco = @([self getl]);
            if (grid) {
                NSLog(@"ANSI MODE");
                self.ljob = @(0);
                self.mode = @(2);
            } else {
                NSLog(@"LINE MODE");
                self.ljob = @(0);
                self.mode = @(0);
            }
            indx = self.vidx.intValue;
            mode = self.mode.intValue;
            cidx = ((self.crow.intValue << 16) | (self.ccol.intValue & 0xffff));
            if (mode == 2) {
                [self refv:@"prop" sels:2 indx:indx cidx:cidx datf:0];
                [self refw:@"prop" prio:9 keep:1 glob:0 titi:@"ansi"];
            } else {
                [self clrs:@"prop" hist:0 scrn:1 ctrl:0];
                [self refv:@"prop" sels:8 indx:indx cidx:cidx datf:0];
                [self refw:@"prop" prio:9 keep:1 glob:0 titi:@"line"];
            }
            [self refv:@"prop" sels:0 indx:indx cidx:-1 datf:0];
        };
    }
    if ((prop == VTERM_PROP_TITLE) || (prop == VTERM_PROP_ICONNAME)) {
        const char *cTitle = val->string.str;
        if (cTitle != NULL) {
            /*NSString *newTitle = [NSString stringWithUTF8String:cTitle];
            NSLog(@"TITL [%@] [%@]", newTitle, self);*/
        }
    }
    return 1;
}

@implementation MainProc

- (void)magicPrompt:(NSString *)comd argsList:(NSArray<NSString *> *)args intervalTime:(uint64_t)secs {
    dispatch_queue_t queue = dispatch_queue_create("com.simpleshell.magicPrompt", DISPATCH_QUEUE_SERIAL);
    self.loot = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

    uint64_t interval = secs * NSEC_PER_SEC;
    dispatch_source_set_timer(self.loot, dispatch_time(DISPATCH_TIME_NOW, 0), interval, 0);

    __weak MainProc *weakSelf = self;
    dispatch_source_set_event_handler(self.loot, ^{
        MainProc *strongSelf = weakSelf;
        if (!strongSelf || strongSelf.stop.intValue != 0) { return; }

        NSTask *task = [[NSTask alloc] init];
        NSPipe *pipe = [NSPipe pipe];

        [task setLaunchPath:comd];
        [task setArguments:args];
        [task setStandardOutput:pipe];
        [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

        NSMutableData *data = [NSMutableData data];
        NSFileHandle *hand = [pipe fileHandleForReading];

        __weak NSFileHandle *weakHandle = hand;
        [hand setReadabilityHandler:^(NSFileHandle *file) {
            NSData *part = nil;
            @try {
                part = [file availableData];
            } @catch (NSException *exception) {
                NSLog(@"Read handle intercepted closure: %@", exception.reason);
                part = nil;
            }
            if (part && part.length > 0) {
                [data appendData:part];
            } else {
                [weakHandle setReadabilityHandler:nil];
            }
        }];

        NSError *erro = nil;
        if (![task launchAndReturnError:&erro]) {
            NSLog(@"EXEC STAT ERROR [%@]", erro.localizedDescription);
            [hand setReadabilityHandler:nil];
            return;
        }

        [task waitUntilExit];
        [hand setReadabilityHandler:nil];

        NSData *outp = [data copy];

        if (outp.length > 0) {
            NSString *stro = [[NSString alloc] initWithData:outp encoding:NSUTF8StringEncoding];
            stro = [stro stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.prom = stro;
                [strongSelf inpt:nil letr:0];
            });
        }
    });

    dispatch_resume(self.loot);
}

- (void)statLoop:(uint64_t)secs {
    dispatch_queue_t statsQueue = dispatch_queue_create("com.simpleshell.statloop", DISPATCH_QUEUE_SERIAL);
    self.loos = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, statsQueue);

    uint64_t intervalNs = secs * NSEC_PER_SEC;
    dispatch_source_set_timer(self.loos, dispatch_time(DISPATCH_TIME_NOW, 0), intervalNs, 0);

    __weak MainProc *weakSelf = self;
    dispatch_source_set_event_handler(self.loos, ^{
        MainProc *strongSelf = weakSelf;
        if (!strongSelf || strongSelf.stop.intValue != 0) { return; }

        BOOL isStatsPanelEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"sysv"];
        if (!isStatsPanelEnabled) { return; }

        NSString *bundPath = [[NSBundle mainBundle] resourcePath];
        NSString *execPath = [bundPath stringByAppendingPathComponent:@"stat.sh"];

        if (![[NSFileManager defaultManager] fileExistsAtPath:execPath]) {
            NSLog(@"ERROR: stat.sh missing at path: %@", execPath);
            return;
        }

        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/bin/bash"];
        [task setArguments:@[execPath]];

        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

        NSMutableData *data = [NSMutableData data];
        NSFileHandle *hand = [pipe fileHandleForReading];

        __weak NSFileHandle *weakHandle = hand;
        [hand setReadabilityHandler:^(NSFileHandle *file) {
            NSData *part = nil;
            @try {
                part = [file availableData];
            } @catch (NSException *exception) {
                NSLog(@"Read handle intercepted closure: %@", exception.reason);
                part = nil;
            }
            if (part && part.length > 0) {
                [data appendData:part];
            } else {
                [weakHandle setReadabilityHandler:nil];
            }
        }];

        NSError *erro = nil;
        if (![task launchAndReturnError:&erro]) {
            NSLog(@"EXEC STAT ERROR [%@]", erro.localizedDescription);
            [hand setReadabilityHandler:nil];
            return;
        }

        [task waitUntilExit];
        [hand setReadabilityHandler:nil];

        NSData *outp = [data copy];

        if (outp.length > 0) {
            NSString *strw = [[NSString alloc] initWithData:outp encoding:NSUTF8StringEncoding];
            NSString *strc = [strw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            NSArray<NSString *> *news = [strc componentsSeparatedByString:@"\n"];
            if (news.count > 2) {
                NSString *cpus = [news[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *rams = [news[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *nets = [news[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                nets = [nets stringByReplacingOccurrencesOfString:@"%d" withString:@"\u2B07"];
                nets = [nets stringByReplacingOccurrencesOfString:@"%u" withString:@"\u2B06"];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (strongSelf.vcon != nil) {
                        if ((strongSelf.vidx != nil) && (strongSelf.vcon.indx != nil)) {
                            if (strongSelf.vidx.intValue != strongSelf.vcon.indx.intValue) {
                                return;
                            }
                        }
                        strongSelf.vcon.cpuv.stringValue = cpus;
                        strongSelf.vcon.ramv.stringValue = rams;
                        strongSelf.vcon.netv.stringValue = nets;
                    }
                });
            }
        }
    });

    dispatch_resume(self.loos);
}

- (unsigned long long)getl {
    NSDate *date = [NSDate date];
    unsigned long long mill = (long long)([date timeIntervalSince1970] * 1000.0);
    return mill;
}

- (int)chkf {
    if (self.stop.intValue > 0) { return 1; }
    if (self.pidn.intValue < 1) { return 2; }
    if (self.mfdn.intValue < 1) { return 3; }
    if (self.sfdn.intValue < 1) { return 4; }
    return 0;
}

- (void)sign:(int)pidn {
    kill(pidn, SIGHUP);
    usleep(135000);
    kill(pidn, SIGTERM);
    usleep(135000);
    kill(pidn, SIGKILL);
}

- (void)stop:(NSString *)pref {
    self.stop = @(9);
    if (self.pidn.intValue > 0) {
        NSLog(@"KILL [%@] [%d][%d] [%d] {%d}", pref, self.widx.intValue, self.indx.intValue, self.pidn.intValue, self.stop.intValue);
        [self sign:self.pidn.intValue];
        self.pidn = @(-1);
    }
    if (self.mfdn.intValue > 0) {
        NSLog(@"MFDN [%@] [%d][%d] [%d] {%d}", pref, self.widx.intValue, self.indx.intValue, self.mfdn.intValue, self.stop.intValue);
        close(self.mfdn.intValue);
        self.mfdn = @(-1);
    }
    if (self.sfdn.intValue > 0) {
        NSLog(@"SFDN [%@] [%d][%d] [%d] {%d}", pref, self.widx.intValue, self.indx.intValue, self.sfdn.intValue, self.stop.intValue);
        close(self.sfdn.intValue);
        self.sfdn = @(-1);
    }
}

- (void)halt:(NSString *)pref {
    if (self.stop.intValue >= 1) { return; }
    self.stop = @(1);
    int indx = (self.vidx.intValue - 1);
    if ((self.vcon == nil) || (indx < 0) || (indx >= [self.vcon.tabl count])) { return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        int numt = 0;
        for (int x = 0; x < [self.vcon.tabl count]; ++x) {
            long tagn = [self.vcon.tabl objectAtIndex:x].tag;
            if (tagn < 1) { continue; }
            ++numt;
        }
        NSLog(@"HALT [%@] [%d] [%d] [%d]", pref, indx, numt, self.stop.intValue);
        [self.vcon tabx:self.vidx.intValue];
        [self stop:pref];
        if (numt <= 1) {
            if (self.wino != nil) {
                [self.wino performClose:nil];
            }
        }
        AppDelegate *appd = (AppDelegate *)[NSApp delegate];
        if ([appd.proc containsObject:self]) {
            [appd.proc removeObject:self];
        }
    });
}

- (void)clrs:(NSString *)pref hist:(int)hist scrn:(int)scrn ctrl:(int)ctrl {
    NSLog(@"CLRS [%@] [%d] [%d] [%d] [%d]", pref, self.mode.intValue, hist, scrn, ctrl);
    self.irow = @(0); self.icol = @(0);
    self.orow = @(0); self.ocol = @(0);
    if (hist == 1) {
        [self.hist removeAllObjects];
    }
    if (scrn == 1) {
        vterm_screen_reset(self.vtsc, 1);
        self.crow = @0; self.ccol = @0;
        self.scre = @(1);
    }
    if (ctrl == 1) {
        for (int z = 0; z < 1; ++z) {
            char byte = 3;
            write(self.mfdn.intValue, &byte, 1);
        }
    }
}

- (void)refw:(NSString *)pref prio:(int)prio keep:(int)keep glob:(int)glob titi:(NSString *)titi {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.vcon != nil) {
            int indx = (glob == 1) ? -1 : self.vidx.intValue;
            [self.vcon wini:indx prio:prio keep:keep titi:titi];
        }
    });
}

- (void)refv:(NSString *)text sels:(int)sels indx:(int)indx cidx:(int)cidx datf:(int)datf {
    //NSLog(@"REFV [%@] [%d] [%ld]", text, sels, [data length]);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.vcon != nil) {
            int rows = self.rows.intValue;
            int cols = self.cols.intValue;
            if (sels == 0) {
                [self inpt:nil letr:0];
                dispatch_time_t popt = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(LOCW * NSEC_PER_MSEC));
                dispatch_after(popt, dispatch_get_main_queue(), ^{
                    [self inpt:nil letr:0];
                });
            } else if (sels == 1) {
                [self comp:@"refv" mode:0];
                dispatch_time_t popt = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(LOCW * NSEC_PER_MSEC));
                dispatch_after(popt, dispatch_get_main_queue(), ^{
                    [self comp:@"refv" mode:0];
                });
            } else {
                NSAttributedString *data = (datf == 0) ? nil : [self gout:@"jobs" mode:2];
                [self.vcon show:text data:data pref:nil indx:indx sels:sels cidx:cidx rows:rows cols:cols];
            }
        }
    });
}

- (void)jobs:(NSString *)pref mode:(int)mode {
    @synchronized (self) {
        if (mode == 0) {
            if ((self.mode.intValue == 0) && (self.ljob.intValue == 0)) {
                pid_t fpid = tcgetpgrp(self.mfdn.intValue);
                pid_t spid = getpgid(self.pidn.intValue);
                if ((fpid > 0) && (fpid != spid)) {
                    NSLog(@"JOBS INIT [%@] [%d] [%d]", pref, mode, self.vidx.intValue);
                    [self refv:@"jobs" sels:3 indx:self.vidx.intValue cidx:-1 datf:1];
                    [self refw:@"jobs" prio:5 keep:1 glob:0 titi:@"jobs"];
                    self.ljob = @(1);
                    self.mode = @(3);
                }
            }
        }
        if (mode == 1) {
            if ((self.mode.intValue != 9) && (self.ljob.intValue != 0)) {
                NSLog(@"JOBS STOP [%@] [%d] [%d]", pref, mode, self.vidx.intValue);
                if (self.ljob.intValue == 1) {
                    [self refv:pref sels:8 indx:self.vidx.intValue cidx:-1 datf:0];
                }
                [self refv:pref sels:0 indx:self.vidx.intValue cidx:-1 datf:0];
                [self refw:@"jobs" prio:5 keep:0 glob:0 titi:@""];
                self.ljob = @(0);
                self.mode = @(0);
            }
        }
        if (mode == 2) {
            if ((self.mode.intValue != 2) && (self.ljob.intValue == 1)) {
                NSLog(@"JOBS LINE [%d]", self.vidx.intValue);
                [self refv:@"outp" sels:8 indx:self.vidx.intValue cidx:-1 datf:0];
                [self refw:@"jobs" prio:5 keep:0 glob:0 titi:@""];
                self.ljob = @(2);
                self.mode = @(0);
            }
        }
    };
}

- (NSColor *)nsColorFromVTermColor:(VTermColor)vcolor {
    NSColor *txtc = nil;
    if (self.vcon != nil) {
        txtc = self.vcon.txtc;
    } else {
        txtc = [NSColor whiteColor];
    }
    if (vcolor.type == VTERM_COLOR_DEFAULT_FG) { return nil; }
    VTermState *state = vterm_obtain_state(self.term);
    if (state == NULL) { return nil; }
    vterm_state_convert_color_to_rgb(state, &vcolor);
    if (VTERM_COLOR_IS_RGB(&vcolor)) {
        txtc = [NSColor colorWithRed:(vcolor.rgb.red / 255.0) green:(vcolor.rgb.green / 255.0) blue:(vcolor.rgb.blue / 255.0) alpha:txtc.alphaComponent];
    }
    return txtc;
}

- (NSMutableAttributedString *)atrl:(NSString *)line atrs:(NSMutableArray *)atrs {
    NSMutableAttributedString *rets = [[NSMutableAttributedString alloc] initWithString:line attributes:@{}];
    for (int c = 0; c < [atrs count]; ++c) {
        NSRange rang = NSMakeRange(c, 1);
        NSDictionary *props = atrs[c];
        [rets addAttribute:NSForegroundColorAttributeName value:props[@"fg"] range:rang];
        if (props[@"bg"]) {
            [rets addAttribute:NSBackgroundColorAttributeName value:props[@"bg"] range:rang];
        }
    }
    return rets;
}

- (NSArray *)scan:(NSArray *)a srcs:(NSArray *)b numb:(int)c {
    int f = -1, r = 0, s = 0, x = 0, y = 0, z = 0;
    int l = ((int)([a count])), n = MIN(c, ((int)[b count]));
    if (([a count] < 1) || ([b count] < 1)) { return @[@(x), @(y), @(z)]; }
    while ((x < l) && (y < n)) {
        NSString *c = [a objectAtIndex:x];
        NSString *d = [b objectAtIndex:y];
        if ([d isEqualToString:c]) {
            if (f < 0) {
                r = x; s = y;
                f = 1;
            }
            ++x; ++y; z += ([d length] + 1);
        } else {
            if (f > 0) {
                x = (r + 1); y = 0; z = 0;
            } else {
                x = (x + 1); y = 0; z = 0;
            }
            r = 0; s = 0;
            f = -1;
        }
    }
    return @[@(x), @(y), @(z)];
}

- (void)comp:(NSString *)pref mode:(int)mode {
    if (self.mode.intValue != 0) { return; }
    NSMutableAttributedString *outs = [[NSMutableAttributedString alloc] init];
    NSAttributedString *outa = [[NSAttributedString alloc] init];
    NSString *outp = @"";
    NSArray *grid = @[];
    int numb = MAX(3, self.rows.intValue / 5);
    if ((mode == 0) || (mode == 1)) {
        outa = [self gout:pref mode:1];
        outp = [outa.string copy];
        grid = [outp componentsSeparatedByString:@"\n"];
    }
    if (mode == 2) {
        [outs appendAttributedString:self.part];
        [self.part deleteCharactersInRange:NSMakeRange(0, [self.part length])];
    }
    if ([outp length] > 0) {
        int zlen = (self.rows.intValue * 3);
        int dlen = ((int)[self.hist count]), glen = ((int)[grid count]);
        int bidx = (dlen > zlen) ? dlen - zlen : 0, eidx = MIN(dlen, zlen);
        NSArray *last = (eidx > 0) ? [self.hist subarrayWithRange:NSMakeRange(bidx, eidx)] : @[];
        NSArray *idxs = [self scan:last srcs:grid numb:numb];
        int didx = ((NSNumber *)[idxs objectAtIndex:0]).intValue;
        int gidx = ((NSNumber *)[idxs objectAtIndex:1]).intValue;
        int indx = ((NSNumber *)[idxs objectAtIndex:2]).intValue;
        int flag = 0;
        //NSLog(@"COMP [%@] [%d][%d] [%d][%d] [%d][%d] [%d] [%@][%@] [%@]", pref, mode, self.scre.intValue, bidx, eidx, didx, gidx, indx, last, grid, self.hist);
        for (int x = (bidx + didx), y = gidx; y < glen; ++x, ++y) {
            NSString *item = (x >= [self.hist count]) ? nil : [self.hist objectAtIndex:x];
            NSString *line = [grid objectAtIndex:y];
            long leng = [line length];
            if ((item == nil) || (![line isEqualToString:item])) {
                NSRange lrng = NSMakeRange(indx, leng);
                NSAttributedString *atrs = [outa attributedSubstringFromRange:lrng];
                NSAttributedString *news = [[NSAttributedString alloc] initWithString:@"\n" attributes:@{}];
                if ([self.hist count] < 1) { news = [[NSAttributedString alloc] init]; }
                if (self.scre.intValue == 1) {
                    if (([line length] < 1) && (flag < 9)) {
                        NSLog(@"COMP SKIP [%d][%d]", x, y);
                        news = [[NSAttributedString alloc] init];
                        atrs = [[NSAttributedString alloc] init];
                        flag = 1;
                    } else {
                        flag = 9;
                        self.scre = @(2);
                    }
                }
                if (mode == 0) {
                    [outs appendAttributedString:news];
                    [outs appendAttributedString:atrs];
                }
                if (mode == 1) {
                    [self.part appendAttributedString:news];
                    [self.part appendAttributedString:atrs];
                }
                if (item == nil) { [self.hist addObject:[line copy]]; }
                else { [self.hist replaceObjectAtIndex:x withObject:[line copy]]; }
            }
            indx += (leng + 1);
        }
    }
    if ([outs length] > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.vcon != nil) {
                int sels = 1;
                [self.vcon show:@"line" data:outs pref:nil indx:self.vidx.intValue sels:sels cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];
            }
        });
        [self refw:@"outp" prio:8 keep:0 glob:0 titi:@"outp"];
        self.scre = @(3);
    }
}

- (NSAttributedString *)gout:(NSString *)pref mode:(int)mode {
    NSMutableAttributedString *rets = [[NSMutableAttributedString alloc] init];
    if (self.vcon == nil) { return rets; }

    if ((mode == 0) || (mode == 1) || (mode == 2)) {
        VTermState *stat = vterm_obtain_state(self.term);

        NSMutableString *line = [NSMutableString string];
        NSMutableString *cstr = [NSMutableString string];
        NSMutableArray *list = [NSMutableArray array];
        NSMutableArray *atrs = [NSMutableArray array];
        NSMutableArray *latr = [NSMutableArray array];

        int maxr = self.rows.intValue;
        int maxc = self.cols.intValue;
        int lira = 0, lirb = 0, lirw = 0, lirz = 0;
        unsigned long long nows = [self getl];
        //int debg = 1;

        if ((maxr < 5) || (maxc < 5)) {
            return rets;
        }

        for (int r = 0; r < maxr; ++r) {
            for (int c = 0; c < maxc; ++c) {
                VTermScreenCell cell;
                VTermPos cpos = { .row = r, .col = c };
                if (vterm_screen_get_cell(self.vtsc, cpos, &cell)) {
                    NSColor *txtc = [self nsColorFromVTermColor:cell.fg];
                    if (mode == 2) {
                        if ((31 < cell.chars[0]) && (cell.chars[0] < 127)) {
                            [cstr appendFormat:@"%C", (unsigned short)cell.chars[0]];
                        } else {
                            [cstr appendFormat:@" "];
                        }
                        [atrs addObject:@{ @"fg":(txtc != nil) ? txtc : self.vcon.txtc }];
                    } else {
                        if (cell.chars[0] != 0) {
                            if ((31 < cell.chars[0]) && (cell.chars[0] < 127)) {
                                [cstr appendFormat:@"%C", (unsigned short)cell.chars[0]];
                            } else {
                                [cstr appendFormat:@" "];
                            }
                            [atrs addObject:@{ @"fg":(txtc != nil) ? txtc : self.vcon.txtc }];
                        }
                    }
                }
            }
            BOOL wrap = NO;
            if ((stat != NULL) && ((r + 1) < maxr)) {
                const VTermLineInfo *info = vterm_state_get_lineinfo(stat, r + 1);
                if ((info != NULL) && info->continuation) {
                    wrap = YES;
                }
            }
            //if (mode == debg) { NSLog(@"OUTP DATA [%@] [%d] [%d][%d] [%d][%d][%d][%d] [%d][%@] [%@]-[%@]", pref, mode, self.crow.intValue, self.ccol.intValue, lira, lirb, lirw, lirz, r, wrap ? @"WRAP" : @"NOOP", cstr, line); }
            if (wrap && ([cstr length] < (maxc - 1))) {
                NSLog(@"WRAP NOOP [%@][%d] [%d]", pref, mode, r);
                wrap = NO;
            }
            if (([cstr length] == 1) && ([cstr UTF8String][0] == ' ')) {
                NSLog(@"WRAP NULL [%@][%d] [%d]", pref, mode, r);
                if (mode == 0) {
                    [cstr setString:@""];
                    [atrs removeAllObjects];
                }
            }
            if ((r == 0) && ([cstr length] == 0)) {
                NSLog(@"LINE NILL");
                continue;
            }
            if ((r < (self.crow.intValue + 1)) || (lirw != 0)) {
                if (lirw == 0) { lira = r; lirb = r; }
                else { lirb = r; }
                if (!wrap) { lirw = 0; }
                else { lirw = 1; }
            }
            //if (mode == debg) { NSLog(@"OUTP LOOP [%@] [%d] [%d][%d] [%d][%d][%d][%d] [%d][%@] [%@]-[%@]", pref, mode, self.crow.intValue, self.ccol.intValue, lira, lirb, lirw, lirz, r, wrap ? @"WRAP" : @"NOOP", cstr, line); }
            if (mode == 2) {
                NSMutableAttributedString *atrl = [self atrl:cstr atrs:atrs];
                [list addObject:atrl];
                [cstr setString:@""];
                [atrs removeAllObjects];
            } else {
                if (mode == 0) {
                    [cstr replaceOccurrencesOfString:@" " withString:@"\u00A0" options:0 range:NSMakeRange(0, cstr.length)];
                }
                [line appendString:[cstr copy]];
                [latr addObjectsFromArray:atrs];
                [cstr setString:@""];
                [atrs removeAllObjects];
                if (r == lira) {
                    lirz = (((int)[list count]) + 1);
                }
                if (!wrap) {
                    NSMutableAttributedString *atrl = [self atrl:line atrs:latr];
                    [list addObject:atrl];
                    [line setString:@""];
                    [latr removeAllObjects];
                }
            }
        }
        if ([line length] > 0) {
            NSMutableAttributedString *atrl = [self atrl:line atrs:latr];
            [list addObject:atrl];
        }

        //if (mode == debg) { NSLog(@"OUTP LIST [%@] [%d] [%d][%d] [%d][%d][%d][%d] [%@]", pref, mode, self.crow.intValue, self.ccol.intValue, lira, lirb, lirw, lirz, list); }

        if ((mode == 0) || (mode == 1)) {
            while ([list count] > lirz) {
                [list removeLastObject];
            }
        }

        //if (mode == debg) { NSLog(@"OUTP PREP [%@] [%d] [%d][%d] [%d][%d][%d] [%@]", pref, mode, self.crow.intValue, self.ccol.intValue, lira, lirb, lirw, list); }

        if (mode == 1) {
            int rmax = ((2 * self.rows.intValue) / 3);
            int rmin = (rmax / 3);
            if (self.crow.intValue < 1) {
                [list removeAllObjects];
            }
            if ((nows - self.loco.unsignedLongLongValue) < LOCT) {
                NSLog(@"OUTP LOCK [%@][%d] [%d][%d] [%d][%d] [%llu]", pref, mode, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue, self.loco.unsignedLongLongValue);
                [list removeAllObjects];
            }
            if (self.crow.intValue >= self.orow.intValue) {
                self.orow = @(self.crow.intValue);
                self.ocol = @(self.ocol.intValue);
            }
            if (self.ccol.intValue >= self.ocol.intValue) {
                self.ocol = @(self.ccol.intValue);
            }
            if ([list count] > 0) {
                [list removeLastObject];
            }
            if ([list count] > rmax) {
                for (int x = 0; x < rmin; ++x) {
                    [list removeObjectAtIndex:0];
                }
            }
        }

        if (mode == 0) {
            int begr = MAX(0, (self.rows.intValue - 1) - (lirb - lira));
            int crsr = MAX(0, (self.crow.intValue - lira) + begr);
            int crsc = MAX(0, self.ccol.intValue);
            rets = ([list count] > 0) ? [list lastObject] : rets;
            self.irow = @(crsr);
            self.icol = @(crsc);
        } else {
            for (NSInteger i = 0; i < [list count]; ++i) {
                id item = [list objectAtIndex:i];
                if ([item isKindOfClass:[NSAttributedString class]]) {
                    [rets appendAttributedString:(NSAttributedString *)item];
                }
                if (i < [list count] - 1) {
                    NSAttributedString *news = [[NSAttributedString alloc] initWithString:@"\n" attributes:@{}];
                    [rets appendAttributedString:news];
                }
            }
        }

        //if (mode == debg) { NSLog(@"OUTP POST [%@] [%d] [%d][%d] [%d][%d][%d][%d] [%@]", pref, mode, self.crow.intValue, self.ccol.intValue, lira, lirb, lirw, lirz, list); }
    }

    return rets;
}

- (void)ginp {
    int newl = 0;
    NSPasteboard *pbrd = [NSPasteboard generalPasteboard];
    if ([pbrd canReadItemWithDataConformingToTypes:@[NSPasteboardTypeString]]) {
        NSString *text = [pbrd stringForType:NSPasteboardTypeString];
        if ((text != nil) && ([text length] > 0)) {
            NSUInteger leng = [text length];
            for (NSUInteger i = 0; i < leng; ++i) {
                unichar letr = [text characterAtIndex:i];
                if ((letr == '\r') || (letr == '\n')) {
                    ++newl;
                } else if (letr == '\t') {
                    [self inpt:nil letr:' '];
                    [self inpt:nil letr:' '];
                } else if ((31 < letr) && (letr < 127)) {
                    if (newl > 0) {
                        [self inpt:nil letr:';'];
                        [self inpt:nil letr:' '];
                        newl = 0;
                    }
                    [self inpt:nil letr:letr];
                }
            }
        }
    }
}

- (int)outp:(NSTimer *)objc {
    ssize_t maxl = 9753;
    ssize_t leng, plen, llen;
    unsigned char *buff = malloc(maxl);
    char *ptra, *ptrb;

    while (1) {
        if ([self chkf] != 0) { return 1; }
        if (self.vcon == nil) { usleep(357000); continue; }
        if (self.term == nil) { usleep(357000); continue; }

        int fdes = self.mfdn.intValue;
        fd_set rfds;
        struct timeval timo;

        FD_ZERO(&rfds);
        FD_SET(fdes, &rfds);
        timo.tv_sec = 0;
        timo.tv_usec = 95000;
        select(fdes + 1, &rfds, NULL, NULL, &timo);
        if ([self chkf] != 0) { return 2; }

        if (FD_ISSET(fdes, &rfds)) {
            bzero(buff, maxl);
            leng = read(fdes, buff, maxl - 9);

            if (leng < 1) {
                NSLog(@"OUTP STOP [%d][%d]", self.indx.intValue, self.vidx.intValue);
                [self halt:@"outp"];
                return 3;
            }

            if (strchr((char *)buff, '\n') != NULL) {
                [self jobs:@"line" mode:2];
            }
            __block int mode = 0;
            @synchronized (self) {
                mode = self.mode.intValue;
            }

            if (mode > 1) {
                @synchronized (self) {
                    vterm_input_write(self.term, (const char *)buff, leng);
                };
            } else {
                ptra = (char *)buff; llen = 0;
                while (llen < leng) {
                    ptrb = strchr(ptra, '\n');
                    if (ptrb != NULL) {
                        ptrb = (ptrb + 1); plen = (ptrb - ptra);
                    } else {
                        ptra = (ptra + 0); plen = (leng - llen);
                    }
                    @synchronized (self) {
                        vterm_input_write(self.term, ptra, plen);
                        [self comp:@"loop" mode:1];
                    };
                    llen += plen; ptra = ptrb;
                }
                @synchronized (self) {
                    [self comp:@"outp" mode:2];
                };
            }

            for (int x = 0; x < leng; ++x) {
                //NSLog(@"OUTP [%d] [%d][%c]", x, buff[x], buff[x]);
                if (buff[x] == 27) {
                    self.ansi = @(1);
                    self.ansd = @(0);
                    [self.info setLength:0];
                    //NSLog(@"ANSI INIT [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                } else if (self.ansd.intValue == 3) {
                    //NSLog(@"ANSI DATA [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                    if ((31 < buff[x]) && (buff[x] < 127)) {
                        [self.info appendBytes:(const char *)&(buff[x]) length:1];
                    } else {
                        if ([self.info length] > 1) {
                            NSString *strs = [[NSString alloc] initWithData:self.info encoding:NSUTF8StringEncoding];
                            if (self.vcon != nil) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if ([strs hasPrefix:@"0;"]) {
                                        NSString *vals = [strs substringFromIndex:2];
                                        [self.vcon wint:vals];
                                    }
                                    if ([strs hasPrefix:@"1;"]) {
                                        NSString *vals = [strs substringFromIndex:2];
                                        [self.tcon tabt:vals indx:self.vidx.intValue];
                                    }
                                    if ([strs hasPrefix:@"99;"]) {
                                        NSString *vals = [strs substringFromIndex:3];
                                        if ([vals isEqualToString:@"CMDB"]) {
                                            NSLog(@"JOBS CMDB [%d]", self.vidx.intValue);
                                        }
                                        if ([vals isEqualToString:@"CMDE"]) {
                                            NSLog(@"JOBS CMDE [%d]", self.vidx.intValue);
                                            [self jobs:@"cmde" mode:1];
                                        }
                                    }
                                });
                            }
                        }
                        self.ansd = @(9);
                        //NSLog(@"ANSI STOP [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                    }
                } else if (self.ansi.intValue == 3) {
                    if (('0' <= buff[x]) && (buff[x] <= '9')) {
                        /* ![?01234h */
                    } else {
                        self.ansi = @(9);
                    }
                    [self.info appendBytes:(const char *)&(buff[x]) length:1];
                    //NSLog(@"ANSI PROC [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                } else if (self.ansd.intValue == 2) {
                    if (buff[x] == ';') {
                        self.ansd = @(3);
                        [self.info appendBytes:(const char *)&(buff[x]) length:1];
                    } else if (('0' <= buff[x]) && (buff[x] <= '9')) {
                        /* !]0;... */
                        [self.info appendBytes:(const char *)&(buff[x]) length:1];
                    } else {
                        NSLog(@"ANSI ERRO [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                        self.ansd = @(0);
                        self.ansi = @(9);
                    }
                    //NSLog(@"ANSI PROC [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                } else if (self.ansi.intValue == 2) {
                    if (('?' <= buff[x]) && (buff[x] <= '~')) {
                        if (buff[x] == '?') {
                            self.ansi = @(3);
                        } else {
                            //NSLog(@"ANSI ENDS [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                            self.ansi = @(9);
                        }
                    }
                } else if (self.ansi.intValue == 1) {
                    if (buff[x] == ']') {
                        self.ansd = @(2);
                    }
                    self.ansi = @(2);
                    //NSLog(@"ANSI PREP [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                } else if (buff[x] == 7) {
                    //NSLog(@"ANSI BELL [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                    self.ansd = @(9);
                    self.ansi = @(9);
                }

                if (self.ansd.intValue >= 9) {
                    self.ansd = @(0);
                    self.ansi = @(0);
                }

                if (self.ansi.intValue >= 9) {
                    if ([self.info length] > 0) {
                        //NSLog(@"ANSI COMD [%@]", self.info);
                    }
                    self.ansi = @(0);
                }
            }
        }
    }
    return 0;
}

- (int)find:(int)letr objc:(NSEvent *)objc {
    if (self.vcon.srcs.intValue != 0) {
        if (objc != nil) {
            NSTextField *text = self.vcon.srct;
            if (text != nil) {
                NSWindow *wind = text.window;
                if ((wind != nil) && (wind.firstResponder != [text currentEditor])) {
                    [wind makeFirstResponder:text];
                }
                NSText *edit = [text currentEditor];
                if (edit != nil) {
                    NSRange rang = NSMakeRange(text.stringValue.length, 0);
                    [edit setSelectedRange:rang];
                    [edit interpretKeyEvents:@[objc]];
                }
            }
            return 1;
        }
    }
    return 0;
}

- (int)inpt:(NSEvent *)objc letr:(char)letr {
    if ([self chkf] != 0) { return 1; }
    if (self.vcon == nil) { return 2; }

    int wini = 0, winp = 6;
    int imax = (5 * (self.cols.intValue - 3));
    int vidx = self.vidx.intValue;
    int iidx = self.indx.intValue;
    char byte;
    int codc = 0;
    NSString *chrs = @"";
    NSEventModifierFlags flag = 0;

    if ([self find:0 objc:objc] != 0) {
        return 1;
    }

    if (objc != nil) {
        if ([objc.characters length] > 0) {
            codc = objc.keyCode;
            chrs = objc.characters;
            flag = [objc modifierFlags];
        }
    }
    if (letr > 0) {
        chrs = [NSString stringWithFormat:@"%c", letr];
    }

    if ([chrs length] > 0) {
        int code = [chrs characterAtIndex:0];

        VTermModifier mods = VTERM_MOD_NONE;
        if (flag & NSEventModifierFlagShift)   mods |= VTERM_MOD_SHIFT;
        if (flag & NSEventModifierFlagControl) mods |= VTERM_MOD_CTRL;
        if (flag & NSEventModifierFlagOption)  mods |= VTERM_MOD_ALT;

        NSLog(@"INPT [%@][%ld] [%d] [%d][%d] <%d>{%d}", chrs, [chrs length], codc, vidx, iidx, mods, code);

        VTermKey keyc = VTERM_KEY_NONE;
        switch (codc) {
            case 126: keyc = VTERM_KEY_UP;    break;
            case 125: keyc = VTERM_KEY_DOWN;  break;
            case 124: keyc = VTERM_KEY_RIGHT; break;
            case 123: keyc = VTERM_KEY_LEFT;  break;
        }

        size_t leng = [chrs length];
        if (code == 27) {
            [self refw:@"inpt" prio:winp keep:0 glob:0 titi:@"esc!"]; wini = 1;
            if (self.vcon.srcs.intValue != 0) {
                [self.vcon find];
            } else {
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            }
            self.ansi = @(0);
        } else if (code == 9) {
            [self refw:@"inpt" prio:winp keep:0 glob:0 titi:@"tab!"]; wini = 1;
            byte = code;
            write(self.mfdn.intValue, &byte, 1);
            self.ansi = @(0);
        } else if (flag & NSEventModifierFlagCommand) {
            NSLog(@"COMD [%d]", code);
            int zidx = (self.vcon.indx.intValue - 1);
            if ((zidx > -1) && (self.vcon.tabs.count > 1)) {
                if (keyc == VTERM_KEY_RIGHT) {
                    [self.vcon next:zidx dirs:0];
                }
                if (keyc == VTERM_KEY_LEFT) {
                    [self.vcon next:zidx dirs:1];
                }
            }
            if (keyc == VTERM_KEY_UP) {
                [self.vcon scro:0];
            }
            if (keyc == VTERM_KEY_DOWN) {
                [self.vcon scro:1];
            }
            if (code == 'f') {
                [self.vcon find];
            } else if (code == 'c') {
                [self refw:@"inpt" prio:winp keep:0 glob:1 titi:@"noop"]; wini = 1;
            } else if (code == 'v') {
                [self refw:@"inpt" prio:winp keep:0 glob:1 titi:@"pste"]; wini = 1;
                [self ginp];
            } else if (code == 't') {
                [self refw:@"inpt" prio:winp keep:0 glob:1 titi:@"tab+"]; wini = 1;
                [self.vcon taba:nil];
            } else if (code == 'd') {
                [self refw:@"inpt" prio:winp keep:0 glob:1 titi:@"tab-"]; wini = 1;
                [self halt:@"comd"];
            } else if (code == 'a') {
                if (self.hist.count > 0) {
                    [self refw:@"inpt" prio:winp keep:0 glob:1 titi:@"copy"]; wini = 1;
                    NSString *join = [[self.hist componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
                    NSPasteboard *pbrd = [NSPasteboard generalPasteboard];
                    [pbrd clearContents];
                    [pbrd writeObjects:@[join]];
                    NSLog(@"COPY INPT [%ld]", [join length]);
                }
            } else if (code == 'q') {
                [self refw:@"inpt" prio:winp keep:0 glob:1 titi:@"quit"]; wini = 1;
                [NSApp terminate:nil];
                self.quit = @(self.quit.intValue + 1);
                if (self.quit.intValue >= 3) { exit(0); }
            } else if (code == 'n') {
                [self refw:@"inpt" prio:winp keep:0 glob:1 titi:@"win+"]; wini = 1;
                id appd = [NSApp delegate];
                [appd performSelectorOnMainThread:@selector(makeNewWindow:) withObject:self waitUntilDone:NO];
            } else if (code == 'w') {
                [self refw:@"inpt" prio:winp keep:0 glob:1 titi:@"win-"]; wini = 1;
                self.qwin = @(self.qwin.intValue + 1);
                if (self.qwin.intValue >= 3) {
                    id appd = [NSApp delegate];
                    [appd performSelectorOnMainThread:@selector(stopAllTabs:) withObject:self waitUntilDone:NO];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.wino != nil) {
                        [self.wino performClose:nil];
                    }
                });
            } else if (code == 'k') {
                if (self.mode.intValue == 0) {
                    [self refw:@"inpt" prio:winp keep:0 glob:1 titi:@"clrs"]; wini = 1;
                    @synchronized (self) {
                        [self clrs:@"cmdk" hist:1 scrn:1 ctrl:1];
                        [self refv:@"cmdk" sels:9 indx:self.vidx.intValue cidx:-1 datf:0];
                    };
                }
            }
        } else if (flag & NSEventModifierFlagControl) {
            NSLog(@"CTRL [%d]", code);
            if (code == 3) {
                //kill(self.pidn.intValue, SIGINT);
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
                self.ansi = @(0);
            } else if (code == 4) {
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            } else if (code == 18) {
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            } else if (code == 24) {
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            } else if (code == 26) {
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            } else if (keyc == VTERM_KEY_LEFT) {
                byte = 27;
                write(self.mfdn.intValue, &byte, 1);
                byte = 98;
                write(self.mfdn.intValue, &byte, 1);
            } else if (keyc == VTERM_KEY_RIGHT) {
                byte = 27;
                write(self.mfdn.intValue, &byte, 1);
                byte = 102;
                write(self.mfdn.intValue, &byte, 1);
            } else {
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            }
        } else if (keyc != VTERM_KEY_NONE) {
            NSLog(@"TERM KEYC [%d]", keyc);
            @synchronized (self) {
                vterm_keyboard_key(self.term, keyc, mods);
            };
        } else {
            if (mods & VTERM_MOD_SHIFT) {
                if (code == ' ') {
                    NSLog(@"DROP BELL");
                    mods = 0;
                }
            }
            for (int i = 0; i < leng; ++i) {
                byte = [chrs characterAtIndex:i];
                self.leni = @(self.leni.intValue + 1);
                if ((byte == 8) || (byte == 127)) {
                    [self refw:@"inpt" prio:winp keep:0 glob:0 titi:@"back"]; wini = 1;
                } else if (self.leni.intValue > imax) {
                    [self refw:@"inpt" prio:4 keep:0 glob:0 titi:@"drop"];
                    continue;
                }
                @synchronized (self) {
                    vterm_keyboard_unichar(self.term, byte, mods);
                };
            }
            self.quit = @(0); self.qwin = @(0);
        }
        if (code == 13) {
            @synchronized (self) {
                [self clrs:@"line" hist:0 scrn:0 ctrl:0];
                self.leni = @(0); self.ljob = @(0);
            };
        }

        @synchronized (self) {
            leng = vterm_output_get_buffer_remaining(self.term);
            if (leng > 0) {
                char *data = malloc(leng);
                if (data != NULL) {
                    size_t rlen = vterm_output_read(self.term, data, leng);
                    write(self.mfdn.intValue, data, rlen);
                    free(data);
                }
            }
        };

        if (wini == 0) {
            [self refw:@"inpt" prio:7 keep:0 glob:0 titi:@"inpt"];
        }

        [self jobs:@"inpt" mode:1];
    } else {
        [self jobs:@"inpt" mode:0];
    }

    if (self.vcon.srcs.intValue != 0) {
        [self refw:@"inpt" prio:3 keep:1 glob:1 titi:@"find"];
    } else {
        [self refw:@"inpt" prio:3 keep:0 glob:1 titi:@""];
    }

    int cidx = ((self.irow.intValue << 16) | (self.ccol.intValue + 0));
    __block NSAttributedString *disp = [[NSAttributedString alloc] init];
    @synchronized (self) {
        if ((self.ljob.intValue == 0) && (self.mode.intValue == 0)) {
            disp = [self gout:@"inpt" mode:0];
        }
    };
    self.leni = @([disp.string length]);
    if (self.leni.intValue < 1) {
        cidx = 0;
    } else if (self.leni.intValue > imax) {
        [self refw:@"inpt" prio:4 keep:0 glob:0 titi:@"leng"];
        disp = [disp attributedSubstringFromRange:NSMakeRange(0, imax)];
    }
    self.leni = @([disp.string length]);
    //NSLog(@"INPS [%d] [%d][%d] [%d][%d] [%d][%d] [%@] [%ld] [%@]", self.vidx.intValue, self.irow.intValue, self.icol.intValue, self.crow.intValue, self.ccol.intValue, self.rows.intValue, self.cols.intValue, self.ljob.intValue != 0 ? @"YES" : @"NO", [disp length], disp);
    int rowc = self.rows.intValue;
    int colc = self.cols.intValue;
    NSString *pref = [self.prom copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vcon show:@"inpt" data:disp pref:pref indx:vidx sels:0 cidx:cidx rows:rowc cols:colc];
    });

    return 0;
}

- (void)winz:(NSString *)text wide:(CGFloat)wide high:(CGFloat)high {
    int indx = self.indx.intValue;
    int fdes = self.mfdn.intValue;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat pixw = MAX( 5.0, self.tcon.fntw.floatValue);
        CGFloat pixh = MAX(13.0, self.tcon.fnth.floatValue);
        CGFloat neww = (wide - SBWA);
        CGFloat newh = (high - SBHA);
        if ((self.tcon.srcs.intValue != 0) || (self.tcon.stts.intValue != 0)) {
            newh = (newh - SBHB);
        }
        int rows = ((int)(newh / pixh));
        int cols = ((int)(neww / pixw));
        struct winsize wsiz;
        wsiz.ws_row = rows;
        wsiz.ws_col = cols;
        wsiz.ws_xpixel = 0;
        wsiz.ws_ypixel = 0;
        ioctl(fdes, TIOCSWINSZ, &wsiz);
        self.rows = @(rows);
        self.cols = @(cols);
        NSLog(@"WINZ [%@] [%d] [%f][%f] [%d][%d] [%f][%f]", text, indx, wide, high, cols, rows, pixw, pixh);
        @synchronized (self) {
            if (self.term == nil) {
                self.term = vterm_new(rows, cols);
                vterm_set_utf8(self.term, 1);
                self.vtsc = vterm_obtain_screen(self.term);
                vterm_screen_reset(self.vtsc, 1);
                static VTermScreenCallbacks cb = {
                    .damage      = screen_damage,
                    .movecursor  = screen_movecursor,
                    .settermprop = screen_settermprop,
                };
                vterm_screen_set_callbacks(self.vtsc, &cb, (__bridge void *)(self));
                vterm_screen_enable_altscreen(self.vtsc, 1);
            }
            vterm_set_size(self.term, rows, cols);
        };
        self.vcon = self.tcon;
        [self.vcon refs:0];
        [self refw:@"winz" prio:1 keep:0 glob:1 titi:@"size"];
    });
}

- (int)opty {
    int mfdn, sfdn;
    char name[128];
    char *args[] = {"/bin/bash", "-i", "-l", NULL};
    char *cmds[] = {"stty raw isig echo \n", NULL};
    char *envs[] = {"EXEC", "TERM", "PS0", "PROMPT_COMMAND"};
    pid_t pidn;
    struct termios ttys;
    if (openpty(&mfdn, &sfdn, name, NULL, NULL) < 0) {
        NSLog(@"ERRO opty");
        return 0;
    }
    pidn = fork();
    self.mfdn = @(mfdn);
    self.sfdn = @(sfdn);
    self.pidn = @(pidn);
    if (pidn == 0) {
        close(mfdn);
        setsid();
        ioctl(sfdn, TIOCSCTTY, 1);
        dup2(sfdn, STDIN_FILENO);
        dup2(sfdn, STDOUT_FILENO);
        dup2(sfdn, STDERR_FILENO);
        close(sfdn);
        setenv(envs[0], "ss", 1);
        setenv(envs[1], "xterm-256color", 1);
        setenv(envs[2], "\033]99;CMDB\007", 1);
        setenv(envs[3], "printf \"\\033]99;CMDE\\007\"", 1);
        execv(args[0], args);
        _exit(1);
    } else {
        //close(sfdn);
        //self.sfdn = @(-1);
        tcgetattr(mfdn, &ttys);
        ttys.c_iflag &= ~(IGNBRK | IGNCR | IGNPAR | INLCR | INPCK | ISTRIP | PARMRK | IXOFF);
        ttys.c_iflag |=  (BRKINT | ICRNL | IXON | IUTF8);
        ttys.c_lflag &= ~(ECHO);
        ttys.c_lflag |=  (ECHO | ICANON | IEXTEN | ISIG);
        ttys.c_oflag &= ~(OPOST);
        ttys.c_oflag |=  (OPOST);
        ttys.c_cflag &= ~(CSIZE | PARENB);
        ttys.c_cflag |=  (CS8);
        tcsetattr(mfdn, TCSANOW, &ttys);
        for (int x = 0; x < 9; ++x) {
            if (cmds[x] == NULL) { break; }
        }
        //close(mfdn);
        //self.mfdn = @(-1);
    }
    return 1;
}

- (void)initProc:(ViewController *)vcon widx:(int)widx indx:(int)indx wide:(CGFloat)wide high:(CGFloat)high wino:(NSWindow *)wino {
    self.quit = @0;
    self.qwin = @0;

    self.stop = 00;
    self.vidx = @-1;
    self.widx = @(widx);
    self.indx = @(indx);
    self.trys = @0;

    self.pidn = @0;
    self.mfdn = @0;
    self.sfdn = @0;
    self.rows = @0;
    self.cols = @0;

    self.mode = @0;
    self.ansi = @0;
    self.ansd = @0;
    self.scre = @0;
    self.leni = @0;
    self.ljob = @0;
    self.loco = @0;

    self.crow = @0;
    self.ccol = @0;
    self.irow = @0;
    self.icol = @0;
    self.orow = @0;
    self.ocol = @0;

    self.prom = @"";

    self.info = [[NSMutableData alloc] init];
    self.part = [[NSMutableAttributedString alloc] init];
    self.hist = [NSMutableArray array];

    self.wino = wino;
    self.tcon = vcon;
    self.vcon = nil;

    self.term = nil;
    self.vtsc = nil;

    [self opty];

    self.vidx = @([self.tcon newt:@"init" wide:wide high:high]);
    [self winz:@"init" wide:wide high:high];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self outp:nil];
    });

    [self magicPrompt:@"/bin/bash" argsList:@[@"-c", @"~/bin/shell.sh $(date '+%s')"] intervalTime:3];
    [self statLoop:7];

    [self refw:@"init" prio:9 keep:1 glob:1 titi:@"line"];

    NSLog(@"PROC [%d][%d] [%d] [%d][%d] [%f][%f]", indx, self.vidx.intValue, self.pidn.intValue, self.mfdn.intValue, self.sfdn.intValue, wide, high);
}

- (instancetype)init {
    self = [super init];
    return self;
}

@end
