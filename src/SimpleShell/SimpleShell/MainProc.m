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

@interface MainProc ()
- (void)comp:(NSString *)pref mode:(int)mode;
- (unsigned long long)getl;
- (NSAttributedString *)gout:(NSString *)pref mode:(int)mode;
@end

static int screen_movecursor(VTermPos pos, VTermPos oldpos, int visible, void *user) {
    MainProc *self = (__bridge MainProc *)(user);
    int prow = pos.row;
    int pcol = pos.col;
    int targetVidx = self.vidx.intValue;
    int targetRows = self.rows.intValue;
    int targetCols = self.cols.intValue;
    __block int activeMode = 0;
    __block int targetCidx = 0;
    __block NSAttributedString *outpData = nil;
    @synchronized (self) {
        self.crow = @(pos.row);
        self.ccol = @(pos.col);
        activeMode = self.mode.intValue;
        targetCidx = ((pos.row << 16) | (pos.col & 0xffff));
        if (activeMode == 2) {
            outpData = [self gout:@"curs" mode:2];
        }
        NSLog(@"CURS [%d][%d] [%d][%d] [%d][%d] (Mode: %d)", prow, pcol, pos.row, pos.col, targetRows, targetCols, activeMode);
        if (activeMode != 2) {
            if (prow < self.orow.intValue) {
                NSLog(@"CURS LOCK [%d] [%d][%d] [%d][%d]", -1, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue);
                self.loco = @([self getl]);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.vcon != nil) {
                if (activeMode == 2) {
                    [self.vcon show:@"movs" data:outpData pref:nil indx:targetVidx sels:2 cidx:targetCidx rows:targetRows cols:targetCols];
                }
                [self inpt:nil indx:targetVidx letr:0];
            }
        });
    };
    return 1;
}

static int screen_damage(VTermRect rect, void *user) {
    MainProc *self = (__bridge MainProc *)(user);
    static CFAbsoluteTime last = 0;
    /*if (self.mode.intValue != 2) {
        [self comp:@"disp" mode:0];
    }*/
    CFAbsoluteTime nows = CFAbsoluteTimeGetCurrent();
    if ((nows - last) <= 0.015) {
        NSLog(@"DLAY");
        return 1;
    }
    last = nows;
    if ((rect.start_col == 0) && (rect.start_row == self.crow.intValue)) {
        NSLog(@"CURK [%d][%d]", self.crow.intValue, self.ccol.intValue);
        /* ![K */
    }
    int targetVidx = self.vidx.intValue;
    int targetRows = self.rows.intValue;
    int targetCols = self.cols.intValue;
    __block int activeMode = 0;
    __block int targetCidx = 0;
    __block NSAttributedString *outpData = nil;
    @synchronized (self) {
        activeMode = self.mode.intValue;
        targetCidx = ((targetRows << 16) | (targetCols & 0xffff));
        if (activeMode == 2) {
            outpData = [self gout:@"disp" mode:2];
        }
        //NSLog(@"DATA [%d][%d] (Mode: %d)", targetRows, targetCols, activeMode);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.vcon != nil) {
                if (activeMode == 2) {
                    [self.vcon show:@"disp" data:outpData pref:nil indx:targetVidx sels:2 cidx:targetCidx rows:targetRows cols:targetCols];
                }
                [self inpt:nil indx:targetVidx letr:0];
            }
        });
    };
    return 1;
}

static int screen_settermprop(VTermProp prop, VTermValue *val, void *user) {
    MainProc *self = (__bridge MainProc *)(user);
    if (prop == VTERM_PROP_ALTSCREEN) {
        __block int activeMode = 0;
        @synchronized (self) {
            activeMode = self.mode.intValue;
            dispatch_async(dispatch_get_main_queue(), ^{
                int gridMode = val->boolean;
                if (gridMode) {
                    NSLog(@"ANSI MODE");
                    self.mode = @(2);
                    if (self.vcon != nil && self.vcon.inpt.count > 0) {
                        int currentIdx = (self.vcon.indx.intValue - 1);
                        if (currentIdx >= 0 && currentIdx < [self.vcon.inpt count]) {
                            NSTextView *activeInputView = [self.vcon.inpt objectAtIndex:currentIdx];
                            NSWindow *targetWindow = activeInputView.window;
                            if (targetWindow != nil) {
                                [targetWindow makeKeyWindow];
                                [targetWindow makeFirstResponder:activeInputView];
                                [activeInputView setNeedsDisplay:YES];
                            }
                        }
                    }
                } else {
                    NSLog(@"LINE MODE");
                    self.mode = @(0);
                    self.irow = @(0); self.icol = @(0);
                    self.orow = @(0); self.ocol = @(0);
                    if (self.vcon != nil) {
                        [self.vcon show:@"prop" data:nil pref:nil indx:self.vidx.intValue sels:3 cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];
                        [self inpt:nil indx:self.vidx.intValue letr:0];
                    }
                }
            });
        };
    }
    if ((prop == VTERM_PROP_TITLE) || (prop == VTERM_PROP_ICONNAME)) {
        const char *cTitle = val->string.str;
        if (cTitle != NULL) {
            NSString *newTitle = [NSString stringWithUTF8String:cTitle];
            NSLog(@"TITL [%@] [%@]", newTitle, self);
            /*dispatch_async(dispatch_get_main_queue(), ^{
                if (prop == VTERM_PROP_TITLE) {
                    if (self.wino != nil) {
                        [self.wino setTitle:newTitle];
                    }
                }
                if (prop == VTERM_PROP_ICONNAME) {
                    if (self.tcon != nil) {
                        [self.tcon tabt:newTitle indx:self.vidx.intValue];
                    }
                }
            });*/
        }
    }
    return 1;
}

@implementation MainProc

- (unsigned long long)getl {
    NSDate *date = [NSDate date];
    unsigned long long mill = (long long)([date timeIntervalSince1970] * 1000.0);
    return mill;
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
                @synchronized (data) {
                    [data appendData:part];
                }
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

        NSData *outp = nil;
        @synchronized (data) {
            outp = [data copy];
        }

        if (outp.length > 0) {
            NSString *strw = [[NSString alloc] initWithData:outp encoding:NSUTF8StringEncoding];
            NSString *strc = [strw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            NSArray<NSString *> *news = [strc componentsSeparatedByString:@"\n"];
            if (news.count > 2) {
                NSString *cpus = [news[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *rams = [news[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *nets = [news[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (strongSelf.vcon != nil) {
                        if ((strongSelf.vidx != nil) && (strongSelf.vcon.indx != nil)) {
                            if (strongSelf.vidx.intValue != strongSelf.vcon.indx.intValue) {
                                return;
                            }
                        }
                        if ([strongSelf.vcon respondsToSelector:@selector(cpuv)]) {
                            strongSelf.vcon.cpuv.stringValue = cpus;
                            strongSelf.vcon.ramv.stringValue = rams;
                            strongSelf.vcon.netv.stringValue = nets;
                        }
                    }
                });
            }
        }
    });

    dispatch_resume(self.loos);
}

- (void)magicPrompt:(NSString *)comd argsList:(NSArray<NSString *> *)args intervalTime:(uint64_t)secs {
    dispatch_queue_t queue = dispatch_queue_create("com.simpleshell.timecomd", DISPATCH_QUEUE_SERIAL);
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
                @synchronized (data) {
                    [data appendData:part];
                }
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

        NSData *outp = nil;
        @synchronized (data) {
            outp = [data copy];
        }

        if (outp.length > 0) {
            NSString *stro = [[NSString alloc] initWithData:outp encoding:NSUTF8StringEncoding];
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.pref = stro;
                [strongSelf inpt:nil indx:strongSelf.vidx.intValue letr:0];
            });
        }
    });

    dispatch_resume(self.loot);
}

- (void)sign:(int)pidn {
    kill(pidn, SIGHUP);
    usleep(135000);
    kill(pidn, SIGTERM);
    usleep(135000);
    kill(pidn, SIGKILL);
}

- (int)chkf {
    if (self.stop.intValue > 0) { return 1; }
    if (self.pidn.intValue < 1) { return 2; }
    if (self.mfdn.intValue < 1) { return 3; }
    if (self.sfdn.intValue < 1) { return 4; }
    return 0;
}

- (void)stop:(NSString *)pref {
    if (self.pidn.intValue > 0) {
        NSLog(@"KILL [%@] [%d][%d] [%d] {%d}", pref, self.widx.intValue, self.indx.intValue, self.pidn.intValue, self.stop.intValue);
        [self sign:self.pidn.intValue];
        self.pidn = @(-1);
    }
    if (self.mfdn.intValue > 0) {
        NSLog(@"MFDN [%@] [%d][%d] [%d] {%d}", pref, self.widx.intValue, self.indx.intValue, self.pidn.intValue, self.stop.intValue);
        close(self.mfdn.intValue);
        self.mfdn = @(-1);
    }
    if (self.sfdn.intValue > 0) {
        NSLog(@"SFDN [%@] [%d][%d] [%d] {%d}", pref, self.widx.intValue, self.indx.intValue, self.pidn.intValue, self.stop.intValue);
        close(self.sfdn.intValue);
        self.sfdn = @(-1);
    }
    self.stop = @(9);
}

- (void)halt:(NSString *)pref {
    int tabn = 0;
    for (int x = 0; x < [self.vcon.tabs count]; ++x) {
        if ([self.vcon.remo containsObject:@(x)]) { continue; }
        ++tabn;
    }
    [self stop:pref];
    [self.vcon tabx:(self.vidx.intValue - 1)];
    if (tabn <= 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.wino != nil) {
                [self.wino performClose:nil];
            }
        });
    }
}

- (int)visi:(int)byte extr:(int)extr {
    if ((31 < byte) && (byte < 127)) {
        return 1;
    }
    if ((extr == 1) && (byte == 9)) {
        return 2;
    }
    return 0;
}

- (int)bite:(NSMutableData *)data indx:(int)indx item:(unsigned char)item repl:(int)repl leng:(int)leng {
    unsigned char spcr = ' ';
    while (indx >= [data length]) {
        [data appendBytes:&(spcr) length:1];
    }
    for (int z = 0; z < leng; ++z) {
        [data replaceBytesInRange:NSMakeRange(indx, repl) withBytes:&item length:1];
    }
    return indx + 1;
}

- (int)scan:(NSArray *)a comp:(NSArray *)b mode:(int)m {
    if (m == 0) { return 0; }
    int l = ((int)([a count]));
    if (([a count] < 1) || ([b count] < 1)) { return 0; }
    NSString *c = [b objectAtIndex:0];
    for (int x = (l - 1); x > -1; --x) {
        NSString *d = [a objectAtIndex:x];
        if ([d isEqualToString:c]) {
            return x;
        }
    }
    return 0;
}

- (void)comp:(NSString *)pref mode:(int)mode {
    NSMutableAttributedString *outs = [[NSMutableAttributedString alloc] init];
    NSAttributedString *outa = [self gout:pref mode:1];
    NSString *outp = [outa.string copy];
    NSArray *grid = [outp componentsSeparatedByString:@"\n"];
    @synchronized (self.part) {
        if (mode == 1) {
            [outs appendAttributedString:self.part];
            [self.part deleteCharactersInRange:NSMakeRange(0, [self.part length])];
        }
        if ([outp length] > 0) {
            NSUInteger dlen = [self.hist count], slen = [grid count], zlen = (self.rows.intValue * 3);
            NSUInteger bidx = (dlen > zlen) ? dlen - zlen : 0, eidx = MIN(dlen, zlen);
            NSArray *last = (eidx > 0) ? [self.hist subarrayWithRange:NSMakeRange(bidx, eidx)] : @[];
            int sidx = [self scan:last comp:grid mode:1];
            long indx = 0;
            for (int x = 0; x < slen; ++x) {
                NSString *line = [grid objectAtIndex:x];
                long leng = [line length];
                int y = (x + sidx);
                //if (![last containsObject:line]) {
                if ((y >= [last count]) || (![line isEqualToString:[last objectAtIndex:y]])) {
                    NSRange lrng = NSMakeRange(indx, leng);
                    NSAttributedString *atrs = [outa attributedSubstringFromRange:lrng];
                    NSAttributedString *news = [[NSAttributedString alloc] initWithString:@"\n" attributes:@{}];
                    if (mode == 0) {
                        [self.part appendAttributedString:news];
                        [self.part appendAttributedString:atrs];
                    } else {
                        [outs appendAttributedString:news];
                        [outs appendAttributedString:atrs];
                    }
                    if (y >= [last count]) { [self.hist addObject:[line copy]]; }
                    else { [self.hist replaceObjectAtIndex:(bidx + y) withObject:[line copy]]; }
                }
                indx += (leng + 1);
            }
        }
    };
    if ([outs length] > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.vcon != nil) {
                if (self.mode.intValue == 0) {
                    [self.vcon show:@"line" data:outs pref:nil indx:self.vidx.intValue sels:1 cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];
                }
            }
        });
    }
}

- (NSColor *)nsColorFromVTermColor:(VTermColor)vcolor {
    if (vcolor.type == VTERM_COLOR_DEFAULT_FG) { return nil; }
    VTermState *state = vterm_obtain_state(self.term);
    if (state == NULL) { return nil; }
    vterm_state_convert_color_to_rgb(state, &vcolor);
    if (VTERM_COLOR_IS_RGB(&vcolor)) {
        return [NSColor colorWithRed:(vcolor.rgb.red / 255.0) green:(vcolor.rgb.green / 255.0) blue:(vcolor.rgb.blue / 255.0) alpha:1.0];
    }
    return self.tcon.txtc ? self.tcon.txtc : [NSColor textColor];
}

- (NSMutableAttributedString *)atrl:(NSString *)line atrs:(NSMutableArray *)atrs {
    NSMutableAttributedString *atrl = [[NSMutableAttributedString alloc] initWithString:line attributes:@{}];
    for (int c = 0; c < [atrs count]; ++c) {
        NSRange chrr = NSMakeRange(c, 1);
        NSDictionary *props = atrs[c];
        [atrl addAttribute:NSForegroundColorAttributeName value:props[@"fg"] range:chrr];
        if (props[@"bg"]) {
            [atrl addAttribute:NSBackgroundColorAttributeName value:props[@"bg"] range:chrr];
        }
    }
    return atrl;
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
                if ((letr == '\n') || (letr == '\r')) {
                    ++newl;
                } else if (letr == '\t') {
                    [self inpt:nil indx:0 letr:' '];
                    [self inpt:nil indx:0 letr:' '];
                } else if ((31 < letr) && (letr < 127)) {
                    if (newl > 0) {
                        [self inpt:nil indx:0 letr:';'];
                        [self inpt:nil indx:0 letr:' '];
                        newl = 0;
                    }
                    [self inpt:nil indx:0 letr:letr];
                }
            }
        }
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
                    if (cell.chars[0] != 0) {
                        if ((31 < cell.chars[0]) && (cell.chars[0] < 127)) {
                            [cstr appendFormat:@"%C", (unsigned short)cell.chars[0]];
                        } else {
                            [cstr appendFormat:@" "];
                        }
                        [atrs addObject:@{ @"fg":(txtc != nil) ? txtc : self.vcon.txtc }];
                    } else if (mode == 2) {
                        [cstr appendFormat:@" "];
                        [atrs addObject:@{ @"fg":(txtc != nil) ? txtc : self.vcon.txtc }];
                    }
                }
            }
            BOOL wrap = NO;
            if (((r + 1) < maxr) && (stat != NULL)) {
                const VTermLineInfo *info = vterm_state_get_lineinfo(stat, r + 1);
                if ((info != NULL) && info->continuation) {
                    wrap = YES;
                }
            }
            //if (mode == debg) { NSLog(@"OUTP DATA [%@] [%d] [%d][%d] [%d][%d] [%d][%d][%d] [%@] [%@][%@]", pref, mode, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue, lira, lirb, lirw, wrap ? @"WRAP" : @"NOOP", line, cstr); }
            if (([cstr length] == 1) && ([cstr UTF8String][0] == ' ')) {
                NSLog(@"GOUT WRAP [%@][%d]", pref,  mode);
                if (mode == 0) {
                    [cstr setString:@""];
                    [atrs removeAllObjects];
                }
            }
            if ([cstr length] > 0) {
                if (lirw == 0) { lira = r; lirb = r; }
                else { lirb = r; }
                if (!wrap) { lirw = 0; }
                else { lirw = 1; }
            }
            //if (mode == debg) { NSLog(@"OUTP LOOP [%@] [%d] [%d][%d] [%d][%d] [%d][%d][%d] [%@] [%@][%@]", pref, mode, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue, lira, lirb, lirw, wrap ? @"WRAP" : @"NOOP", line, cstr); }
            if (mode == 2) {
                NSMutableAttributedString *atrl = [self atrl:cstr atrs:atrs];
                [list addObject:atrl];
                [cstr setString:@""];
                [atrs removeAllObjects];
            } else {
                [line appendString:[cstr copy]];
                [latr addObjectsFromArray:atrs];
                [cstr setString:@""];
                [atrs removeAllObjects];
                if (!wrap) {
                    NSMutableAttributedString *atrl = [self atrl:line atrs:latr];
                    [list addObject:atrl];
                    [line setString:@""];
                    [latr removeAllObjects];
                    if (r == self.crow.intValue) {
                        lirz = (((int)[list count]) - 1);
                    }
                }
            }
        }
        if ([line length] > 0) {
            NSMutableAttributedString *atrl = [self atrl:line atrs:latr];
            [list addObject:atrl];
            if ((maxr - 1) == self.crow.intValue) {
                lirz = (((int)[list count]) - 1);
            }
        }

        //if (mode == debg) { NSLog(@"OUTP LIST [%@][%d] [%d][%d] [%d][%d] [%d][%d][%d] [%@]", pref, mode, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue, lira, lirb, lirw, list); }

        if ((mode == 0) || (mode == 1)) {
            int crsr = MAX(0, lirz + 1);
            while ([list count] > crsr) {
                [list removeLastObject];
            }
        }

        //if (mode == debg) { NSLog(@"OUTP PREP [%@] [%d] [%d][%d] [%d][%d] [%d][%d][%d] [%@]", pref, mode, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue, lira, lirb, lirw, list); }

        if (mode == 1) {
            unsigned long long nows = [self getl];
            if ([list count] > 0) { [list removeLastObject]; }
            if (self.orow.intValue > (self.rows.intValue - 3)) {
                while ([list count] > (self.rows.intValue / 3)) {
                    [list removeObjectAtIndex:0];
                }
            }
            if (self.crow.intValue >= self.orow.intValue) {
                self.orow = @(self.crow.intValue);
            }
            if ((nows - self.loco.unsignedLongLongValue) < 357) {
                NSLog(@"OUTP LOCK [%@][%d] [%d][%d] [%d][%d]", pref, mode, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue);
                //[list removeAllObjects];
            }
        }

        if (mode == 0) {
            int begr = MAX(0, (self.rows.intValue - 1) - (lirb - lira));
            int crsr = MAX(0, (self.crow.intValue - lira) + begr);
            int crsc = MAX(0, self.ccol.intValue);
            rets = ([list count] > 0) ? [list lastObject] : rets;
            @synchronized (self) {
                self.irow = @(crsr);
                self.icol = @(crsc);
            };
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

        //if (mode == debg) { NSLog(@"OUTP POST [%@] [%d] [%d][%d] [%d][%d] [%d][%d][%d] [%@]", pref, mode, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue, lira, lirb, lirw, list); }
    }

    return rets;
}

- (int)outp:(NSTimer *)objc {
    ssize_t maxl = 9753;
    ssize_t leng, plen, llen;
    unsigned char *buff = malloc(maxl);
    char *ptra, *ptrb;

    while (1) {
        ssize_t maxr = (self.cols.intValue - 9);
        ssize_t maxa = (self.cols.intValue + 9);

        if (maxa > maxl) {
            NSLog(@"OUTP REAL [%ld][%ld]", maxl, maxa);
            buff = realloc(buff, maxa);
            maxl = maxa;
        }

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
        if ([self chkf] != 0) { return 3; }

        if (FD_ISSET(fdes, &rfds)) {
            bzero(buff, maxa);
            leng = read(fdes, buff, maxr);

            if (leng < 1) {
                NSLog(@"OUTP STOP [%d][%d]", self.indx.intValue, self.vidx.intValue);
                [self halt:@"outp"];
                return 2;
            }

            if (self.mode.intValue == 2) {
                if (leng > 0) {
                    @synchronized (self) {
                        vterm_input_write(self.term, (const char *)buff, leng);
                    };
                }
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
                    };
                    if (ptra != NULL) {
                        [self comp:@"outp" mode:1];
                    }
                    llen += plen; ptra = ptrb;
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
                                const unsigned char *byte = (const unsigned char *)[self.info bytes];
                                NSRange rngl = NSMakeRange(1, [self.info length] - 1);
                                NSData *subd = [self.info subdataWithRange:rngl];
                                NSString *strs = [[NSString alloc] initWithData:subd encoding:NSUTF8StringEncoding];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (byte[0] == '0') {
                                        if (self.vcon != nil) {
                                            [self.vcon setTitle:strs];
                                        }
                                    }
                                    if (byte[0] == '1') {
                                        if (self.tcon != nil) {
                                            [self.tcon tabt:strs indx:self.vidx.intValue];
                                        }
                                    }
                                });
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
                        } else if (('0' <= buff[x]) && (buff[x] <= '9')) {
                            /* !]0;... */
                            [self.info appendBytes:(const char *)&(buff[x]) length:1];
                        } else {
                            NSLog(@"ANSI ERRO [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                            self.ansd = @(0);
                            self.ansi = @(9);
                        }
                        if (self.ansd.intValue != 0) {
                            //NSLog(@"ANSI PROC [%d][%d] [%d][%d]", x, buff[x], self.ansi.intValue, self.ansd.intValue);
                        }
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
    }
    return 0;
}

- (int)inpt:(NSEvent *)objc indx:(int)indx letr:(char)letr {
    if ([self chkf] != 0) { return 1; }
    if (self.vcon == nil) { return 2; }

    int imax = (5 * (self.cols.intValue - 3));
    int iidx = self.indx.intValue;
    char byte;
    int codc = 0;
    NSString *chrs = @"";
    NSEventModifierFlags flag = 0;

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
        int comd = (flag & NSEventModifierFlagCommand) ? 1 : 0;

        VTermModifier mods = VTERM_MOD_NONE;
        if (flag & NSEventModifierFlagShift)   mods |= VTERM_MOD_SHIFT;
        if (flag & NSEventModifierFlagControl) mods |= VTERM_MOD_CTRL;
        if (flag & NSEventModifierFlagOption)  mods |= VTERM_MOD_ALT;

        NSLog(@"INPT [%@][%ld] [%d][%d] [%d][%d] <%d>{%d}", chrs, [chrs length], comd, codc, indx, iidx, mods, code);

        VTermKey keyc = VTERM_KEY_NONE;
        switch (codc) {
            case 126: keyc = VTERM_KEY_UP;    break;
            case 125: keyc = VTERM_KEY_DOWN;  break;
            case 124: keyc = VTERM_KEY_RIGHT; break;
            case 123: keyc = VTERM_KEY_LEFT;  break;
        }

        size_t leng = [chrs length];
        if (comd == 1) {
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
                /* no-op */
            } else if (code == 'v') {
                [self ginp];
            } else if (code == 't') {
                [self.vcon taba:nil];
            } else if (code == 'd') {
                [self halt:@"comd"];
            } else if (code == 'q') {
                [NSApp terminate:nil];
                self.quit = @(self.quit.intValue + 1);
                if (self.quit.intValue >= 3) { exit(0); }
            } else if (code == 'n') {
                id appDelegate = [NSApp delegate];
                if ([appDelegate respondsToSelector:@selector(makeNewWindow:)]) {
                    [appDelegate performSelectorOnMainThread:@selector(makeNewWindow:) withObject:nil waitUntilDone:NO];
                }
            } else if (code == 'w') {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.wino != nil) {
                        [self.wino performClose:nil];
                    }
                });
            } else if (code == 'k') {
                if (self.mode.intValue == 0) {
                    self.irow = @(0); self.icol = @(0);
                    self.orow = @(0); self.ocol = @(0);
                    [self.hist removeAllObjects];
                    @synchronized (self) {
                        vterm_screen_reset(self.vtsc, 1);
                        self.crow = @0; self.ccol = @0;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.vcon show:@"clrs" data:nil pref:nil indx:self.vcon.indx.intValue sels:4 cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];
                            for (int z = 0; z < 1; ++z) {
                                char byte = 3;
                                write(self.mfdn.intValue, &byte, 1);
                            }
                        });
                    };
                }
            }
        } else if (code == 3) {
            NSLog(@"INPT int");
            //kill(self.pidn.intValue, SIGINT);
            byte = code;
            write(self.mfdn.intValue, &byte, 1);
            self.ansi = @(0);
        } else if (code == 27) {
            NSLog(@"INPT esc");
            if (self.vcon.srcs.intValue != 0) {
                [self.vcon find];
            } else {
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            }
            self.ansi = @(0);
        } else if (code == 9) {
            NSLog(@"INPT tab");
            byte = code;
            write(self.mfdn.intValue, &byte, 1);
            self.ansi = @(0);
        } else if (flag & NSEventModifierFlagControl) {
            NSLog(@"CTRL [%d]", code);
            if (code == 4) {
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
            NSLog(@"TERM KEYC");
            @synchronized (self) {
                vterm_keyboard_key(self.term, keyc, mods);
            };
        } else {
            if ((mods & VTERM_MOD_SHIFT) && (code == ' ')) {
                NSLog(@"DROP BELL");
                mods = 0;
            }
            for (int i = 0; i < leng; ++i) {
                byte = [chrs characterAtIndex:i];
                self.ilen = @(self.ilen.intValue + 1);
                if ((byte == 8) || (byte == 127)) {
                    NSLog(@"INPT backspace");
                } else if (self.ilen.intValue > imax) {
                    NSLog(@"INPT DROP");
                    continue;
                }
                @synchronized (self) {
                    vterm_keyboard_unichar(self.term, byte, mods);
                };
            }
            self.quit = @0;
        }
        if (code == 13) {
            self.irow = @(0); self.icol = @(0);
            self.orow = @(0); self.ocol = @(0);
            self.ilen = @(0);
        }
        leng = vterm_output_get_buffer_remaining(self.term);
        if (leng > 0) {
            char *data = malloc(leng);
            if (data != NULL) {
                size_t rlen = vterm_output_read(self.term, data, leng);
                write(self.mfdn.intValue, data, rlen);
                free(data);
            }
        }
    }

    int cidx = ((self.irow.intValue << 16) | (self.ccol.intValue + 0));
    __block NSAttributedString *disp = [[NSAttributedString alloc] init];
    if (self.mode.intValue != 2) {
        @synchronized (self) {
            disp = [self gout:@"inpt" mode:0];
        };
    }
    self.ilen = @([disp.string length]);
    //NSLog(@"INPS [%d] [%d][%d] [%d][%d] [%d][%d] [%ld] [%@]", self.vidx.intValue, self.irow.intValue, self.icol.intValue, self.crow.intValue, self.ccol.intValue, self.rows.intValue, self.cols.intValue, [disp length],disp);
    int rowc = self.rows.intValue;
    int colc = self.cols.intValue;
    int vidx = self.vidx.intValue;
    NSString *pref = [self.pref copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vcon show:@"inpt" data:disp pref:pref indx:vidx sels:0 cidx:cidx rows:rowc cols:colc];
    });

    return 0;
}

- (void)winz:(NSString *)text wide:(CGFloat)wide high:(CGFloat)high {
    int indx = self.indx.intValue;
    int fdes = self.mfdn.intValue;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tcon sets:text wide:wide high:high];
        CGFloat pixw = MAX( 4.0, self.tcon.fntw.floatValue);
        CGFloat pixh = MAX(12.0, self.tcon.fnth.floatValue);
        int rows = ((int)((high / pixh) - 7)); rows = MAX( 5, rows);
        int cols = ((int)((wide / pixw) - 7)); cols = MAX(35, cols);
        //rows = MAX( 5, rows - 1);
        if ((self.tcon.srcs.intValue != 0) || (self.tcon.stts.intValue != 0)) {
            rows = MAX( 5, rows - 1);
        }
        int size = ((rows + 3) * (cols + 3));
        struct winsize wsiz;
        wsiz.ws_row = rows;
        wsiz.ws_col = cols;
        wsiz.ws_xpixel = ((int)wide);
        wsiz.ws_ypixel = ((int)high);
        ioctl(fdes, TIOCSWINSZ, &wsiz);
        self.rows = @(rows);
        self.cols = @(cols);
        NSLog(@"WINZ [%@] [%d] [%f][%f] [%d][%d] [%f][%f] [%d]", text, indx, wide, high, cols, rows, pixw, pixh, size);
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
    });
}

- (int)opty {
    int mfdn, sfdn;
    char name[128];
    char *args[] = {"/bin/bash", "-i", "-l", NULL};
    char *cmds[] = {"stty raw isig echo \n", NULL};
    pid_t pidn;
    struct termios ttys;
    setenv("TERM", "xterm-256color", 1);
    setenv("EXEC", "ss", 1);
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
        execv(args[0], args);
    } else {
        close(sfdn);
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
    }
    return 1;
}

- (void)initProc:(ViewController *)vcon widx:(int)widx indx:(int)indx wide:(CGFloat)wide high:(CGFloat)high wino:(NSWindow *)wino {
    self.quit = @0;

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
    self.ilen = @0;
    self.loco = @0;

    self.crow = @0;
    self.ccol = @0;
    self.irow = @0;
    self.icol = @0;
    self.orow = @0;
    self.ocol = @0;

    self.pref = @"";

    self.info = [[NSMutableData alloc] init];
    self.part = [[NSMutableAttributedString alloc] init];
    self.hist = [[NSMutableArray alloc] init];

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

    NSLog(@"PROC [%d][%d] [%d] [%d][%d] [%f][%f]", indx, self.vidx.intValue, self.pidn.intValue, self.sfdn.intValue, self.mfdn.intValue, wide, high);
}

- (instancetype)init {
    self = [super init];
    return self;
}

@end
