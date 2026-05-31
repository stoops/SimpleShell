//
//  ViewController.m
//  SimpleShell
//
//  Created by jon on 2026-05-30.
//

#import <CoreImage/CoreImage.h>

#import "ViewController.h"
#import "MainProc.h"
#import "AppDelegate.h"
#import "CursorText.h"
#import "TabButton.h"

@implementation ViewController

- (void)moveTabSrcTag:(NSNumber *)srcNum dstTag:(NSNumber *)dstNum {
    NSInteger srcTag = [srcNum integerValue];
    NSInteger dstTag = [dstNum integerValue];

    __block TabButton *srcButt = nil;
    __block TabButton *dstButt = nil;

    for (NSButton *btn in self.tabs) {
        if (btn.tag == srcTag && [btn isKindOfClass:[TabButton class]]) {
            srcButt = (TabButton *)btn;
        }
        if (btn.tag == dstTag && [btn isKindOfClass:[TabButton class]]) {
            dstButt = (TabButton *)btn;
        }
    }

    if ((!srcButt) || (!dstButt)) { return; }

    NSUInteger srcIndx = [self.tabs indexOfObject:srcButt];
    NSUInteger dstIndx = [self.tabs indexOfObject:dstButt];

    if ((srcIndx == NSNotFound) || (dstIndx == NSNotFound) || (srcIndx == dstIndx)) { return; }

    [self.tabs removeObjectAtIndex:srcIndx];
    [self.tabs insertObject:srcButt atIndex:dstIndx];

    [self.tabv removeView:srcButt];
    NSUInteger visualInsertIndex = [self.tabv.views indexOfObject:dstButt];
    [self.tabv insertView:srcButt atIndex:visualInsertIndex inGravity:NSStackViewGravityCenter];

    [self tabz:srcButt over:1];
    [self sets:@"tabd" wide:self.wide.floatValue high:self.high.floatValue];
}

- (void)didChangeBgdColor:(NSColor *)color {
    self.bgdc = color;
    self.view.layer.backgroundColor = self.bgdc.CGColor;
}

- (void)didChangeTabColor:(NSColor *)color {
    self.tabc = color;
    self.diva.layer.backgroundColor = self.tabc.CGColor;
    self.divb.layer.backgroundColor = self.tabc.CGColor;
    self.divc.layer.backgroundColor = self.tabc.CGColor;
    for (NSButton *tabb in self.tabs) {
        tabb.layer.borderColor = self.tabc.CGColor;
        tabb.layer.backgroundColor = self.tabc.CGColor;
    }
}

- (void)didChangeTxtColor:(NSColor *)color {
    self.txtc = color;
    NSMutableParagraphStyle *wrap = [[NSMutableParagraphStyle alloc] init];
    wrap.lineBreakMode = NSLineBreakByCharWrapping;
    self.attr = @{
        NSFontAttributeName: self.font,
        NSForegroundColorAttributeName: self.txtc,
        NSParagraphStyleAttributeName: wrap,
    };
    for (NSTextView *tv in self.outp) {
        tv.textColor = self.txtc;
    }
    for (NSTextView *tv in self.inpt) {
        tv.textColor = self.txtc;
    }
    self.cpuv.textColor = self.txtc;
    self.ramv.textColor = self.txtc;
    self.netv.textColor = self.txtc;
}

- (void)didChangeSelColor:(NSColor *)color {
    self.selc = color;
    for (NSTextView *tv in self.inpt) {
        if ([tv isKindOfClass:[CursorText class]]) {
            CursorText *ct = (CursorText *)tv;
            ct.colh = self.selc;
            [ct setNeedsDisplay:YES];
        }
    }
    for (NSTextView *tv in self.outp) {
        if ([tv isKindOfClass:[CursorText class]]) {
            CursorText *ct = (CursorText *)tv;
            ct.colh = self.selc;
            [ct setNeedsDisplay:YES];
        }
    }
}

- (void)didChangeCsrColor:(NSColor *)color {
    self.csrc = color;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSTextView *tv in self.inpt) {
            if ([tv isKindOfClass:[CursorText class]]) {
                CursorText *ct = (CursorText *)tv;
                ct.insertionPointColor = self.csrc;
                if (ct.layoutManager) {
                    [ct.layoutManager invalidateDisplayForCharacterRange:NSMakeRange(0, ct.string.length)];
                }
                NSWindow *window = ct.window;
                if (window) {
                    [window makeKeyWindow];
                    [window makeFirstResponder:nil];
                    [window makeFirstResponder:ct];
                }
                //[ct setLock];
                [ct setNeedsDisplay:YES];
            }
        }
        if (self.view.window) {
            [self.view.window displayIfNeeded];
        }
    });
}

- (void)didChangeBlrSlider:(CGFloat)factor {
    if (self.blrs == nil || self.blrs.layer == nil) { return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"BLUR [%f]", factor);
        if (factor <= 0.0) {
            self.blrs.layer.backgroundFilters = nil;
            self.blrs.layer.backgroundColor = [NSColor clearColor].CGColor;
            self.olay.layer.backgroundFilters = nil;
            self.olay.layer.backgroundColor = [NSColor clearColor].CGColor;
            [self.blrs removeFromSuperview];
        } else {
            if (![self.view.subviews containsObject:self.blrs]) {
                [self.view addSubview:self.blrs positioned:NSWindowBelow relativeTo:nil];
            }
            CGFloat targetRadius = (199.0 - (factor * 199.0));
            CGFloat calculatedAlpha = (0.05 + (0.15 * factor));
            CIFilter *updatedFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
            [updatedFilter setDefaults];
            [updatedFilter setValue:@(targetRadius) forKey:@"inputRadius"];
            self.olay.backgroundFilters = @[updatedFilter];
            self.olay.layer.backgroundColor = [self.bgdc colorWithAlphaComponent:calculatedAlpha].CGColor;
            //self.olay.layer.backgroundColor = [[NSColor whiteColor] colorWithAlphaComponent:calculatedAlpha].CGColor;
        }
        [self.blrs.layer setNeedsDisplay];
    });
}

- (void)didChangeSepString:(NSString *)sepString {
    NSMutableCharacterSet *allowedSet = [NSMutableCharacterSet alphanumericCharacterSet];
    if (sepString.length > 0) {
        [allowedSet addCharactersInString:sepString];
    }
    for (NSTextView *tv in self.inpt) {
        if ([tv isKindOfClass:[CursorText class]]) {
            CursorText *ct = (CursorText *)tv;
            ct.sepr = [allowedSet copy];
        }
    }
    for (NSTextView *tv in self.outp) {
        if ([tv isKindOfClass:[CursorText class]]) {
            CursorText *ct = (CursorText *)tv;
            ct.sepr = [allowedSet copy];
        }
    }
}

- (void)refc {
    [self didChangeBgdColor:self.bgdc];
    [self didChangeTabColor:self.tabc];
    [self didChangeTxtColor:self.txtc];
    [self didChangeSelColor:self.selc];
    [self didChangeCsrColor:self.csrc];
    [self.view setNeedsDisplay:YES];
}

- (void)refs {
    BOOL sysv = [[NSUserDefaults standardUserDefaults] boolForKey:@"sysv"];
    self.stts = sysv ? @(1) : @(0);
    if (self.vobj != nil) {
        int iidx = (self.indx.intValue - 1);
        if (iidx >= 0 && iidx < [self.oscr count]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSScrollView *oscr = [self.oscr objectAtIndex:iidx];
                NSView *inpv = [self.inpv objectAtIndex:iidx];
                if (self.stts.intValue == 0) {
                    self.sttv.hidden = YES;
                    self.divc.hidden = YES;
                    [self.allv setViews:@[self.topv, self.tabv, self.diva, oscr, self.divb, inpv] inGravity:NSStackViewGravityBottom];
                } else {
                    self.sttv.hidden = NO;
                    self.divc.hidden = NO;
                    [self.allv setViews:@[self.topv, self.tabv, self.diva, self.sttv, self.divc, oscr, self.divb, inpv] inGravity:NSStackViewGravityBottom];
                }
                [self sets:@"refs" wide:self.wide.floatValue high:self.high.floatValue];
            });
        }
    }
}

- (unsigned long)gets {
    NSTimeInterval secs = [[NSDate date] timeIntervalSince1970];
    return (unsigned long)secs;
}

- (unsigned long long)getl {
    NSDate *date = [NSDate date];
    unsigned long long mill = (long long)([date timeIntervalSince1970] * 1000.0);
    return mill;
}

- (float)itof:(unsigned int)rgbv shif:(int)shif {
    int valu = ((rgbv >> shif) & 0xff);
    float retn = (float)valu;
    return (retn / 255.0);
}

- (CGFloat)tell:(char)kind indx:(int)indx {
    CGFloat chwi = [self.font advancementForGlyph:[self.font glyphWithName:@"x"]].width;
    CGFloat chhi = ((self.font.ascender + fabs(self.font.descender)) + self.font.leading);
    //NSLog(@"FONT [%c] [%f][%f]", kind, chwi, chhi);
    if (kind == 'w') {
        return MAX( 4.0, chwi);
    } else {
        return MAX(12.0, chhi);
    }
}

- (void)clearActiveProtectionTimer {
    self.lall = nil;
}

- (int)sets:(NSString *)text wide:(CGFloat)wide high:(CGFloat)high {
    if (self.vobj != nil) {
        int iidx = (self.indx.intValue - 1);

        if ((-1 < iidx) && (iidx < [self.tabs count])) {
            NSView *view = self.view;
            NSView *diva = self.diva, *divb = self.divb, *divc = self.divc;
            NSStackView *allv = self.allv;
            NSStackView *tabv = self.tabv;
            NSView *inpv = [self.inpv objectAtIndex:iidx];
            NSScrollView *oscr = [self.oscr objectAtIndex:iidx];
            NSScrollView *iscr = [self.iscr objectAtIndex:iidx];
            NSNumber *ihis = [self.ihis objectAtIndex:iidx];
            CGFloat mulv = (wide * 0.9799);
            CGFloat mulw = (wide * 0.9900);

            if (self.coni != nil) {
                [NSLayoutConstraint deactivateConstraints:@[self.coni]];
                self.coni = [inpv.heightAnchor constraintEqualToConstant:ihis.floatValue];
            }

            if (self.cons != nil) {
                [NSLayoutConstraint deactivateConstraints:self.cons];
                self.cons = nil;
            }

            NSMutableArray<NSLayoutConstraint *> *cont = [@[
                [self.topv.heightAnchor constraintEqualToConstant:30.0],

                [allv.topAnchor constraintEqualToAnchor:view.topAnchor],
                [allv.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
                [allv.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
                [allv.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],

                [tabv.heightAnchor constraintEqualToConstant:35.0],

                [iscr.topAnchor constraintEqualToAnchor:inpv.topAnchor constant:0.0],
                [iscr.bottomAnchor constraintEqualToAnchor:inpv.bottomAnchor constant:0.0],
                [iscr.leadingAnchor constraintEqualToAnchor:inpv.leadingAnchor constant:0.0],
                [iscr.trailingAnchor constraintEqualToAnchor:inpv.trailingAnchor constant:0.0],

                [iscr.widthAnchor constraintEqualToConstant:mulv],
                [oscr.widthAnchor constraintEqualToConstant:mulv],

                [diva.heightAnchor constraintEqualToConstant:3.0],
                [divb.heightAnchor constraintEqualToConstant:3.0],

                [diva.widthAnchor constraintEqualToConstant:mulw],
                [divb.widthAnchor constraintEqualToConstant:mulw],

                [[self.spcs objectAtIndex:0].widthAnchor constraintEqualToAnchor:[self.spcs objectAtIndex:1].widthAnchor],

                self.coni,
            ] mutableCopy];
            if (self.stts.intValue == 1) {
                [cont addObject:[divc.heightAnchor constraintEqualToConstant:3.0]];
                [cont addObject:[divc.widthAnchor constraintEqualToConstant:mulw]];
                [cont addObject:[self.sttv.widthAnchor constraintEqualToConstant:mulw]];
            }

            int tabc = 0;
            for (int x = 0; x < [self.tabs count]; ++x) {
                if ([self.remo containsObject:@(x)]) { continue; }
                ++tabc;
            }

            CGFloat padd = (3.0 * 11.0);
            CGFloat gaps = (tabc > 0) ? ((tabc - 1) * tabv.spacing) : 0.0;
            CGFloat mult = (wide * 0.91);
            CGFloat usea = ((mult - padd) - gaps);
            CGFloat asbw = (usea / MAX(1.0, (float)(tabc)));

            for (int x = 0; x < [self.tabs count]; ++x) {
                NSButton *tabb = [self.tabs objectAtIndex:x];
                int tagn = ((int)([tabb tag]) - 1);
                if (tagn < 0) { continue; }
                if ([self.remo containsObject:@(tagn)]) { continue; }
                NSLayoutConstraint *tabc = [tabb.widthAnchor constraintEqualToConstant:asbw];
                tabc.priority = NSLayoutPriorityRequired - 1;
                [cont addObject:tabc];
                //tabc = [tabb.heightAnchor constraintEqualToAnchor:tabv.heightAnchor constant:-5.0];
                //[self.cons addObject:tabc];
                if ((tagn + 1) == self.indx.intValue) {
                    [tabb.layer setBorderColor:self.tabc.CGColor];
                    [tabb.layer setBackgroundColor:self.tabc.CGColor];
                    [tabb setNeedsDisplay:YES];
                } else {
                    NSColor *copy = [self.tabc colorWithAlphaComponent:0.05];
                    [tabb.layer setBorderColor:copy.CGColor];
                    [tabb.layer setBackgroundColor:copy.CGColor];
                    [tabb setNeedsDisplay:YES];
                }
            }

            for (NSLayoutConstraint *constraint in cont) {
                constraint.priority = NSLayoutPriorityDefaultHigh;
            }
            self.cons = [cont mutableCopy];

            [self adjt:iidx];

            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"LOCK [%@] [%d] [%f][%f]", text, iidx, wide, self.view.frame.size.width);
                if (self.lall != nil) {
                    dispatch_block_cancel(self.lall);
                    self.lall = nil;
                }
                if (self.lall == nil) {
                    if (self.alll == nil) {
                        self.alll = [allv.widthAnchor constraintEqualToConstant:wide];
                    }
                    self.alll.priority = NSLayoutPriorityRequired;
                    self.alll.constant = wide;
                    self.alll.active = YES;
                }

                [NSLayoutConstraint activateConstraints:self.cons];
                [view layoutSubtreeIfNeeded];

                if (self.lall == nil) {
                    __weak ViewController *weakSelf = self;
                    self.lall = dispatch_block_create(0, ^{
                        ViewController *strongSelf = weakSelf;
                        if (strongSelf) {
                            if (strongSelf.alll != nil) {
                                strongSelf.alll.active = NO;
                                NSLog(@"[Layout Protection] Protection window expired safely. Window width unlocked.");
                            }
                            [strongSelf.view layoutSubtreeIfNeeded];
                            [strongSelf clearActiveProtectionTimer];
                        }
                    });
                    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.975 * NSEC_PER_SEC));
                    dispatch_after(delayTime, dispatch_get_main_queue(), self.lall);
                }
            });

            [self show:text data:nil pref:nil indx:self.indx.intValue sels:0 cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];
            [self show:text data:nil pref:nil indx:self.indx.intValue sels:1 cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];

            NSLog(@"SETS [%@] [%d] [%f][%f]", text, iidx, wide, self.view.frame.size.width);
        }
    }

    return 0;
}

- (void)remo:(NSTextStorage *)objc area:(NSRange)area {
    [objc removeAttribute:NSForegroundColorAttributeName range:area];
    [objc removeAttribute:NSFontAttributeName range:area];
}

- (void)textViewDidChangeSelection:(NSNotification *)notification {
    NSTextView *txtv = (NSTextView *)notification.object;
    NSArray<NSValue *> *rngl = [txtv selectedRanges];
    if ([rngl count] > 0) {
        NSRange selr = [rngl.firstObject rangeValue];
        NSString *txts = [txtv.string substringWithRange:selr];
        if ((txts != nil) && ([txts length] > 0)) {
            NSLog(@"SELS [%@]", txts);
        }
    }
}

- (void)scrollViewDidScroll:(NSNotification *)notification {
    if (self.vobj != nil) {
        int iidx = (self.indx.intValue - 1);
        if ((-1 < iidx) && (iidx < [self.tabs count])) {
            NSNumber *scrp = [self.scrp objectAtIndex:iidx];
            NSNumber *scrl = [self.scrl objectAtIndex:iidx];
            NSClipView *cobj = [self.oclp objectAtIndex:iidx];
            CGFloat maxd = cobj.documentView.frame.size.height;
            CGFloat maxv = cobj.bounds.size.height;
            int maxy = (int)(maxd - maxv);
            int ypos = (int)(cobj.bounds.origin.y);
            int ppos = (int)(scrp.intValue);
            int dpos = abs(maxy - ypos);
            //NSLog(@"SCRO [%d] [%d][%d] [%d] [%d]", maxy, ypos, ppos, dpos, scrl.intValue);
            unsigned long secs = [self gets];
            int diff = 15;
            if ((ppos > -1) && ((secs - self.last.intValue) > 1)) {
                NSLog(@"SCRZ [%d] [%d][%d] [%d][%d] [%d] [%d]", iidx, diff, maxy, ypos, ppos, dpos, scrl.intValue);
                if ((scrl.intValue == 0) && (dpos > diff)) {
                    [self.scrl replaceObjectAtIndex:iidx withObject:@(1)];
                    self.last = @(secs);
                }
                if ((scrl.intValue == 1) && (dpos < diff)) {
                    [self.scrl replaceObjectAtIndex:iidx withObject:@(0)];
                    self.last = @(secs);
                }
            }
            [self.scrp replaceObjectAtIndex:iidx withObject:@(ypos)];
        }
    }
}

- (void)adjt:(int)indx {
    if (self.vobj != nil) {
        if ((-1 < indx) && (indx < [self.tabs count])) {
            NSTextView *inpt = [self.inpt objectAtIndex:indx];
            NSTextStorage *stor = inpt.textStorage;

            NSString *raws = stor.string;
            if (raws.length > 0) {
                NSRange rang = [raws rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
                if (rang.location != NSNotFound) {
                    [stor beginEditing];
                    while (rang.location != NSNotFound) {
                        [stor replaceCharactersInRange:rang withString:@""];
                        raws = stor.string;
                        rang = [raws rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
                    }
                    [stor endEditing];
                }
            }

            NSLayoutManager *laym = inpt.layoutManager;
            NSTextContainer *txtc = inpt.textContainer;

            [laym ensureLayoutForTextContainer:txtc];

            CGFloat pahi = 15.0;
            CGFloat fohi = self.fnth.floatValue;
            CGFloat lahi = [laym usedRectForTextContainer:txtc].size.height;

            CGFloat mahi = MAX(fohi, lahi);
            CGFloat mlhi = (5 * fohi);
            CGFloat tahi = (mahi + pahi);

            tahi = MAX(tahi, fohi + pahi);
            tahi = MIN(tahi, mlhi + pahi);

            //NSLog(@"ADJT [%d] [%ld] [%f][%f] [%f][%f]", indx, inpt.string.length, fohi, lahi, mahi, tahi);

            dispatch_async(dispatch_get_main_queue(), ^{
                if ((self.coni != nil) && (self.coni.constant != tahi)) {
                    [self.ihis replaceObjectAtIndex:indx withObject:@(tahi)];
                    self.coni.constant = tahi;
                    [self.view layoutSubtreeIfNeeded];
                }
                if (inpt.layoutManager) {
                    [inpt.layoutManager invalidateDisplayForCharacterRange:NSMakeRange(0, inpt.textStorage.length)];
                }
            });
        }
    }
}

- (void)textDidChange:(NSNotification *)notification {
    if (self.vobj != nil) {
        int iidx = (self.indx.intValue - 1);
        if ((-1 < iidx) && (iidx < [self.tabs count])) {
            if ([self.inpt containsObject:notification.object]) {
                [self adjt:iidx];
            }
        }
    }
}

- (NSArray<NSValue *> *)textView:(NSTextView *)txtView willChangeSelectionFromCharacterRanges:(NSArray<NSValue *> *)oldRange toCharacterRanges:(NSArray<NSValue *> *)newRange {
    NSArray<NSValue *> *retRange = newRange;
    if (self.vobj != nil) {
        int iidx = (self.indx.intValue - 1);

        if ((-1 < iidx) && (iidx < [self.tabs count])) {
            if ([self.inpt containsObject:txtView]) {
                int cols = (self.cols.intValue + 1);
                int didx = [self.crsa objectAtIndex:iidx].intValue;

                int totl = ((int)[[txtView textStorage] length]);
                int numl = ((totl / cols) + 1);

                int rnum = (didx >> 16), cnum = (didx & 0xffff);
                int crno = MAX(0, (numl - rnum) - 1), ccno = cnum;
                if ((cnum % cols) == 0) { ++crno; ccno = 0; }

                int curs = ((crno * cols) + (ccno + 0));
                if (ccno < 2) { curs = totl; }
                if (curs < totl) { totl = curs; }

                NSRange locRange = NSMakeRange(totl, 0);
                retRange = @[[NSValue valueWithRange:locRange]];

                //NSLog(@"SELV [%d] [%d][%d] [%d][%d] [%d] [%d][%d] [%lu] [%@][%@]", iidx, rnum, cnum, crno, ccno, curs, self.rows.intValue, self.cols.intValue, (unsigned long)totl, newRange, retRange);

                if (newRange.count > 0) {
                    if (newRange.count > 0) {
                        NSRange tmpRange = [newRange.firstObject rangeValue];
                        if (tmpRange.length > 0) {
                            return newRange;
                        }
                        if (tmpRange.location < totl) {
                            return retRange;
                        }
                    }
                }
            }
        }
    }
    return retRange;
}

- (int)show:(NSString *)text data:(NSString *)data pref:(NSString *)pref indx:(int)indx sels:(int)sels cidx:(int)cidx rows:(int)rows cols:(int)cols {
    int iidx = (indx - 1);
    long leng = ([self.tabs count] - 1);

    if (self.vobj == nil) { return 1; }
    if ((iidx < 0) || (iidx > leng)) { return -2; }
    if ((rows < 5) || (cols < 5)) { return 3; }

    self.rows = @(rows);
    self.cols = @(cols);

    int didx = cidx;
    if (didx < 0) {
        if (sels == 0) { didx = [self.crsa objectAtIndex:iidx].intValue; }
        if (sels == 1) { didx = [self.crsb objectAtIndex:iidx].intValue; }
        if (sels == 2) { didx = [self.crsc objectAtIndex:iidx].intValue; }
    } else {
        if (sels == 0) { [self.crsa replaceObjectAtIndex:iidx withObject:@(didx)]; }
        if (sels == 1) { [self.crsb replaceObjectAtIndex:iidx withObject:@(didx)]; }
        if (sels == 2) { [self.crsc replaceObjectAtIndex:iidx withObject:@(didx)]; }
    }

    if (([self.tabs count] < 1) || (iidx < 0) || ([self.tabs count] <= iidx)) {
        NSLog(@"ERRO show");
        return 0;
    }

    NSTextView *inpt = [self.inpt objectAtIndex:iidx];
    NSTextView *outp = [self.outp objectAtIndex:iidx];
    //NSTextStorage *itxt = [self.itxt objectAtIndex:iidx];
    NSTextStorage *otxt = [self.otxt objectAtIndex:iidx];
    NSNumber *scrl = [self.scrl objectAtIndex:iidx];

    int jidx = (self.indx.intValue - 1);
    CGFloat fntw = [self tell:'w' indx:iidx];
    //CGFloat fnth = [self tell:'h' indx:iidx];

    //NSLog(@"SHOW [%@] [%d][%d] [%d] [%f][%f] [%d][%d] [%d] [%d][%d] [%ld]",text,iidx,jidx,sels,fntw,fnth,rows,cols,cidx,didx>>16,didx&0xffff, data == nil ? -1 : [data length] );

    int wrap = (cols - 1);
    inpt.textContainer.containerSize = NSMakeSize(wrap * fntw, CGFLOAT_MAX);

    if (sels == 0) {
        NSMutableString *strs = [data mutableCopy];
        NSTextStorage *stor = [inpt textStorage];
        if (data != nil) {
            int curl = 0;
            if ((pref != nil) && ([pref length] > 0)) {
                [strs insertString:pref atIndex:0];
                curl += [pref length];
            }
            int slen = ((int)[strs length]);
            int mods = (slen % (wrap - 1));
            int llen = (slen / (wrap - 1));
            for (int x = 0; x < llen; ++x) {
                int zidx = ((x + 1) * (wrap - 1));
                if (mods == 0) {
                    [strs insertString:@"\u2193" atIndex:zidx];
                } else {
                    [strs insertString:@" " atIndex:zidx];
                }
                ++curl;
            }
            if ((slen > 0) && (mods == 0)) {
                strs = [[NSString stringWithFormat:@"%@\u203A", strs] mutableCopy];
                ++curl;
            }
            if (didx < 1) { didx = (int)([strs length]); }
            [self.crsa replaceObjectAtIndex:iidx withObject:@(didx + curl)];
            NSAttributedString *atrs = [[NSAttributedString alloc] initWithString:strs attributes:self.attr];
            [stor beginEditing];
            [stor setAttributedString:atrs];
            [stor endEditing];
        }
        if (iidx == jidx) {
            NSNotification *noti = [NSNotification notificationWithName:@"TextDidChange" object:inpt];
            [self textDidChange:noti];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view layoutSubtreeIfNeeded];
                NSWindow *wind = self.view.window;
                if ((wind != nil) && (wind == [NSApp keyWindow])) {
                    [wind makeFirstResponder:inpt];
                }
            });
        }
        if ([inpt isKindOfClass:[CursorText class]]) {
            CursorText *ct = (CursorText *)inpt;
            ct.wide = [self tell:'w' indx:iidx];
            if (self.mode.intValue == 2) {
                ct.wide = 0.0;
            }
            [ct setNeedsDisplay:YES];
        }
    } else if ((sels == 1) || (sels == 3) || (sels == 4)) {
        NSString *strs = data;
        NSTextStorage *stor = [outp textStorage];
        if (sels == 4) {
            [stor beginEditing];
            [stor deleteCharactersInRange:NSMakeRange(0, stor.length)];
            [stor endEditing];
            [otxt beginEditing];
            [otxt deleteCharactersInRange:NSMakeRange(0, otxt.length)];
            [otxt endEditing];
        }
        if (sels == 3) {
            NSAttributedString *cche = [otxt attributedSubstringFromRange:NSMakeRange(0, [otxt length])];
            [stor beginEditing];
            [stor setAttributedString:cche];
            [stor endEditing];
            [outp.layoutManager ensureLayoutForTextContainer:outp.textContainer];
        }
        if (data != nil) {
            NSAttributedString *atrs = [[NSAttributedString alloc] initWithString:strs attributes:self.attr];
            [stor beginEditing];
            [stor appendAttributedString:atrs];
            [stor endEditing];
            [outp.layoutManager ensureLayoutForTextContainer:outp.textContainer];
            NSAttributedString *save = [stor attributedSubstringFromRange:NSMakeRange(0, [stor length])];
            [self.atrs replaceObjectAtIndex:iidx withObject:save];
            [otxt beginEditing];
            [otxt setAttributedString:[stor copy]];
            [otxt endEditing];
        }
        if (scrl.intValue == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [outp scrollToEndOfDocument:nil];
            });
        }
        self.mode = @(0);
    } else if (sels == 2) {
        NSString *strs = data;
        NSTextStorage *stor = [outp textStorage];
        if (data != nil) {
            NSAttributedString *atrs = [[NSAttributedString alloc] initWithString:strs attributes:self.attr];
            [stor beginEditing];
            [stor setAttributedString:atrs];
            int crsr = (didx >> 16), crsc = (didx & 0xffff);
            NSInteger crsi = ((crsr * (cols + 1)) + crsc);
            if (crsi >= 0 && (crsi < stor.length)) {
                NSRange rang = NSMakeRange(crsi, 1);
                NSString *targ = [stor.string substringWithRange:rang];
                NSColor *fill = self.csrc ? self.csrc : [NSColor whiteColor];
                NSColor *invr = self.bgdc ? self.bgdc : [NSColor blackColor];
                if ([targ isEqualToString:@"\n"]) {
                    [stor addAttribute:NSBackgroundColorAttributeName value:fill range:rang];
                } else {
                    [stor addAttribute:NSBackgroundColorAttributeName value:fill range:rang];
                    [stor addAttribute:NSForegroundColorAttributeName value:invr range:rang];
                }
            }
            [stor endEditing];
            [outp.layoutManager ensureLayoutForTextContainer:outp.textContainer];
            NSAttributedString *save = [stor attributedSubstringFromRange:NSMakeRange(0, [stor length])];
            [self.atrs replaceObjectAtIndex:iidx withObject:save];
        }
        self.mode = @(2);
    }

    return 0;
}

- (void)colt:(NSButton *)butt {
    NSMutableAttributedString *tita = [[NSMutableAttributedString alloc] initWithAttributedString:[butt attributedTitle]];
    NSRange titr = NSMakeRange(0, [tita length]);
    NSMutableParagraphStyle *tunc = [[NSMutableParagraphStyle alloc] init];
    tunc.lineBreakMode = NSLineBreakByTruncatingTail;
    tunc.alignment = NSTextAlignmentLeft;
    [tita addAttribute:NSParagraphStyleAttributeName value:tunc range:titr];
    [tita addAttribute:NSForegroundColorAttributeName value:self.txtc range:titr];
    [butt setAttributedTitle:tita];
}

- (int)next:(int)iidx dirs:(int)dirs stop:(int)stop {
    NSButton *prev = nil, *this = nil, *next = nil;
    for (int x = 0; x < [self.tabs count]; ++x) {
        NSButton *butn = [self.tabs objectAtIndex:x];
        int zidx = (((int)[butn tag]) - 1);
        if (![self.remo containsObject:@(zidx)]) {
            if (this != nil) {
                if (next == nil) { next = butn; }
            }
            if (zidx == iidx) { this = butn; }
            if (this == nil) { prev = butn; }
        } else {
            if (zidx == iidx) { this = butn; }
        }
    }
    if (this != nil) {
        if (dirs == 0) {
            if (next != nil) { [self tabz:next over:1]; return 1; }
            if (prev != nil) { [self tabz:prev over:1]; return 2; }
        }
        if (dirs == 1) {
            if (prev != nil) { [self tabz:prev over:1]; return 3; }
            if (next != nil) { [self tabz:next over:1]; return 4; }
        }
    }
    return 0;
}

- (void)tabx:(int)iidx {
    NSLog(@"TABX [%d]", iidx);

    int tabn = 0;
    for (int x = 0; x < [self.tabs count]; ++x) {
        if ([self.remo containsObject:@(x)]) { continue; }
        ++tabn;
    }

    if (tabn <= 1) { return; }
    if ([self.remo containsObject:@(iidx)]) { return; }
    if ((iidx <= -1) || ([self.tabs count] <= iidx)) { return; }

    [self.remo addObject:@(iidx)];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSButton *tabb = [self.tabs objectAtIndex:iidx];
        [self.tabv removeView:tabb];
        [tabb removeFromSuperview];
        [self next:iidx dirs:0 stop:0];
    });

    for (int x = 0; x < [self.tabs count]; ++x) {
        if ([self.remo containsObject:@(x)]) { continue; }
        [self tabt:@"Tab" indx:x];
    }
}

- (void)tabc:(id)sender {
    [self tabx:(self.indx.intValue - 1)];
}

- (int)tabz:(id)sender over:(int)ride {
    NSButton *tabb = (NSButton *)sender;
    if (self.vobj != nil) {
        unsigned long tagn = [tabb tag];
        int indx = ((int)(tagn) - 1);
        int iidx = (self.indx.intValue - 1);
        if ([self.remo containsObject:@(indx)]) { return 1; }
        if ((ride == 0) && (indx == iidx)) { return 2; }
        if ((-1 < indx) && (indx < [self.tabs count])) {
            NSLog(@"VIEW [%d][%d]", indx, iidx);
            self.indx = @(indx + 1);
            NSTextView *inpt = [self.inpt objectAtIndex:indx];
            NSTextView *outp = [self.outp objectAtIndex:indx];
            NSNumber *scrl = [self.scrl objectAtIndex:indx];
            [self refs];
            if (scrl.intValue == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [outp scrollToEndOfDocument:nil];
                });
            }
            if (inpt.window != nil) {
                [inpt.window makeFirstResponder:inpt];
            }
            [self didChangeCsrColor:self.csrc];
        }
    }
    return 0;
}

- (void)tabf:(id)sender {
    [self tabz:sender over:0];
}

- (int)tabt:(NSString *)text indx:(int)indx {
    int iidx = (indx - 1);
    if ([self.remo containsObject:@(iidx)]) { return 0; }
    if (self.vobj != nil) {
        if ((-1 < iidx) && (iidx < [self.tabs count])) {
            int tabn = 1;
            for (int x = 0; x < [self.tabs count]; ++x) {
                if ([self.remo containsObject:@(x)]) { continue; }
                if (x == iidx) { break; }
                ++tabn;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSButton *butt = [self.tabs objectAtIndex:iidx];
                NSString *head = [NSString stringWithFormat:@"%@  [#%d]", text, tabn];
                [butt setTitle:head];
                [butt setAlignment:NSTextAlignmentLeft];
                [butt.cell setLineBreakMode:NSLineBreakByTruncatingTail];
                [butt.cell setUsesSingleLineMode:YES];
                [self colt:butt];
            });
        }
        return 1;
    }
    return 0;
}

- (void)taba:(id)sender {
    NSLog(@"TABA");
    if (self.flag.intValue == 0) {
        self.flag = @1;
    }
}

- (int)newt:(NSString *)text wide:(CGFloat)wide high:(CGFloat)high {
    [self blur];
    [self sepr];

    unsigned long leng = [self.tabs count];
    int indx = (((int)leng) + 1);

    CGFloat chwi = [self.font advancementForGlyph:[self.font glyphWithName:@"x"]].width;
    CGFloat chhi = ((self.font.ascender + fabs(self.font.descender)) + self.font.leading);

    self.wide = @(wide);
    self.high = @(high);
    self.fntw = @([self tell:'w' indx:0]);
    self.fnth = @([self tell:'h' indx:0]);

    CGFloat ihis = (self.fnth.floatValue + 15.0);

    NSColor *bgcr = [NSColor colorWithRed:0.01 green:0.11 blue:0.19 alpha:0.91];
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = bgcr.CGColor;

    TabButton *tabb = [[TabButton alloc] init];
    [tabb setTag:indx];
    [tabb setBezelStyle:NSBezelStyleRounded];
    [tabb setWantsLayer:YES];
    [tabb setTranslatesAutoresizingMaskIntoConstraints:NO];
    [tabb.layer setBorderWidth:1.0];
    [tabb.layer setCornerRadius:9.0];
    [tabb.layer setBorderColor:self.tabc.CGColor];
    [tabb.layer setBackgroundColor:self.tabc.CGColor];
    [tabb setTarget:self];
    [tabb setAction:@selector(tabf:)];
    [tabb setFont:self.font];
    [self.tabs addObject:tabb];

    NSView *spcl = [[NSView alloc] init];
    [spcl setTranslatesAutoresizingMaskIntoConstraints:NO];
    [spcl setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.spcs addObject:spcl];
    NSView *spcr = [[NSView alloc] init];
    [spcr setTranslatesAutoresizingMaskIntoConstraints:NO];
    [spcr setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.spcs addObject:spcr];

    if (self.vobj == nil) {
        NSButton *butt = [[NSButton alloc] init];
        NSImage *imgo = [NSImage imageWithSystemSymbolName:@"plus.circle.fill" accessibilityDescription:nil];
        NSImageSymbolConfiguration *conf = [NSImageSymbolConfiguration configurationWithHierarchicalColor:self.txtc];
        NSImage *imgf = [imgo imageWithSymbolConfiguration:conf];
        [butt setWantsLayer:YES];
        [butt setTranslatesAutoresizingMaskIntoConstraints:NO];
        [butt setImageScaling:NSImageScaleProportionallyUpOrDown];
        [butt setImagePosition:NSImageOnly];
        [butt setBordered:NO];
        [butt.widthAnchor constraintEqualToConstant:21.0].active = YES;
        [butt.heightAnchor constraintEqualToConstant:21.0].active = YES;
        [butt setImage:imgf];
        butt.target = self;
        butt.action = @selector(taba:);
        [self.tabv addView:butt inGravity:NSStackViewGravityCenter];
        [self.tabv addView:spcl inGravity:NSStackViewGravityCenter];
    }

    if (self.vobj == nil) {
        NSButton *butt = [[NSButton alloc] init];
        NSImage *imgo = [NSImage imageWithSystemSymbolName:@"slash.circle.fill" accessibilityDescription:nil];
        NSImageSymbolConfiguration *conf = [NSImageSymbolConfiguration configurationWithHierarchicalColor:self.txtc];
        NSImage *imgf = [imgo imageWithSymbolConfiguration:conf];
        [butt setWantsLayer:YES];
        [butt setTranslatesAutoresizingMaskIntoConstraints:NO];
        [butt setImageScaling:NSImageScaleProportionallyUpOrDown];
        [butt setImagePosition:NSImageOnly];
        [butt setBordered:NO];
        [butt.widthAnchor constraintEqualToConstant:21.0].active = YES;
        [butt.heightAnchor constraintEqualToConstant:21.0].active = YES;
        [butt setImage:imgf];
        butt.target = self;
        butt.action = @selector(tabc:);
        [self.tabv addView:spcr inGravity:NSStackViewGravityCenter];
        [self.tabv addView:butt inGravity:NSStackViewGravityCenter];
    }

    if ([self.tabs count] < 1) {
        [self.tabv addView:tabb inGravity:NSStackViewGravityCenter];
    } else {
        [self.tabv insertView:tabb atIndex:([self.tabv.views count] - 2) inGravity:NSStackViewGravityCenter];
    }

    NSScrollView *oscr = [[NSScrollView alloc] init];
    [oscr setHasVerticalScroller:YES];
    [oscr setHasHorizontalScroller:NO];
    [oscr setDrawsBackground:NO];
    [oscr setTranslatesAutoresizingMaskIntoConstraints:NO];
    [oscr setFindBarPosition:NSScrollViewFindBarPositionAboveHorizontalRuler];
    [oscr.contentView setAutoresizesSubviews:YES];
    [self.oscr addObject:oscr];

    NSClipView *oclp = oscr.contentView;
    oclp.drawsBackground = NO;
    [self.oclp addObject:oclp];

    CursorText *outp = [[CursorText alloc] init];
    outp.font = self.font;
    outp.textColor = self.txtc;
    outp.backgroundColor = [NSColor clearColor];
    [outp setVerticallyResizable:YES];
    [outp setHorizontallyResizable:NO];
    [outp setEditable:NO];
    [outp setSelectable:YES];
    [outp setBackgroundColor:[NSColor clearColor]];
    [outp setTranslatesAutoresizingMaskIntoConstraints:YES];
    [outp.textContainer setWidthTracksTextView:YES];
    [outp.textContainer setHeightTracksTextView:NO];
    [outp.layoutManager setTypesetterBehavior:NSTypesetterLatestBehavior];
    outp.textContainer.lineFragmentPadding = 0.0;
    outp.textContainerInset = NSMakeSize(0.0, 7.0);
    [self.outp addObject:outp];
    [self.otxt addObject:[[NSTextStorage alloc] init]];

    outp.insertionPointColor = self.csrc;
    outp.wide = chwi;
    outp.high = chhi;
    outp.colh = self.selc;
    outp.sepr = [self.seps copy];

    [oscr setDocumentView:outp];

    NSView *inpv = [[NSView alloc] init];
    inpv.wantsLayer = YES;
    inpv.layer.backgroundColor = [NSColor clearColor].CGColor;
    inpv.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inpv addObject:inpv];

    NSScrollView *iscr = [[NSScrollView alloc] init];
    [iscr setHasVerticalScroller:NO];
    [iscr setHasHorizontalScroller:NO];
    [iscr setWantsLayer:YES];
    [iscr setTranslatesAutoresizingMaskIntoConstraints:NO];
    [iscr setAutohidesScrollers:YES];
    [iscr setDrawsBackground:NO];
    [iscr setAutomaticallyAdjustsContentInsets:NO];
    [iscr.contentView setDrawsBackground:NO];
    [iscr.contentView setPostsBoundsChangedNotifications:NO];
    [inpv addSubview:iscr];
    [self.iscr addObject:iscr];

    //NSTextView *inpt = [[NSTextView alloc] init];
    CursorText *inpt = [[CursorText alloc] init];
    inpt.font = self.font;
    inpt.textColor = self.txtc;
    inpt.backgroundColor = [NSColor clearColor];
    [inpt setDrawsBackground:NO];
    [inpt setEditable:YES];
    [inpt setSelectable:YES];
    [inpt setVerticallyResizable:YES];
    [inpt setHorizontallyResizable:NO];
    [inpt setTranslatesAutoresizingMaskIntoConstraints:YES];
    [inpt.textContainer setWidthTracksTextView:NO];
    [inpt.textContainer setHeightTracksTextView:NO];
    inpt.textContainer.lineFragmentPadding = 0.0;
    inpt.textContainerInset = NSMakeSize(0.0, 7.0);
    inpt.delegate = self;
    [self.inpt addObject:inpt];

    inpt.insertionPointColor = self.csrc;
    inpt.wide = chwi;
    inpt.high = chhi;
    inpt.colh = self.selc;
    inpt.sepr = [self.seps copy];

    [iscr setDocumentView:inpt];
    [self.itxt addObject:[[NSTextStorage alloc] init]];

    NSTextStorage *stor = [outp textStorage];
    [self.atrs addObject:(NSAttributedString *)stor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewDidScroll:) name:NSViewBoundsDidChangeNotification object:oclp];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:outp];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:inpt];

    [self.crsa addObject:@(0)];
    [self.crsb addObject:@(0)];
    [self.crsc addObject:@(0)];

    [self.ihis addObject:@(ihis)];
    [self.scrp addObject:@(-1)];
    [self.scrl addObject:@(0)];

    if (self.vobj == nil) {
        if (self.stts.intValue == 0) {
            [self.allv setViews:@[self.topv, self.tabv, self.diva, oscr, self.divb, inpv] inGravity:NSStackViewGravityBottom];
        } else {
            [self.allv setViews:@[self.topv, self.tabv, self.diva, self.sttv, self.divc, oscr, self.divb, inpv] inGravity:NSStackViewGravityBottom];
        }
        [self.view addSubview:self.allv];
        self.indx = @(indx);
        self.coni = [inpv.heightAnchor constraintEqualToConstant:ihis];
        self.vobj = self.view;
    }

    [self tabt:@"Tab" indx:indx];
    [self tabf:tabb];

    self.flag = @0;

    NSLog(@"NEWT [%@] [%d]", text, indx);

    return indx;
}

- (void)sepr {
    NSString *sepString = [[NSUserDefaults standardUserDefaults] stringForKey:@"seps"] ?: @"";
    NSMutableCharacterSet *sepSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [sepSet addCharactersInString:sepString];
    self.seps = sepSet;
}

- (void)blur {
    if (self.blrs != nil) { return; }
    self.blrs = [[NSView alloc] initWithFrame:self.view.bounds];
    self.blrs.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.blrs.wantsLayer = YES;
    self.blrs.layer.masksToBounds = YES;
    self.blrs.layer.backgroundFilters = nil;
    self.blrs.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.glas = [[NSVisualEffectView alloc] initWithFrame:self.view.bounds];
    self.glas.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.glas.material = NSVisualEffectMaterialSidebar;
    self.glas.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    self.glas.state = NSVisualEffectStateActive;
    self.olay = [[NSView alloc] initWithFrame:self.glas.bounds];
    self.olay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.olay.wantsLayer = YES;
    self.olay.layer.masksToBounds = YES;
    self.olay.layer.backgroundColor = [[NSColor whiteColor] colorWithAlphaComponent:0.05].CGColor;
    [self.glas addSubview:self.olay];
    [self.blrs addSubview:self.glas];
    [self.view addSubview:self.blrs positioned:NSWindowBelow relativeTo:nil];
    double factor = [[NSUserDefaults standardUserDefaults] objectForKey:@"blrs"] ? [[NSUserDefaults standardUserDefaults] doubleForKey:@"blrs"] : 0.91;
    [self didChangeBlrSlider:(CGFloat)factor];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"LOAD");

    NSMutableParagraphStyle *wrap = [[NSMutableParagraphStyle alloc] init];
    wrap.lineBreakMode = NSLineBreakByCharWrapping;

    self.vobj = nil;

    self.wide = @0.0;
    self.high = @0.0;
    self.fntw = @0.0;
    self.fnth = @0.0;
    self.rows = @0;
    self.cols = @0;

    self.indx = @0;
    self.mode = @0;
    self.last = @0;
    self.flag = @0;
    self.remo = [[NSMutableArray alloc] init];

    self.bgdc = [NSColor clearColor];
    self.tabc = [NSColor clearColor];
    self.txtc = [NSColor clearColor];
    self.selc = [NSColor clearColor];
    self.csrc = [NSColor clearColor];
    self.blrs = nil;

    self.font = [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Monaco" size:13.0] toHaveTrait:NSBoldFontMask];
    self.attr = @{
        NSFontAttributeName:self.font,
        NSForegroundColorAttributeName:self.txtc,
        NSParagraphStyleAttributeName: wrap,
    };

    self.ihis = [[NSMutableArray alloc] init];
    self.scrp = [[NSMutableArray alloc] init];
    self.scrl = [[NSMutableArray alloc] init];

    self.cons = nil;
    self.cono = nil;
    self.coni = nil;

    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = self.bgdc.CGColor;

    self.crsa = [[NSMutableArray alloc] init];
    self.crsb = [[NSMutableArray alloc] init];
    self.crsc = [[NSMutableArray alloc] init];

    self.outp = [[NSMutableArray alloc] init];
    self.otxt = [[NSMutableArray alloc] init];
    self.oclp = [[NSMutableArray alloc] init];
    self.oscr = [[NSMutableArray alloc] init];
    self.outv = [[NSMutableArray alloc] init];
    self.inpt = [[NSMutableArray alloc] init];
    self.itxt = [[NSMutableArray alloc] init];
    self.iclp = [[NSMutableArray alloc] init];
    self.iscr = [[NSMutableArray alloc] init];
    self.inpv = [[NSMutableArray alloc] init];

    self.tabs = [[NSMutableArray alloc] init];
    self.spcs = [[NSMutableArray alloc] init];
    self.atrs = [[NSMutableArray alloc] init];

    self.diva = [[NSView alloc] init];
    self.diva.wantsLayer = YES;
    self.diva.layer.backgroundColor = self.tabc.CGColor;

    self.divb = [[NSView alloc] init];
    self.divb.wantsLayer = YES;
    self.divb.layer.backgroundColor = self.tabc.CGColor;

    self.divc = [[NSView alloc] init];
    self.divc.wantsLayer = YES;
    self.divc.layer.backgroundColor = self.tabc.CGColor;

    self.topv = [[NSView alloc] init];
    self.topv.wantsLayer = YES;
    self.topv.translatesAutoresizingMaskIntoConstraints = NO;
    self.topv.layer.backgroundColor = [NSColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:0.90].CGColor;

    NSRect dimt = NSMakeRect(1.0, 1.0, 1.0, 1.0);
    self.tabv = [[NSStackView alloc] initWithFrame:dimt];
    self.tabv.distribution = NSStackViewDistributionFill;
    self.tabv.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.tabv.spacing = 4.0;
    self.tabv.wantsLayer = YES;
    self.tabv.layer.masksToBounds = YES;
    self.tabv.edgeInsets = NSEdgeInsetsMake(0.0, 11.0, 0.0, 11.0);
    [self.tabv setWantsLayer:YES];
    [self.tabv setTranslatesAutoresizingMaskIntoConstraints:NO];

    NSRect dimv = NSMakeRect(1.0, 1.0, 1.0, 1.0);
    self.allv = [[NSStackView alloc] initWithFrame:dimv];
    self.allv.distribution = NSStackViewDistributionFill;
    self.allv.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.allv.spacing = 0.0;
    self.allv.layer.masksToBounds = YES;
    [self.allv setWantsLayer:YES];
    [self.allv setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.allv setDistribution:NSStackViewDistributionFill];
    [self.allv setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationVertical];

    self.sttv = [[NSStackView alloc] initWithFrame:NSZeroRect];
    self.sttv.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.sttv.distribution = NSStackViewDistributionFillEqually;
    self.sttv.spacing = 12.0;
    self.sttv.edgeInsets = NSEdgeInsetsMake(4, 15, 4, 15);
    self.sttv.translatesAutoresizingMaskIntoConstraints = NO;
    self.sttv.wantsLayer = YES;
    self.sttv.layer.backgroundColor = [NSColor clearColor].CGColor;

    void (^configureLabel)(NSTextField *) = ^(NSTextField *tf) {
        tf.editable = NO;
        tf.selectable = NO;
        tf.bordered = NO;
        tf.drawsBackground = NO;
        tf.alignment = NSTextAlignmentCenter;
        tf.font = self.font;
        tf.textColor = self.txtc;
    };

    self.cpuv = [NSTextField labelWithString:@"CPU: 0.0%"];
    configureLabel(self.cpuv);

    self.ramv = [NSTextField labelWithString:@"RAM: 0.0%"];
    configureLabel(self.ramv);

    self.netv = [NSTextField labelWithString:@"NET: In: 0B/s • Out: 0B/s"];
    configureLabel(self.netv);

    [self.sttv addView:self.cpuv inGravity:NSStackViewGravityCenter];
    [self.sttv addView:self.ramv inGravity:NSStackViewGravityCenter];
    [self.sttv addView:self.netv inGravity:NSStackViewGravityCenter];

    self.cpuv.textColor = self.txtc;
    self.ramv.textColor = self.txtc;
    self.netv.textColor = self.txtc;
    [self refs];

    self.alll = nil;
    self.lall = nil;
}

@end
