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

#define INST  13.0
#define INSV -13.0

@interface NSResponder (MyFindSelectors)
- (void)noop:(id)sender;
@end

@implementation ViewController

- (void)moveTabSrcTag:(NSNumber *)srcNum dstTag:(NSNumber *)dstNum {
    NSInteger srcTag = [srcNum integerValue];
    NSInteger dstTag = [dstNum integerValue];

    __block TabButton *srcButt = nil;
    __block TabButton *dstButt = nil;

    int srcIndx = -1, dstIndx = -1;

    int tabi = 0;
    for (NSButton *btn in self.tabs) {
        if ([self.remo containsObject:@(btn.tag - 1)]) { continue; }
        if ((btn.tag == srcTag) && [btn isKindOfClass:[TabButton class]]) {
            srcButt = (TabButton *)btn; srcIndx = tabi;
        }
        if ((btn.tag == dstTag) && [btn isKindOfClass:[TabButton class]]) {
            dstButt = (TabButton *)btn; dstIndx = tabi;
        }
        ++tabi;
    }

    if ((!srcButt) || (!dstButt) || (srcIndx == dstIndx)) { return; }

    NSLog(@"MOVE [%d] -> [%d]", srcIndx, dstIndx);

    [self.tabs removeObjectAtIndex:srcIndx];
    [self.tabs insertObject:srcButt atIndex:dstIndx];

    [self.tabv removeView:srcButt];
    [self.tabv insertView:srcButt atIndex:dstIndx inGravity:NSStackViewGravityCenter];

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
    self.titl.textColor = self.txtc;
    self.cpuv.textColor = self.txtc;
    self.ramv.textColor = self.txtc;
    self.netv.textColor = self.txtc;
}

- (void)didChangeSelColor:(NSColor *)color {
    self.selc = color;

    NSDictionary *selAttrs = @{
        NSBackgroundColorAttributeName: self.selc
    };

    void (^applySelColor)(NSArray<NSTextView *> *) = ^(NSArray<NSTextView *> *textViews) {
        for (NSTextView *tv in textViews) {
            tv.selectedTextAttributes = selAttrs;
            if ([tv isKindOfClass:[CursorText class]]) {
                CursorText *ct = (CursorText *)tv;
                ct.selc = self.selc;
            }
            for (NSValue *rangeValue in tv.selectedRanges) {
                NSRange range = [rangeValue rangeValue];
                if (range.length > 0 && tv.layoutManager) {
                    [tv.layoutManager invalidateDisplayForCharacterRange:range];
                }
            }
            [tv setNeedsDisplay:YES];
        }
    };

    applySelColor(self.inpt);
    applySelColor(self.outp);

    for (NSTextView *tv in self.outp) {
        if ([tv isKindOfClass:[CursorText class]]) {
            CursorText *ct = (CursorText *)tv;
            NSWindow *window = ct.window;
            if (window) {
                [window makeKeyWindow];
                [window makeFirstResponder:nil];
                [window makeFirstResponder:ct];
            }
            [ct setNeedsDisplay:YES];
        }
    }
}

- (void)didChangeCrsColor:(NSColor *)color {
    self.crsc = color;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSTextView *tv in self.inpt) {
            if ([tv isKindOfClass:[CursorText class]]) {
                CursorText *ct = (CursorText *)tv;
                ct.insertionPointColor = self.crsc;
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

- (void)didChangeInpColor:(NSColor *)color {
    self.inpc = color;
    for (NSView *inpView in self.inpv) {
        inpView.layer.backgroundColor = self.inpc.CGColor;
    }
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
    NSLog(@"REFC");
    [self didChangeBgdColor:self.bgdc];
    [self didChangeTabColor:self.tabc];
    [self didChangeTxtColor:self.txtc];
    [self didChangeSelColor:self.selc];
    [self didChangeCrsColor:self.crsc];
    [self didChangeInpColor:self.inpc];
    NSImage *imgo;
    NSImageSymbolConfiguration *conf;
    imgo = [NSImage imageWithSystemSymbolName:@"plus.circle.fill" accessibilityDescription:nil];
    conf = [NSImageSymbolConfiguration configurationWithHierarchicalColor:self.txtc];
    self.imgl = [imgo imageWithSymbolConfiguration:conf];
    [self.butl setImage:self.imgl];
    imgo = [NSImage imageWithSystemSymbolName:@"slash.circle.fill" accessibilityDescription:nil];
    conf = [NSImageSymbolConfiguration configurationWithHierarchicalColor:self.txtc];
    self.imgr = [imgo imageWithSymbolConfiguration:conf];
    [self.butr setImage:self.imgr];
    [self.view setNeedsDisplay:YES];
}

- (void)refs {
    NSLog(@"REFS");
    [self refc];
    BOOL sysv = [[NSUserDefaults standardUserDefaults] boolForKey:@"sysv"];
    self.stts = sysv ? @(1) : @(0);
    if (self.vobj != nil) {
        int iidx = (self.indx.intValue - 1);
        if (iidx >= 0 && iidx < [self.oscr count]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSScrollView *oscr = [self.oscr objectAtIndex:iidx];
                NSView *inpv = [self.inpv objectAtIndex:iidx];
                if (self.srcs.intValue != 0) {
                    self.srcv.hidden = NO;
                    self.sttv.hidden = YES;
                    self.divc.hidden = NO;
                    [self.allv setViews:@[self.topv, self.tabv, self.diva, self.srcv, self.divc, oscr, self.divb, inpv] inGravity:NSStackViewGravityBottom];
                    NSWindow *wind = self.view.window;
                    if (wind != nil) {
                        [wind makeFirstResponder:self.srct];
                    }
                } else if (self.stts.intValue != 0) {
                    self.srcv.hidden = YES;
                    self.sttv.hidden = NO;
                    self.divc.hidden = NO;
                    [self.allv setViews:@[self.topv, self.tabv, self.diva, self.sttv, self.divc, oscr, self.divb, inpv] inGravity:NSStackViewGravityBottom];
                } else {
                    self.srcv.hidden = YES;
                    self.sttv.hidden = YES;
                    self.divc.hidden = YES;
                    [self.allv setViews:@[self.topv, self.tabv, self.diva, oscr, self.divb, inpv] inGravity:NSStackViewGravityBottom];
                }
                if (self.inpc.alphaComponent > 0.01) {
                    self.divb.hidden = YES;
                } else {
                    self.divb.hidden = NO;
                }
                [self sets:@"refs" wide:self.wide.floatValue high:self.high.floatValue];
                if (self.view.window != nil) {
                    NSLog(@"REFS [%ld]", [self.tabs count]);
                    id appd = [NSApplication sharedApplication].delegate;
                    if ([appd respondsToSelector:@selector(windowDidResize:)]) {
                        NSNotification *note = [NSNotification notificationWithName:NSWindowDidResizeNotification object:self.view.window];
                        [appd windowDidResize:note];
                    }
                }
            });
        }
    }
}

- (void)findText:(int)dirs {
    NSString *sstr = self.srct.stringValue;
    if (sstr.length == 0) { return; }

    int iidx = (self.indx.intValue - 1);
    if (iidx < 0 || iidx >= [self.outp count]) { return; }

    NSTextView *outp = [self.outp objectAtIndex:iidx];
    NSString *outt = outp.string;

    NSError *erro = nil;
    NSRegularExpression *regx = [NSRegularExpression regularExpressionWithPattern:sstr options:NSRegularExpressionCaseInsensitive error:&erro];
    if (erro) {
        return;
    }

    NSMutableArray<NSValue *> *mach = [NSMutableArray array];
    NSArray<NSTextCheckingResult *> *mrgx = [regx matchesInString:outt options:0 range:NSMakeRange(0, outt.length)];
    for (NSTextCheckingResult *item in mrgx) {
        [mach addObject:[NSValue valueWithRange:item.range]];
    }

    if ([mach count] == 0) {
        NSBeep();
        self.sidx = @(-1);
        return;
    }

    if (dirs == 1) {
        self.sidx = @((self.sidx.intValue + 1) % [mach count]);
    } else {
        if (self.sidx.intValue > 0) { self.sidx = @(self.sidx.intValue - 1); }
        else { self.sidx = @([mach count] - 1); }
    }

    NSRange rrng = [mach[self.sidx.intValue] rangeValue];
    [outp setSelectedRange:rrng];
    [outp scrollRangeToVisible:rrng];
}

- (void)findPrev:(id)sender {
    [self findText:-1];
}

- (void)findNext:(id)sender {
    [self findText:1];
}

- (void)findDone:(id)sender {
    self.srcs = @(0);
    [self refs];
}

- (void)find {
    if (self.srcs.intValue == 0) {
        self.srcs = @(1);
    } else {
        self.srcs = @(0);
        self.sidx = @(-1);
        self.srct.stringValue = @"";
        int iidx = (self.indx.intValue - 1);
        if ((-1 < iidx) && (iidx < [self.outp count])) {
            NSTextView *outp = [self.outp objectAtIndex:iidx];
            [outp setSelectedRange:NSMakeRange(0, 0)];
        }
    }
    [self refs];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (control == self.srct) {
        if (commandSelector == @selector(cancelOperation:)) {
            [self find];
            return YES;
        }
        if (commandSelector == @selector(noop:)) {
            NSEvent *currentEvent = [NSApp currentEvent];
            if (currentEvent.type == NSEventTypeKeyDown) {
                NSUInteger flags = (currentEvent.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask);
                BOOL cKey = (flags & NSEventModifierFlagCommand) == NSEventModifierFlagCommand;
                BOOL gKey = [[currentEvent charactersIgnoringModifiers] isEqualToString:@"g"];
                BOOL rKey = [[currentEvent charactersIgnoringModifiers] isEqualToString:@"r"];
                if (cKey && gKey) {
                    [self findText:1];
                    return YES;
                }
                if (cKey && rKey) {
                    [self findText:-1];
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)refv:(NSTimer *)timer {
    if ((self.vobj == nil) || (self.indx.intValue < 1)) { return; }

    NSString *text = @"refr";

    [self show:text data:nil pref:nil indx:self.indx.intValue sels:0 cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];
    [self show:text data:nil pref:nil indx:self.indx.intValue sels:1 cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];
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

- (void)adjb:(NSStackView *)tabv wide:(CGFloat)wide high:(CGFloat)high mode:(int)mode {
    int tabc = 0;
    for (int x = 0; x < [self.tabs count]; ++x) {
        if ([self.remo containsObject:@(x)]) { continue; }
        ++tabc;
    }

    [NSLayoutConstraint deactivateConstraints:self.cont];
    [self.cont removeAllObjects];

    NSButton *last = nil;
    for (int x = 0; x < [self.tabs count]; ++x) {
        NSButton *tabb = [self.tabs objectAtIndex:x];
        if ([self.remo containsObject:@(tabb.tag - 1)]) { continue; }
        NSColor *back = [self.tabc colorWithAlphaComponent:0.07];
        if (self.indx.intValue == tabb.tag) {
            [tabb.layer setBorderColor:self.tabc.CGColor];
            [tabb.layer setBackgroundColor:self.tabc.CGColor];
        } else {
            [tabb.layer setBorderColor:back.CGColor];
            [tabb.layer setBackgroundColor:back.CGColor];
        }
        if (last != nil) {
            NSLayoutConstraint *tcon = [tabb.widthAnchor constraintEqualToAnchor:last.widthAnchor];
            tcon.priority = NSLayoutPriorityRequired;
            [self.cont addObject:tcon];
        }
        last = tabb;
    }

    [NSLayoutConstraint activateConstraints:self.cont];
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
            CGFloat mulw = (wide * 0.9900);
            CGFloat barh = (17.0 * 1.55);

            //[NSLayoutConstraint deactivateConstraints:self.view.constraints];

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
                [tabv.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0.1],
                [tabv.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-0.1],

                [iscr.topAnchor constraintEqualToAnchor:inpv.topAnchor constant:0.0],
                [iscr.bottomAnchor constraintEqualToAnchor:inpv.bottomAnchor constant:0.0],
                [iscr.leadingAnchor constraintEqualToAnchor:inpv.leadingAnchor constant:0.0],
                [iscr.trailingAnchor constraintEqualToAnchor:inpv.trailingAnchor constant:0.0],

                [oscr.leadingAnchor constraintEqualToAnchor:allv.leadingAnchor constant:INST],
                [oscr.trailingAnchor constraintEqualToAnchor:allv.trailingAnchor constant:INSV],

                [diva.heightAnchor constraintEqualToConstant:3.0],
                [divb.heightAnchor constraintEqualToConstant:3.0],

                [diva.widthAnchor constraintEqualToConstant:mulw],
                [divb.widthAnchor constraintEqualToConstant:mulw],

                [self.spcl.widthAnchor constraintEqualToConstant:13.0],
                [self.spcl.widthAnchor constraintEqualToAnchor:self.spcr.widthAnchor],

                self.coni,
            ] mutableCopy];

            if (self.srcs.intValue != 0) {
                [cont addObject:[divc.heightAnchor constraintEqualToConstant:3.0]];
                [cont addObject:[divc.widthAnchor constraintEqualToConstant:mulw]];
                [cont addObject:[self.srct.widthAnchor constraintEqualToConstant:(wide * 0.33)]];
                [cont addObject:[self.srcv.heightAnchor constraintEqualToConstant:barh]];
            }

            if (self.stts.intValue != 0) {
                [cont addObject:[divc.heightAnchor constraintEqualToConstant:3.0]];
                [cont addObject:[divc.widthAnchor constraintEqualToConstant:mulw]];
                [cont addObject:[self.sttv.widthAnchor constraintEqualToConstant:mulw]];
                [cont addObject:[self.sttv.heightAnchor constraintEqualToConstant:barh]];
            }

            for (NSLayoutConstraint *constraint in cont) {
                constraint.priority = NSLayoutPriorityRequired;
            }
            self.cons = [cont mutableCopy];

            NSLayoutConstraint *lock = [tabv.widthAnchor constraintLessThanOrEqualToConstant:wide];
            lock.active = YES;
            //if (![text isEqualToString:@"wmov"]) {
            [self adjb:tabv wide:wide high:high mode:0];
            //}
            [NSLayoutConstraint activateConstraints:self.cons];
            [self adjt:iidx];
            //if (![text isEqualToString:@"wmov"]) {
            [self adjb:tabv wide:wide high:high mode:1];
            //}
            [view layoutSubtreeIfNeeded];
            lock.active = NO;

            NSLog(@"SETS [%@] [%d] [%f][%f]", text, iidx, wide, self.view.frame.size.width);
        }
    }

    return 0;
}

- (void)remo:(NSTextStorage *)objc area:(NSRange)area {
    [objc removeAttribute:NSForegroundColorAttributeName range:area];
    [objc removeAttribute:NSFontAttributeName range:area];
}

- (void)scro:(int)dirs {
    if (self.vobj == nil) { return; }
    int iidx = (self.indx.intValue - 1);
    if ((iidx < 0) || (iidx >= [self.outp count])) { return; }
    NSTextView *outp = [self.outp objectAtIndex:iidx];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (dirs == 0) {
            [outp scrollToBeginningOfDocument:nil];
        } else if (dirs == 1) {
            [outp scrollToEndOfDocument:nil];
        }
    });
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

            //NSLog(@"ADJT [%d] [%ld] [%f][%f] [%f][%f] [%f][%f]", indx, inpt.string.length, fohi, mlhi, lahi, mahi, tahi, pahi);

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
                int rows = (self.rows.intValue + 0);
                int wrap = (self.wrap.intValue + 0);
                int didx = [self.crsx objectAtIndex:iidx].intValue;

                int totl = ((int)[[txtView textStorage] length]);
                int rlen = ((totl / wrap) + 1);
                int rbeg = MAX(0, rows - rlen);

                int zero = 0;
                int rnum = (didx >> 16), cnum = (didx & 0xffff);
                int crno = MAX(0, rnum - rbeg), ccno = cnum;

                if (ccno == zero) {
                    crno = MAX(0, crno - 1); ccno = (wrap - 1);
                }

                int curs = ((crno * wrap) + (ccno + 0));
                if (curs < totl) { totl = curs; }

                NSRange locRange = NSMakeRange(totl, 0);
                retRange = @[[NSValue valueWithRange:locRange]];

                //NSLog(@"SELV [%d] [%d] [%d][%d] [%d][%d] [%d][%d] [%d][%d] [%lu] [%@][%@]", iidx, didx, rnum, cnum, crno, ccno, curs, wrap, self.rows.intValue, self.cols.intValue, (unsigned long)totl, newRange, retRange);

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

- (int)show:(NSString *)text data:(NSAttributedString *)data pref:(NSString *)pref indx:(int)indx sels:(int)sels cidx:(int)cidx rows:(int)rows cols:(int)cols {
    int iidx = (indx - 1);
    long leng = ([self.tabs count] - 1);

    if (self.vobj == nil) { return 1; }
    if ((iidx < 0) || (iidx > leng)) { return -2; }
    if ((rows < 5) || (cols < 5)) { return 3; }

    self.rows = @(rows);
    self.cols = @(cols);

    int didx = cidx;
    if (didx < 0) {
        if (sels == 0) { didx = [self.crsx objectAtIndex:iidx].intValue; }
        if (sels == 1) { didx = [self.crsy objectAtIndex:iidx].intValue; }
        if (sels == 2) { didx = [self.crsz objectAtIndex:iidx].intValue; }
    } else {
        if (sels == 0) { [self.crsx replaceObjectAtIndex:iidx withObject:@(didx)]; }
        if (sels == 1) { [self.crsy replaceObjectAtIndex:iidx withObject:@(didx)]; }
        if (sels == 2) { [self.crsz replaceObjectAtIndex:iidx withObject:@(didx)]; }
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

    self.wrap = @(cols - 1);

    int wrap = self.wrap.intValue;
    int crow = (didx >> 16), ccol = (didx & 0xffff);
    inpt.textContainer.containerSize = NSMakeSize(wrap * fntw, CGFLOAT_MAX);

    //NSLog(@"SHOW [%@] [%d][%d] [%d] [%f][%f] [%d][%d] [%d] [%d] [%d][%d] [%ld]",text,iidx,jidx,sels,fntw,fnth,rows,cols,wrap,cidx,crow,ccol, data == nil ? -1 : [data length] );

    NSMutableAttributedString *strs = (data != nil) ? [data mutableCopy] : [[NSMutableAttributedString alloc] init];
    [strs addAttributes:self.atrf range:NSMakeRange(0, [strs length])];
    if (sels == 0) {
        NSTextStorage *stor = [inpt textStorage];
        if (data != nil) {
            int plen = 0;
            int slen = ((int)[strs.string length]);
            if ((pref != nil) && ([pref length] > 0)) {
                NSAttributedString *prea = [[NSAttributedString alloc] initWithString:pref attributes:self.attr];
                [strs insertAttributedString:prea atIndex:0];
                plen += [pref length];
            }
            int wlen = ((int)[strs.string length]);
            int mods = (wlen % (wrap - 1));
            int llen = (wlen / (wrap - 1));
            for (int x = 0; x < llen; ++x) {
                int zidx = ((x + 1) * (wrap - 1));
                if (mods == 0) {
                    NSAttributedString *prea = [[NSAttributedString alloc] initWithString:@"\u2193" attributes:self.attr];
                    [strs insertAttributedString:prea atIndex:zidx];
                } else {
                    NSAttributedString *prea = [[NSAttributedString alloc] initWithString:@" " attributes:self.attr];
                    [strs insertAttributedString:prea atIndex:zidx];
                }
                ++plen;
            }
            if ((wlen > 0) && (mods == 0)) {
                NSAttributedString *prea = [[NSAttributedString alloc] initWithString:@"\u203A" attributes:self.attr];
                [strs appendAttributedString:prea];
                ++plen;
            }
            int rlen = ((slen / cols) + 1);
            int dlen = (((plen + slen) / wrap) + 1);
            int rbeg = MAX(0, rows - rlen);
            int dbeg = MAX(0, rows - dlen);
            int idxr = MAX(0, crow - rbeg);
            int idxt = ((idxr * cols) + ccol);
            int idxc = (plen + idxt);
            while (idxc >= wrap) { idxr = MIN(rows - 1, idxr + 1); idxc -= wrap; }
            int rowd = MIN(rows - 1, dbeg + idxr);
            int offl = MAX(0, (rows - rowd) - 1);
            int cold = MAX(0, idxc - offl);
            //NSLog(@"PREF [pre-off=%d] [pre-len=%d][str-len=%d] [old-len:%d][new-len:%d] [old-beg:%d][new-beg:%d] [old-idx:%d] [old-row:%d][old-col:%d] [inp-row:%d][inp-col:%d] [new-row:%d][new-col:%d] [%d][%@]", offl, plen, slen, rlen, dlen, rbeg, dbeg, idxt, crow, ccol, idxr, idxc, rowd, cold, wrap, pref);
            int eidx = ((rowd << 16) | cold);
            if (didx != 0) { [self.crsx replaceObjectAtIndex:iidx withObject:@(eidx)]; }
            [stor beginEditing];
            [stor setAttributedString:strs];
            [stor endEditing];
        }
        if (iidx == jidx) {
            if (data != nil) {
                NSNotification *noti = [NSNotification notificationWithName:@"TextDidChange" object:inpt];
                [self textDidChange:noti];
                CursorText *ct = (CursorText *)inpt;
                ct.wide = (self.mode.intValue != 2) ? fntw : 0.0;
                [ct setNeedsDisplay:YES];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view layoutSubtreeIfNeeded];
                NSWindow *wind = self.view.window;
                NSRange sels = [outp selectedRange];
                if (wind != nil) {
                    if ((self.srcs.intValue == 0) && (sels.length == 0)) {
                        [wind makeFirstResponder:inpt];
                    }
                }
            });
        }
    } else if ((sels == 1) || (sels == 3) || (sels == 4)) {
        NSTextStorage *stor = [outp textStorage];
        if (sels == 4) {
            [stor beginEditing];
            [stor deleteCharactersInRange:NSMakeRange(0, stor.length)];
            [stor endEditing];
            [otxt beginEditing];
            [otxt deleteCharactersInRange:NSMakeRange(0, otxt.length)];
            [otxt endEditing];
            [outp.layoutManager ensureLayoutForTextContainer:outp.textContainer];
        }
        if (sels == 3) {
            NSAttributedString *cche = [otxt attributedSubstringFromRange:NSMakeRange(0, [otxt length])];
            [stor beginEditing];
            [stor setAttributedString:cche];
            [stor endEditing];
            [outp.layoutManager ensureLayoutForTextContainer:outp.textContainer];
            self.mode = @(3);
        }
        if (sels == 1) {
            self.mode = @(0);
        }
        if (data != nil) {
            [stor beginEditing];
            [stor appendAttributedString:strs];
            [stor endEditing];
            [otxt beginEditing];
            [otxt setAttributedString:[stor copy]];
            [otxt endEditing];
            [outp.layoutManager ensureLayoutForTextContainer:outp.textContainer];
        }
        if (scrl.intValue == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [outp scrollToEndOfDocument:nil];
            });
        }
    } else if (sels == 2) {
        NSTextStorage *stor = [outp textStorage];
        if (data != nil) {
            if (self.mode.intValue < 3) {
                [stor beginEditing];
                [stor setAttributedString:strs];
                int crsr = (didx >> 16), crsc = (didx & 0xffff);
                NSInteger crsi = ((crsr * (cols + 1)) + crsc);
                if (crsi >= 0 && (crsi < stor.length)) {
                    NSRange rang = NSMakeRange(crsi, 1);
                    NSString *targ = [stor.string substringWithRange:rang];
                    NSColor *fill = self.crsc ? self.crsc : [NSColor whiteColor];
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
                self.mode = @(2);
            }
        }
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

- (int)next:(int)iidx dirs:(int)dirs {
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
        [self adjb:self.tabv wide:self.wide.floatValue high:self.high.floatValue mode:0];
        NSButton *tabb = [self.tabs objectAtIndex:iidx];
        [self.tabv removeView:tabb];
        [tabb removeFromSuperview];
        [self next:iidx dirs:0];
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
            [self didChangeCrsColor:self.crsc];
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
    id appDelegate = [NSApp delegate];
    if ([appDelegate respondsToSelector:@selector(makeProc:iidx:vobj:)]) {
        [appDelegate makeProc:@"taba" iidx:NSNotFound vobj:self];
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
    [self.tabv addView:tabb inGravity:NSStackViewGravityCenter];

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

    outp.insertionPointColor = self.crsc;
    outp.wide = chwi;
    outp.high = chhi;
    outp.selc = self.selc;
    outp.sepr = [self.seps copy];

    [oscr setDocumentView:outp];

    NSView *inpv = [[NSView alloc] init];
    inpv.wantsLayer = YES;
    inpv.layer.backgroundColor = self.inpc.CGColor;
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
    inpt.textContainerInset = NSMakeSize(INST, 7.0);
    inpt.delegate = self;
    [self.inpt addObject:inpt];

    inpt.insertionPointColor = self.crsc;
    inpt.wide = chwi;
    inpt.high = chhi;
    inpt.selc = self.selc;
    inpt.sepr = [self.seps copy];

    [iscr setDocumentView:inpt];
    [self.itxt addObject:[[NSTextStorage alloc] init]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewDidScroll:) name:NSViewBoundsDidChangeNotification object:oclp];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:outp];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:inpt];

    [self.crsx addObject:@(0)];
    [self.crsy addObject:@(0)];
    [self.crsz addObject:@(0)];

    [self.ihis addObject:@(ihis)];
    [self.scrp addObject:@(-1)];
    [self.scrl addObject:@(0)];

    if (self.vobj == nil) {
        [self.view addSubview:self.allv];
        self.indx = @(indx);
        self.coni = [inpv.heightAnchor constraintEqualToConstant:ihis];
        self.vobj = self.view;
    }

    [self tabt:@"Tab" indx:indx];
    [self tabf:tabb];
    [self refs];

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

- (void)setTitle:(NSString *)titl {
    self.titl.stringValue = titl;
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
    self.wrap = @0;

    self.remo = [[NSMutableArray alloc] init];

    self.bgdc = [NSColor clearColor];
    self.tabc = [NSColor clearColor];
    self.txtc = [NSColor clearColor];
    self.selc = [NSColor clearColor];
    self.crsc = [NSColor clearColor];
    self.inpc = [NSColor clearColor];
    self.blrs = nil;

    self.font = [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Monaco" size:13.0] toHaveTrait:NSBoldFontMask];
    self.attr = @{ NSFontAttributeName:self.font, NSForegroundColorAttributeName:self.txtc, NSParagraphStyleAttributeName:wrap, };
    self.atrf = @{ NSFontAttributeName:self.font, NSParagraphStyleAttributeName: wrap, };

    self.ihis = [[NSMutableArray alloc] init];
    self.scrp = [[NSMutableArray alloc] init];
    self.scrl = [[NSMutableArray alloc] init];

    self.cons = [[NSMutableArray alloc] init];
    self.cont = [[NSMutableArray alloc] init];
    self.cono = nil;
    self.coni = nil;

    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = self.bgdc.CGColor;

    self.crsx = [[NSMutableArray alloc] init];
    self.crsy = [[NSMutableArray alloc] init];
    self.crsz = [[NSMutableArray alloc] init];

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

    self.diva = [[NSView alloc] init];
    self.diva.wantsLayer = YES;
    self.diva.layer.backgroundColor = self.tabc.CGColor;

    self.divb = [[NSView alloc] init];
    self.divb.wantsLayer = YES;
    self.divb.layer.backgroundColor = self.tabc.CGColor;

    self.divc = [[NSView alloc] init];
    self.divc.wantsLayer = YES;
    self.divc.layer.backgroundColor = self.tabc.CGColor;

    NSRect dimi = NSMakeRect(1.0, 1.0, 1.0, 1.0);
    self.topv = [[NSStackView alloc] initWithFrame:dimi];
    self.topv.distribution = NSStackViewDistributionFill;
    self.topv.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.topv.spacing = 0.0;
    self.topv.edgeInsets = NSEdgeInsetsMake(5.5, 0.0, 0.0, 0.0);
    self.topv.layer.masksToBounds = YES;
    [self.topv setWantsLayer:YES];
    [self.topv setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.topv.layer.backgroundColor = [NSColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:0.90].CGColor;

    self.titl = [NSTextField labelWithString:@"SimpleShell"];
    self.titl.editable = NO;
    self.titl.selectable = NO;
    self.titl.bordered = NO;
    self.titl.drawsBackground = NO;
    self.titl.alignment = NSTextAlignmentCenter;
    self.titl.font = self.font;
    self.titl.textColor = self.txtc;
    [self.topv addView:self.titl inGravity:NSStackViewGravityCenter];

    NSRect dimt = NSMakeRect(1.0, 1.0, 1.0, 1.0);
    self.tabv = [[NSStackView alloc] initWithFrame:dimt];
    self.tabv.distribution = NSStackViewDistributionFill;
    self.tabv.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.tabv.spacing = 4.0;
    self.tabv.wantsLayer = YES;
    self.tabv.layer.masksToBounds = YES;
    self.tabv.edgeInsets = NSEdgeInsetsMake(0.0, INST, 0.0, INST);
    [self.tabv setWantsLayer:YES];
    [self.tabv setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.spcl = [[NSView alloc] init];
    [self.spcl setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.spcl setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];

    self.spcr = [[NSView alloc] init];
    [self.spcr setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.spcr setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];

    NSImageSymbolConfiguration *conf;

    self.butl = [[NSButton alloc] init];
    self.imgl = [NSImage imageWithSystemSymbolName:@"plus.circle.fill" accessibilityDescription:nil];
    conf = [NSImageSymbolConfiguration configurationWithHierarchicalColor:self.txtc];
    self.imgl = [self.imgl imageWithSymbolConfiguration:conf];
    [self.butl setWantsLayer:YES];
    [self.butl setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.butl setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.butl setImagePosition:NSImageOnly];
    [self.butl setBordered:NO];
    [self.butl.widthAnchor constraintEqualToConstant:21.0].active = YES;
    [self.butl.heightAnchor constraintEqualToConstant:21.0].active = YES;
    [self.butl setImage:self.imgl];
    self.butl.target = self;
    self.butl.action = @selector(taba:);
    [self.tabv addView:self.butl inGravity:NSStackViewGravityLeading];
    [self.tabv addView:self.spcl inGravity:NSStackViewGravityLeading];
    [self.butl setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.butl setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];

    self.butr = [[NSButton alloc] init];
    self.imgr = [NSImage imageWithSystemSymbolName:@"slash.circle.fill" accessibilityDescription:nil];
    conf = [NSImageSymbolConfiguration configurationWithHierarchicalColor:self.txtc];
    self.imgr = [self.imgr imageWithSymbolConfiguration:conf];
    [self.butr setWantsLayer:YES];
    [self.butr setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.butr setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.butr setImagePosition:NSImageOnly];
    [self.butr setBordered:NO];
    [self.butr.widthAnchor constraintEqualToConstant:21.0].active = YES;
    [self.butr.heightAnchor constraintEqualToConstant:21.0].active = YES;
    [self.butr setImage:self.imgr];
    self.butr.target = self;
    self.butr.action = @selector(tabc:);
    [self.tabv addView:self.spcr inGravity:NSStackViewGravityTrailing];
    [self.tabv addView:self.butr inGravity:NSStackViewGravityTrailing];
    [self.butr setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.butr setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];

    NSRect dimv = NSMakeRect(1.0, 1.0, 1.0, 1.0);
    self.allv = [[NSStackView alloc] initWithFrame:dimv];
    self.allv.distribution = NSStackViewDistributionFill;
    self.allv.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.allv.spacing = 0.0;
    self.allv.layer.masksToBounds = YES;
    [self.allv setWantsLayer:YES];
    [self.allv setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.allv setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationVertical];

    self.sttv = [[NSStackView alloc] initWithFrame:NSZeroRect];
    self.sttv.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.sttv.distribution = NSStackViewDistributionFillEqually;
    self.sttv.spacing = 9.0;
    self.sttv.edgeInsets = NSEdgeInsetsMake(3.0, INST, 3.0, INST);
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
    [self.sttv addView:self.cpuv inGravity:NSStackViewGravityCenter];

    self.ramv = [NSTextField labelWithString:@"RAM: 0.0%"];
    configureLabel(self.ramv);
    [self.sttv addView:self.ramv inGravity:NSStackViewGravityCenter];

    self.netv = [NSTextField labelWithString:@"NET: In: 0B/s • Out: 0B/s"];
    configureLabel(self.netv);
    [self.sttv addView:self.netv inGravity:NSStackViewGravityCenter];

    self.srcs = @0;
    self.sidx = @-1;

    self.srcv = [[NSStackView alloc] initWithFrame:NSZeroRect];
    self.srcv.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.srcv.distribution = NSStackViewDistributionFill;
    self.srcv.spacing = 9.0;
    self.srcv.edgeInsets = NSEdgeInsetsMake(3.0, INST, 3.0, INST);
    self.srcv.translatesAutoresizingMaskIntoConstraints = NO;

    self.srct = [[NSTextField alloc] init];
    self.srct.placeholderString = @"Find";
    self.srct.font = self.font;
    self.srct.bordered = NO;
    self.srct.bezeled = NO;
    self.srct.bezelStyle = NSTextFieldSquareBezel;
    self.srct.backgroundColor = [NSColor clearColor];
    self.srct.focusRingType = NSFocusRingTypeNone;
    self.srct.delegate = self;
    self.srct.target = self;
    self.srct.action = @selector(findNext:);
    [self.srct setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];

    NSButton *prev = [NSButton buttonWithTitle:@"Back" target:self action:@selector(findPrev:)];
    prev.bordered = NO;

    NSButton *next = [NSButton buttonWithTitle:@"Next" target:self action:@selector(findNext:)];
    next.bordered = NO;

    NSButton *done = [NSButton buttonWithTitle:@"Done" target:self action:@selector(findDone:)];
    done.bordered = NO;

    NSView *srcs = [[NSView alloc] init];
    srcs.translatesAutoresizingMaskIntoConstraints = NO;
    [srcs setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];

    [self.srcv addView:self.srct inGravity:NSStackViewGravityLeading];
    [self.srcv addView:prev inGravity:NSStackViewGravityLeading];
    [self.srcv addView:next inGravity:NSStackViewGravityLeading];
    [self.srcv addView:done inGravity:NSStackViewGravityLeading];
    [self.srcv addView:srcs inGravity:NSStackViewGravityTrailing];
    [prev.widthAnchor constraintEqualToConstant:50].active = YES;
    [next.widthAnchor constraintEqualToConstant:50].active = YES;

    self.refr = [NSTimer scheduledTimerWithTimeInterval:1.357 target:self selector:@selector(refv:) userInfo:nil repeats:YES];
}

@end
