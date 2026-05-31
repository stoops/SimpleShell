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
- (unsigned long long)getl;
- (NSString *)gout:(int)mode;
@end

static int screen_movecursor(VTermPos pos, VTermPos oldpos, int visible, void *user) {
    MainProc *self = (__bridge MainProc *)(user);
    int prow = pos.row;
    int pcol = pos.col;
    int activeMode = self.mode.intValue;
    int targetVidx = self.vidx.intValue;
    __block int targetRows = 0;
    __block int targetCols = 0;
    __block int safeCidx = 0;
    __block NSString *outpData = nil;
    @synchronized (self) {
        self.crow = @(pos.row);
        self.ccol = @(pos.col);
        targetRows = self.rows.intValue;
        targetCols = self.cols.intValue;
        safeCidx = ((pos.row << 16) | (pos.col & 0xffff));
        if (activeMode == 2) {
            outpData = [self gout:2];
        }
    };
    NSLog(@"CURS [%d][%d] [%d][%d] [%d][%d] (Mode: %d)", prow, pcol, pos.row, pos.col, targetRows, targetCols, activeMode);
    if (prow < self.orow.intValue) {
        NSLog(@"CURS LOCK [%d] [%d][%d] [%d][%d]", -1, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue);
        self.loco = @([self getl]);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.vcon != nil) {
            if (self.mode.intValue == 2) {
                [self.vcon show:@"movs" data:outpData pref:nil indx:targetVidx sels:2 cidx:safeCidx rows:targetRows cols:targetCols];
            }
            [self inpt:nil indx:self.vidx.intValue letr:0];
        }
    });
    return 1;
}

static int screen_damage(VTermRect rect, void *user) {
    MainProc *self = (__bridge MainProc *)(user);
    static CFAbsoluteTime last = 0;
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
    int activeMode = self.mode.intValue;
    int targetVidx = self.vidx.intValue;
    __block int targetRows = 0;
    __block int targetCols = 0;
    __block int safeCidx = 0;
    __block NSString *outpData = nil;
    @synchronized (self) {
        targetRows = self.rows.intValue;
        targetCols = self.cols.intValue;
        safeCidx = ((targetRows << 16) | (targetCols & 0xffff));
        if (activeMode == 2) {
            outpData = [self gout:2];
        }
    };
    //NSLog(@"DATA [%d][%d] (Mode: %d)", targetRows, targetCols, activeMode);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.vcon != nil) {
            if (self.mode.intValue == 2) {
                [self.vcon show:@"disp" data:outpData pref:nil indx:targetVidx sels:2 cidx:safeCidx rows:targetRows cols:targetCols];
            }
            [self inpt:nil indx:self.vidx.intValue letr:0];
        }
    });
    return 1;
}

static int screen_settermprop(VTermProp prop, VTermValue *val, void *user) {
    MainProc *self = (__bridge MainProc *)(user);
    if (prop == VTERM_PROP_ALTSCREEN) {
        int gridMode = val->boolean;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (gridMode) {
                NSLog(@"ANSI MODE");
                self.mode = @(2);
                dispatch_async(dispatch_get_main_queue(), ^{
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
                });
            } else {
                NSLog(@"LINE MODE");
                self.irow = @(0); self.icol = @(0);
                self.orow = @(0); self.ocol = @(0);
                self.mode = @(0);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.vcon != nil) {
                        [self.vcon show:@"prop" data:nil pref:nil indx:self.vidx.intValue sels:3 cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];
                        [self inpt:nil indx:self.vidx.intValue letr:0];
                    }
                });
            }
        });
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
        //NSLog(@"STAT LOOP");

        MainProc *strongSelf = weakSelf;
        if (!strongSelf) { return; }

        BOOL isStatsPanelEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"sysv"];
        if (!isStatsPanelEnabled) { return; }

        NSTask *statsTask = [[NSTask alloc] init];
        NSPipe *outputPipe = [NSPipe pipe];

        NSString *bundleResPath = [[NSBundle mainBundle] resourcePath];
        NSString *execPath = [bundleResPath stringByAppendingPathComponent:@"stat.sh"];
        if (!execPath) { return; }

        [statsTask setLaunchPath:@"/bin/bash"];
        [statsTask setArguments:@[@"-c", [NSString stringWithFormat:@"chmod +x '%@' && '%@'", execPath, execPath]]];
        [statsTask setStandardOutput:outputPipe];
        [statsTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];

        NSError *taskError = nil;
        if (![statsTask launchAndReturnError:&taskError]) {
            NSLog(@"STATS EXEC ERROR: %@", taskError.localizedDescription);
            return;
        }

        NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        [statsTask waitUntilExit];

        if (outputData.length > 0) {
            NSString *rawString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
            NSString *cleanString = [rawString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            NSArray<NSString *> *statsLines = [cleanString componentsSeparatedByString:@"\n"];
            if (statsLines.count >= 3) {
                NSString *cpuMetricsText = [statsLines[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *ramMetricsText = [statsLines[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *netMetricsText = [statsLines[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (strongSelf.vcon != nil) {
                        if ([strongSelf.vcon respondsToSelector:@selector(cpuv)]) {
                            strongSelf.vcon.cpuv.stringValue = cpuMetricsText;
                            strongSelf.vcon.ramv.stringValue = ramMetricsText;
                            strongSelf.vcon.netv.stringValue = netMetricsText;
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
        //NSLog(@"TERM LOOP");

        MainProc *strongSelf = weakSelf;
        if (!strongSelf) { return; }

        NSTask *task = [[NSTask alloc] init];
        NSPipe *pipe = [NSPipe pipe];

        [task setLaunchPath:comd];
        [task setArguments:args];
        [task setStandardOutput:pipe];
        [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

        NSError *error = nil;
        if (![task launchAndReturnError:&error]) {
            NSLog(@"EXEC [%@]", error.localizedDescription);
            return;
        }

        NSFileHandle *file = [pipe fileHandleForReading];
        NSData *data = [file readDataToEndOfFile];
        [task waitUntilExit];
        if (data.length > 0) {
            self.pref = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self inpt:nil indx:self.vidx.intValue letr:0];
        }
    });

    dispatch_resume(self.loot);
}

- (int)chkf {
    if (self.stop != 0) { return 1; }
    if ((self.mfdn == nil) || (self.sfdn == nil)) { return 2; }
    if (self.mfdn.intValue < 1) { return 3; }
    if (self.sfdn.intValue < 1) { return 4; }
    return 0;
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

- (void)ginp {
    NSPasteboard *pbrd = [NSPasteboard generalPasteboard];
    if ([pbrd canReadItemWithDataConformingToTypes:@[NSPasteboardTypeString]]) {
        NSString *text = [pbrd stringForType:NSPasteboardTypeString];
        if ((text != nil) && ([text length] > 0)) {
            NSUInteger leng = [text length];
            for (NSUInteger i = 0; i < leng; ++i) {
                unichar letr = [text characterAtIndex:i];
                if ((letr == '\n') || (letr == '\r')) {
                    break; // todo OR replace with ;
                } else if (letr == '\t') {
                    [self inpt:nil indx:0 letr:' '];
                    [self inpt:nil indx:0 letr:' '];
                } else if ((31 < letr) && (letr < 127)) {
                    [self inpt:nil indx:0 letr:letr];
                }
            }
        }
    }
}

- (int)gidx:(int)mode {
    int i = 0, j = 0, k = 0, z = 0;
    const unsigned char *q = [self.ansi bytes];
    if (mode == 0) {
        z = ((self.crow.intValue * (self.cols.intValue - 1)) + self.ccol.intValue);
        goto last;
    }
    if (mode == 1) {
        for (int r = 0; r < (self.rows.intValue - 1); ++r) {
            for (int c = 0; c < (self.cols.intValue - 1); ++c) {
                i = ((r * (self.cols.intValue - 1)) + c);
                if (q[i] == 1) {
                    ++k;
                }
                if ((q[i] != 0) && (q[i] != 1)) {
                    if ((r == self.crow.intValue) && (c == self.ccol.intValue)) {
                        z = (j + k);
                        goto last;
                    }
                    ++j;
                }
            }
        }
        z = (j + k);
        goto last;
    }
last:
    if ((z >= [self.ansi length]) || (z >= [self.ansp length])) {
        NSLog(@"INDX [%d] [%ld][%ld", z, [self.ansi length], [self.ansp length]);
        z = 0;
    }
    return z;
}

- (void)comp {
    NSMutableString *outs = [@"" mutableCopy];
    NSString *outp = [self gout:1];
    NSMutableArray *info = [[outp componentsSeparatedByString:@"\n"] mutableCopy];
    if ([outp length] > 0) {
        NSString *last = [info lastObject];
        if (([self.hist count] < 1) || (![[self.hist lastObject] isEqualToString:last])) {
            NSString *line = [[NSString stringWithFormat:@"\n%@", last] copy];
            [outs appendString:line];
            [self.hist addObject:[last copy]];
        }
    }
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

- (NSString *)gout:(int)mode {
    if ((mode == 0) || (mode == 1) || (mode == 2)) {
        NSMutableString *line = [NSMutableString string];
        NSMutableString *cstr = [NSMutableString string];
        NSMutableString *outp = [NSMutableString string];
        NSMutableArray *list = [NSMutableArray array];
        NSMutableString *inpt = [@"" mutableCopy];
        NSMutableString *join = [@"\n" mutableCopy];
        VTermState *stat = vterm_obtain_state(self.term);
        int maxr = self.rows.intValue;
        int maxc = self.cols.intValue;
        int hack = 0;
        if ((maxr < 1) || (maxc < 1)) {
            return @"";
        }
        [line setString:@""];
        for (int r = 0; r < maxr; ++r) {
            [cstr setString:@""];
            for (int c = 0; c < maxc; ++c) {
                VTermScreenCell cell;
                VTermPos cpos = { .row = r, .col = c };
                if (vterm_screen_get_cell(self.vtsc, cpos, &cell)) {
                    if (cell.chars[0] != 0) {
                        if ((31 < cell.chars[0]) && (cell.chars[0] < 127)) {
                            [cstr appendFormat:@"%C", (unsigned short)cell.chars[0]];
                        } else {
                            [cstr appendFormat:@" "];
                        }
                    } else if (mode == 2) {
                        [cstr appendFormat:@" "];
                    }
                }
            }
            //NSLog(@"OUTP LOOP [%d] [%d][%d] [%d][%d] [%@]", mode, self.crow.intValue, self.ccol.intValue, r, self.cols.intValue, cstr);
            if ((r == (maxr - 1)) && ([cstr length] == 1) && ([cstr UTF8String][0] == ' ')) {
                NSLog(@"GOUT WRAP");
                if (mode == 0) {
                    [cstr setString:@""];
                }
            }
            if ((r == (maxr - 2)) && ([cstr length] > 0)) {
                hack = 1;
            }
            BOOL wrap = NO;
            if ((r + 1 < maxr) && (stat != NULL)) {
                const VTermLineInfo *info = vterm_state_get_lineinfo(stat, r + 1);
                if ((info != NULL) && info->continuation) {
                    wrap = YES;
                }
            }
            if (mode == 2) {
                [list addObject:[cstr copy]];
            } else {
                [line appendString:cstr];
                if (!wrap) {
                    [list addObject:[line copy]];
                    [line setString:@""];
                }
            }
        }
        if ([line length] > 0) {
            [list addObject:[line copy]];
        }
        //NSLog(@"OUTP LIST [%d] [%d][%d] [%@]", mode, self.crow.intValue, self.ccol.intValue, list);
        if ((mode == 0) || (mode == 1)) {
            if ((mode != 0) || (hack != 1)) {
                while (([list count] > 0) && ([[list lastObject] length] < 1)) {
                    [list removeLastObject];
                }
            }
        }
        //NSLog(@"OUTP POST [%d] [%d][%d] [%@]", mode, self.crow.intValue, self.ccol.intValue, list);
        if (mode == 1) {
            unsigned long long nows = [self getl];
            if ([list count] > 0) { [list removeLastObject]; }
            if (self.crow.intValue >= self.orow.intValue) {
                self.orow = @(self.crow.intValue);
            }
            if ((nows - self.loco.unsignedLongLongValue) < 357) {
                NSLog(@"OUTP LOCK [%d] [%d][%d] [%d][%d]", mode, self.crow.intValue, self.ccol.intValue, self.orow.intValue, self.ocol.intValue);
                [list removeAllObjects];
            }
        }
        if (mode == 0) {
            inpt = ([list count] > 0) ? [list lastObject] : @"";
            [self.ansp setData:[inpt dataUsingEncoding:NSUTF8StringEncoding]];
            @synchronized (self) {
                self.irow = @(MAX(0, (self.rows.intValue - self.crow.intValue) -1));
                self.icol = @(self.ccol.intValue);
            };
        } else {
            outp = [[list componentsJoinedByString:join] mutableCopy];
        }
        if (mode == 0) {
            return [inpt copy];
        } else {
            return [outp copy];
        }
    }
    return @"";
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
                NSLog(@"OUTP END [%d][%d]", self.indx.intValue, self.vidx.intValue);
                int tabn = 0;
                for (int x = 0; x < [self.vcon.tabs count]; ++x) {
                    if ([self.vcon.remo containsObject:@(x)]) { continue; }
                    ++tabn;
                }
                if (tabn <= 1) { self.stop = @(2); }
                else { self.stop = @(1); }
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
                    [self comp];
                    llen += plen; ptra = ptrb;
                }

                for (int x = 0; x < leng; ++x) {
                    //NSLog(@"OUTP [%d] [%d][%c]", x, buff[x], buff[x]);
                    if (buff[x] == 27) {
                        self.skip = @(1);
                        self.flag = @(0);
                        [self.info setLength:0];
                        NSLog(@"ANSI [%d][%d] [%d][%d]", x, buff[x], self.skip.intValue, self.flag.intValue);
                    } else if (self.flag.intValue == 3) {
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
                                        if (self.wino != nil) {
                                            [self.wino setTitle:strs];
                                        }
                                    }
                                    if (byte[0] == '1') {
                                        if (self.tcon != nil) {
                                            [self.tcon tabt:strs indx:self.vidx.intValue];
                                        }
                                    }
                                });
                            }
                            self.flag = @(9);
                            NSLog(@"AEND [%d][%d] [%d][%d]", x, buff[x], self.skip.intValue, self.flag.intValue);
                        }
                        //NSLog(@"ALET [%d][%d] [%d][%d]", x, buff[x], self.skip.intValue, self.flag.intValue);
                    } else if (self.skip.intValue == 3) {
                        if (('0' <= buff[x]) && (buff[x] <= '9')) {
                            /* ![?01234h */
                        } else {
                            self.skip = @(9);
                        }
                        [self.info appendBytes:(const char *)&(buff[x]) length:1];
                        NSLog(@"SKIP [%d][%d] [%d][%d]", x, buff[x], self.skip.intValue, self.flag.intValue);
                    } else if (self.flag.intValue == 2) {
                        if (buff[x] == ';') {
                            self.flag = @(3);
                        } else if (('0' <= buff[x]) && (buff[x] <= '9')) {
                            /* !]0;... */
                            [self.info appendBytes:(const char *)&(buff[x]) length:1];
                        } else {
                            NSLog(@"AERR [%d][%d] [%d][%d]", x, buff[x], self.skip.intValue, self.flag.intValue);
                            self.flag = @(0);
                            self.skip = @(9);
                        }
                        if (self.flag.intValue != 0) {
                            NSLog(@"ABEG [%d][%d] [%d][%d]", x, buff[x], self.skip.intValue, self.flag.intValue);
                        }
                    } else if (self.skip.intValue == 2) {
                        if (('?' <= buff[x]) && (buff[x] <= '~')) {
                            if (buff[x] == '?') {
                                self.skip = @(3);
                            } else {
                                NSLog(@"ENDS [%d][%d] [%d][%d]", x, buff[x], self.skip.intValue, self.flag.intValue);
                                self.skip = @(9);
                            }
                        }
                    } else if (self.skip.intValue == 1) {
                        if (buff[x] == ']') {
                            self.flag = @(2);
                        }
                        self.skip = @(2);
                        NSLog(@"AMOD [%d][%d] [%d][%d]", x, buff[x], self.skip.intValue, self.flag.intValue);
                    } else if (buff[x] == 7) {
                        NSLog(@"BELL [%d][%d] [%d][%d]", x, buff[x], self.skip.intValue, self.flag.intValue);
                        self.flag = @(9);
                        self.skip = @(9);
                    }

                    if (self.flag.intValue >= 9) {
                        self.flag = @(0);
                        self.skip = @(0);
                    }

                    if (self.skip.intValue >= 9) {
                        if ([self.info length] > 0) {
                            NSLog(@"ANSI COMD [%@]", self.info);
                        }
                        self.skip = @(0);
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
                    [self.vcon next:zidx dirs:0 stop:0];
                }
                if (keyc == VTERM_KEY_LEFT) {
                    [self.vcon next:zidx dirs:1 stop:0];
                }
            }
            if (code == 'n') {
                NSLog(@"COMD MAKE");
                id appDelegate = [NSApp delegate];
                if ([appDelegate respondsToSelector:@selector(makeNewWindow:)]) {
                    [appDelegate performSelectorOnMainThread:@selector(makeNewWindow:) withObject:nil waitUntilDone:NO];
                }
            } else if (code == 'w') {
                NSLog(@"COMD CLOS");
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.wino != nil) {
                        [self.wino performClose:nil];
                    }
                });
            } else if (code == 'c') {
                NSLog(@"COPY");
            } else if (code == 'v') {
                [self ginp];
            } else if (code == 't') {
                [self.vcon taba:nil];
            } else if (code == 'd') {
                NSLog(@"COMD CLOS");
                [self.vcon tabx:(self.vcon.indx.intValue - 1)];
            } else if (code == 'q') {
                [NSApp terminate:nil];
            } else if (code == 'k') {
                if (self.mode.intValue == 0) {
                    self.irow = @(0); self.icol = @(0);
                    self.orow = @(0); self.ocol = @(0);
                    @synchronized (self) {
                        vterm_screen_reset(self.vtsc, 1);
                        self.crow = @0; self.ccol = @0;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.vcon show:@"clrs" data:nil pref:nil indx:self.vcon.indx.intValue sels:4 cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];
                            for (int z = 0; z < 1; ++z) {
                                char byte = 3;
                                write(self.mfdn.intValue, &byte, 1);
                                //byte = 10;
                                //write(self.mfdn.intValue, &byte, 1);
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
            self.skip = @(0);
        } else if (code == 27) {
            NSLog(@"INPT esc");
            byte = code;
            write(self.mfdn.intValue, &byte, 1);
            self.skip = @(0);
        } else if (code == 9) {
            NSLog(@"INPT tab");
            byte = code;
            write(self.mfdn.intValue, &byte, 1);
            self.skip = @(0);
        } else if (flag & NSEventModifierFlagControl) {
            if (code == 4) {
                NSLog(@"INPT eot");
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            } else if (code == 18) {
                NSLog(@"INPT rev");
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            } else if (code == 24) {
                NSLog(@"INPT can");
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            } else if (code == 26) {
                NSLog(@"INPT job");
                byte = code;
                write(self.mfdn.intValue, &byte, 1);
            } else if (keyc == VTERM_KEY_LEFT) {
                NSLog(@"INPT al");
                byte = 27;
                write(self.mfdn.intValue, &byte, 1);
                byte = 98;
                write(self.mfdn.intValue, &byte, 1);
            } else if (keyc == VTERM_KEY_RIGHT) {
                NSLog(@"INPT ar");
                byte = 27;
                write(self.mfdn.intValue, &byte, 1);
                byte = 102;
                write(self.mfdn.intValue, &byte, 1);
            } else {
                NSLog(@"INPT ???");
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
    __block NSString *disp = @"";
    if (self.mode.intValue != 2) {
        @synchronized (self) {
            disp = [self gout:0];
        };
    }
    self.ilen = @([disp length]);
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

- (void)wins:(NSString *)text wide:(CGFloat)wide high:(CGFloat)high {
    int indx = self.indx.intValue;
    int fdes = self.mfdn.intValue;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tcon sets:text wide:wide high:high];
        CGFloat pixw = MAX( 4.0, self.tcon.fntw.floatValue);
        CGFloat pixh = MAX(12.0, self.tcon.fnth.floatValue);
        int rows = ((int)((high / pixh) - 7)); rows = MAX( 5, rows);
        int cols = ((int)((wide / pixw) - 7)); cols = MAX(35, cols);
        BOOL sysv = [[NSUserDefaults standardUserDefaults] boolForKey:@"sysv"];
        //rows = MAX( 5, rows - 1);
        if (sysv) {
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
        NSLog(@"WINS [%d][%@] [%f][%f] [%d][%d] [%f][%f] [%d]", indx, text, wide, high, cols, rows, pixw, pixh, size);
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
        if (size > [self.ansi length]) {
            [self.ansi setLength:size];
        }
        if (size > [self.ansp length]) {
            [self.ansp setLength:size];
        }
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
    self.skip = @0;
    self.flag = @0;
    self.ilen = @0;
    self.loco = @0;

    self.crow = @0;
    self.ccol = @0;
    self.irow = @0;
    self.icol = @0;
    self.orow = @0;
    self.ocol = @0;

    self.pref = @"";

    self.ansi = [[NSMutableData alloc] init];
    self.ansp = [[NSMutableData alloc] init];
    self.info = [[NSMutableData alloc] init];

    self.hist = [[NSMutableArray alloc] init];

    self.wino = wino;
    self.tcon = vcon;
    self.vcon = nil;

    self.term = nil;
    self.vtsc = nil;

    [self opty];

    self.vidx = @([self.tcon newt:@"init" wide:wide high:high]);
    [self wins:@"init" wide:wide high:high];

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
