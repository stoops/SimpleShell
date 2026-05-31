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

#define DIVH   3.33
#define INSH   7.00
#define INSW  13.00
#define INSV -13.00
#define PADH  15.00
#define TABH  31.33
#define TABO   5.55
#define TWOV   1.99
#define OPAT   0.19
#define RADI   5.99
#define KERN   0.39

#define SIZE 23.0
#define PLUS @"plus.circle"
#define CLOS @"slash.circle"

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
        long tagn = btn.tag;
        if (tagn < 1) { continue; }
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
    [self sets:@"tabd" wide:0.0 high:0.0];

    for (int x = 0; x < [self.tabl count]; ++x) {
        long tagn = [self.tabl objectAtIndex:x].tag;
        if (tagn < 1) { continue; }
        [self tabt:@"Tab" indx:((int)tagn)];
    }
}

- (void)didChangeBarColor:(NSColor *)color {
    self.topv.layer.backgroundColor = self.barc.CGColor;
}

- (void)didChangeBgdColor:(NSColor *)color {
    self.view.layer.backgroundColor = self.bgdc.CGColor;
}

- (void)didChangeTabColor:(NSColor *)color {
    self.diva.layer.backgroundColor = self.tabc.CGColor;
    self.divb.layer.backgroundColor = self.tabc.CGColor;
    self.divc.layer.backgroundColor = self.tabc.CGColor;
    for (NSButton *tabb in self.tabs) {
        tabb.layer.borderColor = self.tabc.CGColor;
        tabb.layer.backgroundColor = self.tabc.CGColor;
    }
}

- (void)didChangeTxtColor:(NSColor *)color {
    self.atrf = @{ NSFontAttributeName:self.font, NSKernAttributeName:@(KERN), NSForegroundColorAttributeName:self.txtc, NSParagraphStyleAttributeName:[self wrap:1], };
    self.atrc = @{ NSFontAttributeName:self.fiot, NSForegroundColorAttributeName:self.txtc, NSParagraphStyleAttributeName:[self wrap:0], };
    self.attr = @{ NSFontAttributeName:self.fiot, NSParagraphStyleAttributeName:[self wrap:0], };
    for (NSButton *tb in self.tabs) {
        [self colt:tb];
    }
    for (NSTextView *tv in self.outp) {
        tv.textColor = self.txtc;
    }
    for (NSTextView *tv in self.inpt) {
        tv.textColor = self.txtc;
    }
    self.titl.attributedStringValue = [[NSAttributedString alloc] initWithString:self.titl.stringValue attributes:self.atrf];
    self.titi.attributedStringValue = [[NSAttributedString alloc] initWithString:self.titi.stringValue attributes:self.atrf];
    self.cpuv.attributedStringValue = [[NSAttributedString alloc] initWithString:self.cpuv.stringValue attributes:self.atrf];
    self.ramv.attributedStringValue = [[NSAttributedString alloc] initWithString:self.ramv.stringValue attributes:self.atrf];
    self.netv.attributedStringValue = [[NSAttributedString alloc] initWithString:self.netv.stringValue attributes:self.atrf];
    self.srct.attributedStringValue = [[NSAttributedString alloc] initWithString:self.srct.stringValue attributes:self.atrf];
    self.srcf.attributedStringValue = [[NSAttributedString alloc] initWithString:self.srcf.stringValue attributes:self.atrf];
    self.srcp.contentTintColor = self.txtc;
    self.srcn.contentTintColor = self.txtc;
    self.srcc.contentTintColor = self.txtc;
    self.srcd.contentTintColor = self.txtc;
}

- (void)didChangeSelColor:(NSColor *)color {
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
            NSWindow *wi = ct.window;
            if (wi) {
                [wi makeKeyWindow];
                [wi makeFirstResponder:nil];
                [wi makeFirstResponder:ct];
            }
            [ct setNeedsDisplay:YES];
        }
    }
}

- (void)didChangeCrsColor:(NSColor *)color {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSTextView *tv in self.inpt) {
            if ([tv isKindOfClass:[CursorText class]]) {
                CursorText *ct = (CursorText *)tv;
                ct.insertionPointColor = self.crsc;
                if (ct.layoutManager) {
                    [ct.layoutManager invalidateDisplayForCharacterRange:NSMakeRange(0, ct.string.length)];
                }
                NSWindow *wi = ct.window;
                if (wi) {
                    [wi makeKeyWindow];
                    [wi makeFirstResponder:nil];
                    [wi makeFirstResponder:ct];
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
    for (NSView *inpView in self.inpv) {
        inpView.layer.backgroundColor = self.inpc.CGColor;
    }
}

- (void)didChangeBtnColor:(NSColor *)color {
    NSImageSymbolConfiguration *conf;
    NSArray<NSColor *> *clrs = @[self.txtc, self.tabc];
    conf = [NSImageSymbolConfiguration configurationWithPaletteColors:clrs];
    self.imgl = [self.imgl imageWithSymbolConfiguration:conf];
    [self.butl setImage:self.imgl];
    conf = [NSImageSymbolConfiguration configurationWithPaletteColors:clrs];
    self.imgr = [self.imgr imageWithSymbolConfiguration:conf];
    [self.butr setImage:self.imgr];
}

- (void)didChangeTxtFont:(NSFont *)font {
    self.atrf = @{ NSFontAttributeName:self.font, NSKernAttributeName:@(KERN), NSForegroundColorAttributeName:self.txtc, NSParagraphStyleAttributeName:[self wrap:1], };
    self.atrc = @{ NSFontAttributeName:self.fiot, NSForegroundColorAttributeName:self.txtc, NSParagraphStyleAttributeName:[self wrap:0], };
    self.attr = @{ NSFontAttributeName:self.fiot, NSParagraphStyleAttributeName:[self wrap:0], };
    for (NSButton *tb in self.tabs) {
        tb.font = self.font;
    }
    for (NSTextView *tv in self.outp) {
        tv.font = self.fiot;
    }
    for (NSTextView *tv in self.inpt) {
        tv.font = self.fiot;
    }
    self.titl.attributedStringValue = [[NSAttributedString alloc] initWithString:self.titl.stringValue attributes:self.atrf];
    self.titi.attributedStringValue = [[NSAttributedString alloc] initWithString:self.titi.stringValue attributes:self.atrf];
    self.cpuv.attributedStringValue = [[NSAttributedString alloc] initWithString:self.cpuv.stringValue attributes:self.atrf];
    self.ramv.attributedStringValue = [[NSAttributedString alloc] initWithString:self.ramv.stringValue attributes:self.atrf];
    self.netv.attributedStringValue = [[NSAttributedString alloc] initWithString:self.netv.stringValue attributes:self.atrf];
    self.srct.attributedStringValue = [[NSAttributedString alloc] initWithString:self.srct.stringValue attributes:self.atrf];
    self.srcf.attributedStringValue = [[NSAttributedString alloc] initWithString:self.srcf.stringValue attributes:self.atrf];
    self.srcp.font = self.font;
    self.srcn.font = self.font;
    self.srcc.font = self.font;
    self.srcd.font = self.font;
}

- (void)didChangeBlrSlider:(CGFloat)factor {
    self.fact = @(factor);
    [self blur];

    //NSLog(@"BLUR [%f]", self.fact.doubleValue);

    if (self.fact.doubleValue <= 0.001) {
        self.blrs.layer.backgroundFilters = nil;
        self.blrs.layer.backgroundColor = [NSColor clearColor].CGColor;
        self.olay.layer.backgroundFilters = nil;
        self.olay.layer.backgroundColor = [NSColor clearColor].CGColor;
        [self.blrs removeFromSuperview];
        return;
    }

    CGFloat calcRadis = (199.0 - (self.fact.doubleValue * 199.0));
    CGFloat calcAlpha = (0.05 + (0.15 * self.fact.doubleValue));
    CIFilter *blurFiltr = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFiltr setDefaults];
    [blurFiltr setValue:@(calcRadis) forKey:@"inputRadius"];
    self.olay.backgroundFilters = @[blurFiltr];
    self.olay.layer.backgroundColor = [self.bgdc colorWithAlphaComponent:calcAlpha].CGColor;
    //self.olay.layer.backgroundColor = [[NSColor whiteColor] colorWithAlphaComponent:calculatedAlpha].CGColor;

    if (![self.view.subviews containsObject:self.blrs]) {
        self.blrs.frame = self.view.bounds;
        [self.view addSubview:self.blrs positioned:NSWindowBelow relativeTo:nil];
    }
}

- (void)blur {
    if (self.blrs != nil) { return; }

    self.blrs = [[NSView alloc] initWithFrame:self.view.bounds];
    self.blrs.wantsLayer = YES;
    self.blrs.layer.masksToBounds = YES;
    self.blrs.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    self.glas = [[NSVisualEffectView alloc] initWithFrame:self.view.bounds];
    self.glas.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.glas.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    self.glas.material = NSVisualEffectMaterialUnderWindowBackground;
    self.glas.state = NSVisualEffectStateFollowsWindowActiveState;
    //self.glas.state = NSVisualEffectStateInactive;
    //self.glas.state = NSVisualEffectStateActive;

    self.olay = [[NSView alloc] initWithFrame:self.glas.bounds];
    self.olay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.olay.wantsLayer = YES;
    self.olay.layer.masksToBounds = YES;
    self.olay.layer.backgroundColor = [[NSColor whiteColor] colorWithAlphaComponent:0.05].CGColor;

    [self.glas addSubview:self.olay];
    [self.blrs addSubview:self.glas];
}

- (void)sepr {
    if (self.seps != nil) { return; }
    NSString *sepString = [[NSUserDefaults standardUserDefaults] stringForKey:@"seps"] ?: @"";
    NSMutableCharacterSet *sepSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [sepSet addCharactersInString:sepString];
    self.seps = sepSet;
}

- (NSMutableParagraphStyle *)wrap:(int)mode {
    NSMutableParagraphStyle *wrap = [[NSMutableParagraphStyle alloc] init];
    wrap.lineBreakMode = NSLineBreakByCharWrapping;
    wrap.alignment = (mode == 0) ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    return wrap;
}

- (void)refc:(int)mode {
    NSLog(@"REFC");
    [self didChangeBarColor:self.barc];
    [self didChangeBgdColor:self.bgdc];
    [self didChangeTabColor:self.tabc];
    [self didChangeTxtColor:self.txtc];
    [self didChangeSelColor:self.selc];
    [self didChangeCrsColor:self.crsc];
    [self didChangeInpColor:self.inpc];
    [self didChangeBtnColor:self.txtc];
    [self didChangeBlrSlider:self.fact.doubleValue];
    [self didChangeTxtFont:nil];
}

- (void)refs:(NSString *)pref mode:(int)mode rsiz:(int)rsiz wide:(CGFloat)wide high:(CGFloat)high {
    NSLog(@"REFS [%d] [%d] [%d]", self.indx.intValue, mode, rsiz);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (mode == 1) {
            [self refc:mode];
        }
        if (self.vobj != nil) {
            int iidx = (self.indx.intValue - 1);
            if ((-1 < iidx) && (iidx < [self.tabs count])) {
                NSScrollView *oscr = [self.oscr objectAtIndex:iidx];
                NSView *inpv = [self.inpv objectAtIndex:iidx];
                NSTextView *inpt = [self.inpt objectAtIndex:iidx];
                NSTextView *outp = [self.outp objectAtIndex:iidx];
                NSNumber *scrl = [self.scrl objectAtIndex:iidx];
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
                [self sets:pref wide:wide high:high];
                [self layo:pref data:nil indx:iidx inpt:inpt outp:outp scrl:scrl lidx:8000];
                if ((1 < rsiz) && (rsiz < 9)) {
                    if (self.view.window != nil) {
                        id appd = [NSApplication sharedApplication].delegate;
                        NSNotification *note = [NSNotification notificationWithName:NSWindowDidResizeNotification object:self.view.window];
                        [appd windowDidEndLiveResize:note];
                        [self.view.window makeFirstResponder:inpt];
                    }
                }
                [self.view setNeedsDisplay:YES];
            }
        }
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

- (void)findText:(int)dirs {
    self.srcf.stringValue = @"";

    NSString *sstr = self.srct.stringValue;
    if ([sstr length] == 0) { return; }

    int iidx = (self.indx.intValue - 1);
    if ((iidx < 0) || (iidx >= [self.outp count])) { return; }

    NSTextView *outp = [self.outp objectAtIndex:iidx];
    NSString *outt = outp.string;
    if ([outt length] == 0) { return; }

    [outp.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, [outt length])];

    NSError *erro = nil;
    NSRegularExpression *regx = [NSRegularExpression regularExpressionWithPattern:sstr options:NSRegularExpressionCaseInsensitive error:&erro];
    if (erro) {
        return;
    }

    NSMutableArray<NSValue *> *mach = [NSMutableArray array];
    NSArray<NSTextCheckingResult *> *mrgx = [regx matchesInString:outt options:0 range:NSMakeRange(0, [outt length])];
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

    NSString *tstr = [NSString stringWithFormat:@"%d / %ld", self.sidx.intValue + 1, [mach count]];
    self.srcf.attributedStringValue = [[NSAttributedString alloc] initWithString:tstr attributes:self.atrf];

    NSRange rrng = [mach[self.sidx.intValue] rangeValue];
    [outp setSelectedRange:rrng];
    [outp scrollRangeToVisible:rrng];

    if (self.selc) {
        [outp.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:self.selc forCharacterRange:rrng];
        [outp.window makeFirstResponder:outp];
    }

    NSLog(@"FIND [%d][%ld]", self.sidx.intValue, [mach count]);
}

- (void)findPrev:(id)sender {
    [self findText:-1];
}

- (void)findNext:(id)sender {
    [self findText:1];
}

- (void)findCopy:(id)sender {
    NSString *sstr = self.srct.stringValue;
    if ([sstr length] == 0) { return; }

    int iidx = (self.indx.intValue - 1);
    if ((iidx < 0) || (iidx >= [self.outp count])) { return; }

    NSTextView *outp = [self.outp objectAtIndex:iidx];
    NSString *outt = outp.string;
    if ([outt length] == 0) { return; }

    NSError *erro = nil;
    NSRegularExpression *regx = [NSRegularExpression regularExpressionWithPattern:sstr options:NSRegularExpressionCaseInsensitive error:&erro];
    if (erro) {
        NSBeep();
        return;
    }

    NSArray<NSTextCheckingResult *> *mrgx = [regx matchesInString:outt options:0 range:NSMakeRange(0, [outt length])];
    if ([mrgx count] == 0) {
        NSBeep();
        return;
    }

    NSMutableArray<NSString *> *hist = [NSMutableArray array];
    NSMutableIndexSet *idxs = [NSMutableIndexSet indexSet];

    for (NSTextCheckingResult *match in mrgx) {
        NSRange rang = [outt lineRangeForRange:match.range];
        if (![idxs intersectsIndexesInRange:rang]) {
            [idxs addIndexesInRange:rang];
            NSString *strl = [outt substringWithRange:rang];
            while ([strl hasSuffix:@"\n"] || [strl hasSuffix:@"\r"]) {
                strl = [strl substringToIndex:strl.length - 1];
            }
            [hist addObject:strl];
        }
    }

    if ([hist count] > 0) {
        NSString *join = [[hist componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
        NSPasteboard *pbrd = [NSPasteboard generalPasteboard];
        [pbrd clearContents];
        [pbrd writeObjects:@[join]];
        NSLog(@"COPY FIND [%ld]", [hist count]);
    }
}

- (void)findDone:(id)sender {
    [self find];
}

- (void)find {
    if (self.srcs.intValue == 0) {
        self.srcs = @(1);
    } else {
        self.srcs = @(0);
        self.sidx = @(-1);
        self.srct.stringValue = @"";
        self.srcf.stringValue = @"";
        int iidx = (self.indx.intValue - 1);
        if ((-1 < iidx) && (iidx < [self.outp count])) {
            NSTextView *outp = [self.outp objectAtIndex:iidx];
            NSString *outt = outp.string;
            [outp.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, outt.length)];
            [outp setSelectedRange:NSMakeRange(0, 0)];
        }
    }
    [self refs:@"find" mode:0 rsiz:8 wide:0.0 high:0.0];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (control == self.srct) {
        if (commandSelector == @selector(cancelOperation:)) {
            [self find];
            return YES;
        }
        if (commandSelector == @selector(insertNewline:)) {
            NSRange rang = NSMakeRange(textView.string.length, 0);
            [textView setSelectedRange:rang];
            [self findText:1];
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
                } else if (cKey && rKey) {
                    [self findText:-1];
                    return YES;
                } else {
                    [self find];
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)refrLoop:(NSTimer *)timer {
    if ((self.vobj == nil) || (self.indx.intValue < 1)) { return; }
    if ((NSApp.isActive) && (self.view.window) && (self.view.window.isKeyWindow)) {
        [self show:@"refr" data:nil prom:nil indx:self.indx.intValue sels:0 cidx:-1 rows:self.rows.intValue cols:self.cols.intValue];
    }
}

- (void)winrLoop:(NSTimer *)timer {
    NSString *titi = @"noop";
    for (int x = 0; x < [self.titz count]; ++x) {
        NSArray *item = [self.titz objectAtIndex:x];
        NSString *info = [item objectAtIndex:0];
        NSNumber *time = [item objectAtIndex:1];
        NSNumber *indx = [item objectAtIndex:2];
        if (([info length] > 0) && ((indx.intValue < 0) || (indx.intValue == self.indx.intValue))) {
            titi = [info copy];
            if (time.intValue < 1) {
                [self.titz replaceObjectAtIndex:x withObject:@[@"", @0, @0]];
            }
            break;
        }
    }
    NSString *tstr = [NSString stringWithFormat:@"[%@]", titi];
    self.titi.attributedStringValue = [[NSAttributedString alloc] initWithString:tstr attributes:self.atrf];
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
    CGFloat chwi = [self.fiot advancementForGlyph:[self.fiot glyphWithName:@"x"]].width;
    CGFloat chhi = ((self.fiot.ascender + fabs(self.fiot.descender)) + self.fiot.leading);
    //NSLog(@"FONT [%c] [%f][%f]", kind, chwi, chhi);
    if (kind == 'w') {
        return MAX( 4.0, chwi);
    } else {
        return MAX(12.0, chhi);
    }
}

- (void)adjb:(NSStackView *)tabv mode:(int)mode {
    int tabc = 0;
    for (int x = 0; x < [self.tabs count]; ++x) {
        long tagn = [self.tabs objectAtIndex:x].tag;
        if (tagn < 1) { continue; }
        ++tabc;
    }

    [NSLayoutConstraint deactivateConstraints:self.cont];
    [self.cont removeAllObjects];

    NSButton *last = nil;
    for (int x = 0; x < [self.tabs count]; ++x) {
        NSButton *tabb = [self.tabs objectAtIndex:x];
        long tagn = tabb.tag;
        if (tagn < 1) { continue; }
        NSColor *back = [self.tabc colorWithAlphaComponent:OPAT];
        if (self.indx.intValue == tabb.tag) {
            [tabb.layer setBorderColor:self.tabc.CGColor];
            [tabb.layer setBackgroundColor:self.tabc.CGColor];
        } else {
            [tabb.layer setBorderColor:back.CGColor];
            [tabb.layer setBackgroundColor:back.CGColor];
        }
        CGFloat zpad = (0.01 + 0.50);
        CGFloat btal = (TABH - TABO);
        NSLayoutConstraint *bcon = [tabb.bottomAnchor constraintEqualToAnchor:self.tabv.bottomAnchor constant:-zpad];
        bcon.priority = NSLayoutPriorityDefaultHigh - 1;
        [self.cont addObject:bcon];
        NSLayoutConstraint *hcon = [tabb.heightAnchor constraintEqualToConstant:btal];
        hcon.priority = NSLayoutPriorityDefaultHigh - 1;
        [self.cont addObject:hcon];
        if (last != nil) {
            NSLayoutConstraint *tcon = [tabb.widthAnchor constraintEqualToAnchor:last.widthAnchor];
            tcon.priority = NSLayoutPriorityDefaultHigh - 1;
            [self.cont addObject:tcon];
        }
        last = tabb;
    }

    CGFloat zpad = (((TABH - TABO) / TWOV) + 1.35);
    NSLayoutConstraint *lcon = [self.butl.centerYAnchor constraintEqualToAnchor:self.tabv.bottomAnchor constant:-zpad];
    [self.cont addObject:lcon];
    NSLayoutConstraint *rcon = [self.butr.centerYAnchor constraintEqualToAnchor:self.tabv.bottomAnchor constant:-zpad];
    [self.cont addObject:rcon];

    [NSLayoutConstraint activateConstraints:self.cont];
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

            CGFloat pahi = PADH;
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
                }
                if (inpt.layoutManager) {
                    [inpt.layoutManager invalidateDisplayForCharacterRange:NSMakeRange(0, inpt.textStorage.length)];
                }
            });
        }
    }
}

- (int)sets:(NSString *)pref wide:(CGFloat)wide high:(CGFloat)high {
    if (self.vobj != nil) {
        int iidx = (self.indx.intValue - 1);

        if ((-1 < iidx) && (iidx < [self.tabs count])) {
            if (wide > 5.0) {
                self.wide = @(wide);
                self.high = @(high);
                self.fntw = @([self tell:'w' indx:0]);
                self.fnth = @([self tell:'h' indx:0]);
            } else {
                wide = self.wide.floatValue;
                high = self.high.floatValue;
            }

            NSView *view = self.view;
            NSView *topv = self.topv;
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
            if (self.conh != nil) {
                [NSLayoutConstraint deactivateConstraints:self.conh];
                self.conh = nil;
            }
            if (self.conw != nil) {
                [NSLayoutConstraint deactivateConstraints:self.conw];
                self.conw = nil;
            }

            NSMutableArray<NSLayoutConstraint *> *conw = [@[
                [topv.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
                [topv.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],

                [tabv.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
                [tabv.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],

                [allv.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
                [allv.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],

                [iscr.leadingAnchor constraintEqualToAnchor:inpv.leadingAnchor constant:0.0],
                [iscr.trailingAnchor constraintEqualToAnchor:inpv.trailingAnchor constant:0.0],

                [oscr.leadingAnchor constraintEqualToAnchor:allv.leadingAnchor constant:INSW],
                [oscr.trailingAnchor constraintEqualToAnchor:allv.trailingAnchor constant:INSV],

                [self.titi.trailingAnchor constraintEqualToAnchor:topv.trailingAnchor constant:-(INSW+TWOV)],
                [self.titl.centerXAnchor constraintEqualToAnchor:topv.centerXAnchor],

                [self.diva.widthAnchor constraintEqualToAnchor:allv.widthAnchor multiplier:0.9900],
                [self.divb.widthAnchor constraintEqualToAnchor:allv.widthAnchor multiplier:0.9900],
                [self.divc.widthAnchor constraintEqualToAnchor:allv.widthAnchor multiplier:0.9900],

                [self.spcl.widthAnchor constraintEqualToConstant:9.99],
                [self.spcl.widthAnchor constraintEqualToAnchor:self.spcr.widthAnchor],
            ] mutableCopy];

            NSMutableArray<NSLayoutConstraint *> *conh = [@[
                [topv.heightAnchor constraintEqualToConstant:31.0],

                [tabv.heightAnchor constraintEqualToConstant:TABH],

                [allv.topAnchor constraintEqualToAnchor:view.topAnchor],
                [allv.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],

                [iscr.topAnchor constraintEqualToAnchor:inpv.topAnchor constant:0.0],
                [iscr.bottomAnchor constraintEqualToAnchor:inpv.bottomAnchor constant:0.0],

                [self.titl.centerYAnchor constraintEqualToAnchor:topv.centerYAnchor],
                [self.titi.centerYAnchor constraintEqualToAnchor:topv.centerYAnchor],

                [self.diva.heightAnchor constraintEqualToConstant:DIVH],
                [self.divb.heightAnchor constraintEqualToConstant:DIVH],
                [self.divc.heightAnchor constraintEqualToConstant:DIVH],
            ] mutableCopy];

            if (self.coni != nil) {
                [conh addObject:self.coni];
            }

            if (self.srcs.intValue != 0) {
                NSLayoutConstraint *srcw = [self.srct.widthAnchor constraintEqualToConstant:(wide * 0.33)];
                [conw addObject:srcw];
                NSLayoutConstraint *srch = [self.srcv.heightAnchor constraintEqualToConstant:barh];
                [conh addObject:srch];
            }

            if (self.stts.intValue != 0) {
                NSLayoutConstraint *sttw = [self.sttv.widthAnchor constraintEqualToConstant:mulw];
                [conw addObject:sttw];
                NSLayoutConstraint *stth = [self.sttv.heightAnchor constraintEqualToConstant:barh];
                [conh addObject:stth];
            }

            for (NSLayoutConstraint *constraint in conw) {
                constraint.priority = NSLayoutPriorityDefaultHigh - 1;
            }
            self.conw = [conw mutableCopy];
            for (NSLayoutConstraint *constraint in conh) {
                constraint.priority = NSLayoutPriorityDefaultHigh - 1;
            }
            self.conh = [conh mutableCopy];

            NSLayoutConstraint *lock = [tabv.widthAnchor constraintLessThanOrEqualToConstant:wide];
            lock.priority = NSLayoutPriorityRequired;
            lock.active = YES;
            [self adjb:tabv mode:0];
            [NSLayoutConstraint activateConstraints:self.conw];
            [NSLayoutConstraint activateConstraints:self.conh];
            [self adjb:tabv mode:1];
            [self adjt:iidx];
            [view layoutSubtreeIfNeeded];
            lock.active = NO;

            NSLog(@"SETS [%@] [%d] [%f][%f]", pref, iidx, wide, self.view.frame.size.width);
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

- (void)controlTextDidChange:(NSNotification *)notification {
    if (notification.object == self.srct) {
        self.sidx = @(-1);
        [self findText:1];
    }
}

- (void)windowResignedKey:(NSNotification *)notification {
    NSLog(@"VIEW BACK");
}

- (void)windowBecameKey:(NSNotification *)notification {
    NSLog(@"VIEW MAIN");
}

- (void)layo:(NSString *)pref data:(NSAttributedString *)data indx:(int)indx inpt:(NSTextView *)inpt outp:(NSTextView *)outp scrl:(NSNumber *)scrl lidx:(int)lidx {
    if (lidx != 0) {
        self.lidx = @(self.indx.intValue);
        self.lmod = @(self.mode.intValue);
    }
    CursorText *inpc = (CursorText *)inpt;
    NSUInteger maxl = inpt.string.length;
    NSRange rang = (inpc.rang.length > 0) ? inpc.rang : inpt.selectedRange;
    if ((rang.location != NSNotFound) && (rang.length > 0) && (rang.location < maxl)) {
        if (NSMaxRange(rang) > maxl) {
            rang.length = (maxl - rang.location);
        }
        [inpc applyHighlightToRange:rang];
        inpc.rang = rang;
    }
    NSNotification *noti = [NSNotification notificationWithName:@"textDidChange" object:inpt];
    [self textDidChange:noti];
    if (scrl.intValue == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [outp scrollToEndOfDocument:nil];
        });
    }
}

- (NSMutableAttributedString *)tran:(NSMutableAttributedString *)inpt iidx:(int)iidx plen:(int)plen ilen:(int)ilen crow:(int)crow ccol:(int)ccol {
    int rows = self.rows.intValue;
    int cols = self.cols.intValue;
    int wrap = self.wrap.intValue;
    int slen = ((int)[inpt length]);
    int rlen = ((ilen / cols) + 1);
    int rbeg = MAX(0, rows - rlen);
    int idxr = MAX(0, crow - rbeg);
    int idxt = ((idxr * cols) + ccol);
    int idxc = (plen + idxt);
    int widx = 0;
    for (int x = 0; x < slen; ++x) {
        if ((widx > 0) && ((widx % (wrap - 2)) == 0)) {
            if (x == (slen - 1)) {
                NSAttributedString *prea = [[NSAttributedString alloc] initWithString:@"\u2193\u203A" attributes:self.atrc];
                [inpt insertAttributedString:prea atIndex:(x + 1)];
                if ((x + 1) <= idxc) { idxc += 2; }
                x += 2; slen += 2;
            } else {
                NSAttributedString *prea = [[NSAttributedString alloc] initWithString:@" " attributes:self.atrc];
                [inpt insertAttributedString:prea atIndex:(x + 1)];
                if ((x + 1) <= idxc) { idxc += 1; }
                x += 1; slen += 1;
            }
            widx = 0;
        } else {
            ++widx;
        }
    }
    int drow = (idxc / wrap);
    int dcol = (idxc % wrap);
    int dlen = ((slen / wrap) + 1);
    int dbeg = MAX(0, rows - dlen);
    int rowd = MIN(rows - 1, dbeg + drow);
    int cold = dcol;
    //NSLog(@"TRAN [pre-len=%d][str-len=%d] [old-len:%d][new-len=%d] [old-beg:%d][new-beg:%d] [old-idx:%d][new-idx:%d] [old-num:%d][new-num:%d] [old-row:%d][old-col:%d] [inp-row:%d][inp-col:%d] [new-row:%d][new-col:%d] [%d][%@]", plen, slen, rlen, dlen, rbeg, dbeg, idxt, idxc, idxr, -1, crow, ccol, drow, dcol, rowd, cold, wrap, inpt.string);
    int eidx = ((rowd << 16) | cold);
    [self.crsx replaceObjectAtIndex:iidx withObject:@(eidx)];
    int fidx = ((drow << 16) | dcol);
    [self.crsz replaceObjectAtIndex:iidx withObject:@(fidx)];
    return inpt;
}

- (int)show:(NSString *)pref data:(NSAttributedString *)data prom:(NSString *)prom indx:(int)indx sels:(int)sels cidx:(int)cidx rows:(int)rows cols:(int)cols {
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
        if (sels != 0) { didx = [self.crsy objectAtIndex:iidx].intValue; }
    } else {
        if (sels == 0) { [self.crsx replaceObjectAtIndex:iidx withObject:@(didx)]; }
        if (sels != 0) { [self.crsy replaceObjectAtIndex:iidx withObject:@(didx)]; }
    }

    if (([self.tabs count] < 1) || (iidx < 0) || ([self.tabs count] <= iidx)) {
        NSLog(@"ERRO show");
        return 0;
    }

    NSTextView *inpt = [self.inpt objectAtIndex:iidx];
    NSTextView *outp = [self.outp objectAtIndex:iidx];
    NSTextStorage *itxt = [self.itxt objectAtIndex:iidx];
    NSTextStorage *otxt = [self.otxt objectAtIndex:iidx];
    NSNumber *scrl = [self.scrl objectAtIndex:iidx];
    CursorText *inpc = (CursorText *)inpt;
    CursorText *outc = (CursorText *)outp;

    int jidx = (self.indx.intValue - 1);
    CGFloat fntw = self.fntw.floatValue;
    CGFloat fnth = self.fnth.floatValue;

    self.wrap = @(cols - 1);

    int wrap = self.wrap.intValue;
    int crow = (didx >> 16), ccol = (didx & 0xffff);
    inpt.textContainer.containerSize = NSMakeSize(wrap * fntw, CGFLOAT_MAX);

    //NSLog(@"SHOW [%@] [%d][%d] [%d] [%f][%f] [%d][%d] [%d] [%d] [%d][%d] [%ld][%@]",text,iidx,jidx,sels,fntw,fnth,rows,cols,wrap,cidx,crow,ccol, (data == nil) ? -1 : [data length], (data == nil) ? @"" : data.string);

    int lidx = 0;
    if (self.indx.intValue != self.lidx.intValue) {
        lidx += (1 * 1);
    }
    if (self.mode.intValue != self.lmod.intValue) {
        lidx += (2 * 10);
    }

    if (sels == 0) {
        NSMutableAttributedString *strs = (data != nil) ? [data mutableCopy] : [itxt mutableCopy];
        [strs addAttributes:self.attr range:NSMakeRange(0, [strs length])];
        if ((data != nil) || (lidx != 0)) {
            NSTextStorage *stor = [inpt textStorage];
            int ilen = ((int)[strs.string length]);
            int plen = 0;
            if ((prom != nil) && ([prom length] > 0)) {
                NSString *magi = @"%p";
                NSRange rang = [strs.string rangeOfString:magi];
                NSAttributedString *prea = [[NSAttributedString alloc] initWithString:prom attributes:self.atrc];
                if (rang.location != NSNotFound) {
                    [strs replaceCharactersInRange:rang withAttributedString:prea];
                    plen += (prom.length - rang.length);
                } else {
                    [strs insertAttributedString:prea atIndex:0];
                    plen += [prom length];
                }
            }
            strs = [self tran:strs iidx:iidx plen:plen ilen:ilen crow:crow ccol:ccol];
            [stor beginEditing];
            [stor setAttributedString:strs];
            [stor endEditing];
            [itxt beginEditing];
            [itxt setAttributedString:[stor copy]];
            [itxt endEditing];
            [inpc drawCursor:self.mode.intValue cidx:[self.crsz objectAtIndex:iidx].intValue fntw:fntw fnth:fnth insx:INSW insy:INSH];
        }
        if (iidx == jidx) {
            [self layo:@"show" data:data indx:iidx inpt:inpt outp:outp scrl:scrl lidx:lidx];
        }
    } else if ((sels == 1) || (sels == 8) || (sels == 9)) {
        NSMutableAttributedString *strs = (data != nil) ? [data mutableCopy] : [[NSMutableAttributedString alloc] init];
        [strs addAttributes:self.attr range:NSMakeRange(0, [strs length])];
        NSTextStorage *stor = [outp textStorage];
        if (sels == 9) {
            [stor beginEditing];
            [stor deleteCharactersInRange:NSMakeRange(0, stor.length)];
            [stor endEditing];
            [otxt beginEditing];
            [otxt deleteCharactersInRange:NSMakeRange(0, otxt.length)];
            [otxt endEditing];
            [outp.layoutManager ensureLayoutForTextContainer:outp.textContainer];
            self.mode = @(sels);
        }
        if (sels == 8) {
            NSAttributedString *cche = [otxt attributedSubstringFromRange:NSMakeRange(0, [otxt length])];
            [stor beginEditing];
            [stor setAttributedString:cche];
            [stor endEditing];
            [outp.layoutManager ensureLayoutForTextContainer:outp.textContainer];
            self.mode = @(sels);
        }
        if (sels == 1) {
            if (self.mode.intValue != 2) {
                [stor beginEditing];
                [stor appendAttributedString:strs];
                [stor endEditing];
                [otxt beginEditing];
                [otxt setAttributedString:[stor copy]];
                [otxt endEditing];
                [outp.layoutManager ensureLayoutForTextContainer:outp.textContainer];
                self.mode = @(sels);
                if (iidx == jidx) {
                    [self layo:@"show" data:data indx:iidx inpt:inpt outp:outp scrl:scrl lidx:lidx];
                }
            }
        }
    } else if (sels > 1) {
        NSMutableAttributedString *strs = (data != nil) ? [data mutableCopy] : [[NSMutableAttributedString alloc] init];
        [strs addAttributes:self.attr range:NSMakeRange(0, [strs length])];
        NSTextStorage *stor = [outp textStorage];
        if (data != nil) {
            if (self.mode.intValue < 8) {
                [stor beginEditing];
                [stor setAttributedString:strs];
                [stor endEditing];
                self.mode = @(sels);
                if (sels == 2) {
                    [outc insrCursor:self.mode.intValue cidx:didx rows:rows cols:cols stor:stor crsc:self.crsc bgdc:self.bgdc];
                }
            }
        }
    }

    return 0;
}

- (void)colt:(NSButton *)butn {
    NSMutableAttributedString *tita = [[NSMutableAttributedString alloc] initWithAttributedString:[butn attributedTitle]];
    NSRange titr = NSMakeRange(0, [tita length]);
    NSMutableParagraphStyle *styl = [[NSMutableParagraphStyle alloc] init];
    styl.lineBreakMode       = NSLineBreakByTruncatingTail;
    styl.alignment           = NSTextAlignmentLeft;
    styl.firstLineHeadIndent =  11.0;
    styl.headIndent          =  11.0;
    styl.tailIndent          = -11.0;
    [tita setAttributes:self.atrf range:titr];
    [tita addAttribute:NSParagraphStyleAttributeName value:styl range:titr];
    [butn.cell setUsesSingleLineMode:YES];
    [butn setAttributedTitle:tita];
}

- (int)next:(int)iidx dirs:(int)dirs {
    NSButton *prev = nil, *this = nil, *next = nil;
    for (int x = 0; x < [self.tabs count]; ++x) {
        NSButton *butn = [self.tabs objectAtIndex:x];
        int zidx = (((int)[butn tag]) - 1);
        if (zidx > -1) {
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

- (void)tabx:(int)indx {
    NSLog(@"TABX [%d]", indx);

    int iidx = (indx - 1);
    if ((iidx < 0) || (iidx > [self.tabl count])) { return; }
    NSButton *butn = [self.tabl objectAtIndex:iidx];
    if (butn.tag < 1) { return; }

    int tabn = 0;
    for (int x = 0; x < [self.tabs count]; ++x) {
        long tagn = [self.tabs objectAtIndex:x].tag;
        if (tagn < 1) { continue; }
        ++tabn;
    }
    if (tabn <= 1) { return; }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self next:iidx dirs:0];
        butn.tag = 0;
        [self.tabv removeView:butn];
        [butn removeFromSuperview];
        [self refs:@"tabx" mode:0 rsiz:8 wide:0.0 high:0.0];
        for (int x = 0; x < [self.tabl count]; ++x) {
            long tagn = [self.tabl objectAtIndex:x].tag;
            if (tagn < 1) { continue; }
            [self tabt:@"Tab" indx:((int)tagn)];
        }
    });
}

- (void)tabc:(id)sender {
    NSLog(@"TABC [%d] [%ld]", self.indx.intValue, [self.tabl count]);
    int indx = self.indx.intValue;
    AppDelegate *appd = (AppDelegate *)[NSApp delegate];
    int leng = ((int)[appd.proc count]);
    for (int x = (leng - 1); x > -1; --x) {
        MainProc *proc = [appd.proc objectAtIndex:x];
        if ((proc.vcon == self) && (proc.vidx.intValue == indx)) {
            [proc halt:@"tabc"];
            return;
        }
    }
}

- (int)tabz:(id)sender over:(int)ride {
    NSButton *tabb = (NSButton *)sender;
    if (self.vobj != nil) {
        long tagn = tabb.tag;
        if (tagn < 1) { return 1; }
        int indx = ((int)(tagn) - 1);
        int iidx = (self.indx.intValue - 1);
        if ((ride == 0) && (indx == iidx)) { return 2; }
        if ((-1 < indx) && (indx < [self.tabs count])) {
            NSLog(@"VIEW [%d] -> [%d]", iidx, indx);
            self.indx = @(indx + 1);
            [self refs:@"tabz" mode:0 rsiz:8 wide:0.0 high:0.0];
        }
    }
    return 0;
}

- (void)tabf:(id)sender {
    [self tabz:sender over:0];
}

- (int)tabt:(NSString *)pref indx:(int)indx {
    if (self.vobj != nil) {
        int iidx = (indx - 1);
        if ((iidx < 0) || (iidx > [self.tabl count])) { return 0; }
        NSButton *butn = [self.tabl objectAtIndex:iidx];
        long tagb = butn.tag;
        if (tagb < 1) { return 0; }
        dispatch_async(dispatch_get_main_queue(), ^{
            int tabn = 1;
            for (int x = 0; x < [self.tabs count]; ++x) {
                long tagn = [self.tabs objectAtIndex:x].tag;
                if (tagn < 1) { continue; }
                if (tagn == tagb) { break; }
                ++tabn;
            }
            NSString *head = [NSString stringWithFormat:@"%@  [#%d]", pref, tabn];
            [butn setTitle:head];
            [self colt:butn];
        });
        return 1;
    }
    return 0;
}

- (void)taba:(id)sender {
    NSLog(@"TABA [%d] [%ld]", self.indx.intValue, [self.tabl count]);
    AppDelegate *appd = (AppDelegate *)[NSApp delegate];
    [appd makeProc:@"taba" iidx:NSNotFound vobj:self];
}

- (int)newt:(NSString *)pref wide:(CGFloat)wide high:(CGFloat)high {
    unsigned long leng = [self.tabs count];
    int indx = (((int)leng) + 1);

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
    [tabb setBezelStyle:NSBezelStyleInline];
    [tabb setBordered:NO];
    [tabb setWantsLayer:YES];
    [tabb setTranslatesAutoresizingMaskIntoConstraints:NO];
    tabb.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [tabb.layer setBorderWidth:0.0];
    [tabb.layer setCornerRadius:RADI];
    [tabb.layer setBorderColor:self.tabc.CGColor];
    [tabb.layer setBackgroundColor:self.tabc.CGColor];
    [tabb setTarget:self];
    [tabb setAction:@selector(tabf:)];
    [self.tabs addObject:tabb];
    [self.tabl addObject:tabb];
    [self.tabv addView:tabb inGravity:NSStackViewGravityCenter];

    [tabb setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    //[tabb setClippingResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.srct setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.cpuv setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.ramv setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.netv setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];

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
    outp.textContainerInset = NSMakeSize(0.0, INSH);
    [self.outp addObject:outp];
    [self.otxt addObject:[[NSTextStorage alloc] init]];

    outp.insertionPointColor = self.crsc;
    outp.wide = self.fntw.floatValue;
    outp.high = self.fnth.floatValue;
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

    CursorText *inpt = [[CursorText alloc] init];
    inpt.backgroundColor = [NSColor clearColor];
    [inpt setDrawsBackground:NO];
    [inpt setEditable:NO];
    [inpt setSelectable:YES];
    [inpt setVerticallyResizable:YES];
    [inpt setHorizontallyResizable:NO];
    [inpt setTranslatesAutoresizingMaskIntoConstraints:YES];
    [inpt.textContainer setWidthTracksTextView:NO];
    [inpt.textContainer setHeightTracksTextView:NO];
    inpt.textContainer.lineFragmentPadding = 0.0;
    inpt.textContainerInset = NSMakeSize(INSW, INSH);
    inpt.delegate = self;
    [self.inpt addObject:inpt];

    inpt.insertionPointColor = self.crsc;
    inpt.wide = self.fntw.floatValue;
    inpt.high = self.fnth.floatValue;
    inpt.selc = self.selc;
    inpt.sepr = [self.seps copy];

    [iscr setDocumentView:inpt];
    [self.itxt addObject:[[NSTextStorage alloc] init]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewDidScroll:) name:NSViewBoundsDidChangeNotification object:oclp];

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
    [self refs:@"newt" mode:1 rsiz:8 wide:0.0 high:0.0];

    NSLog(@"NEWT [%@] [%d]", pref, indx);

    return indx;
}

- (void)wint:(NSString *)titl {
    self.titl.attributedStringValue = [[NSAttributedString alloc] initWithString:titl attributes:self.atrf];
}

- (void)wini:(int)indx prio:(int)prio keep:(int)keep titi:(NSString *)titi {
    if ((-1 < indx) && (indx != self.indx.intValue)) { return; }
    while (prio >= [self.titz count]) {
        [self.titz addObject:@[@"", @0, @0]];
    }
    [self.titz replaceObjectAtIndex:prio withObject:@[titi, @(keep), @(indx)]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"LOAD");

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
    self.lidx = @0;
    self.lmod = @0;

    self.barc = [NSColor clearColor];
    self.bgdc = [NSColor clearColor];
    self.tabc = [NSColor clearColor];
    self.txtc = [NSColor clearColor];
    self.selc = [NSColor clearColor];
    self.crsc = [NSColor clearColor];
    self.inpc = [NSColor clearColor];

    self.fact = @0.0;
    self.seps = nil;
    self.blrs = nil;

    self.font = [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Courier New" size:13.99] toHaveTrait:NSBoldFontMask];
    self.fiot = [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Monaco" size:13.00] toHaveTrait:NSBoldFontMask];
    self.atrf = @{ NSFontAttributeName:self.font, NSKernAttributeName:@(KERN), NSForegroundColorAttributeName:self.txtc, NSParagraphStyleAttributeName:[self wrap:1], };
    self.atrc = @{ NSFontAttributeName:self.fiot, NSForegroundColorAttributeName:self.txtc, NSParagraphStyleAttributeName:[self wrap:0], };
    self.attr = @{ NSFontAttributeName:self.fiot, NSParagraphStyleAttributeName:[self wrap:0], };

    self.ihis = [NSMutableArray array];
    self.scrp = [NSMutableArray array];
    self.scrl = [NSMutableArray array];

    self.conw = [NSMutableArray array];
    self.conh = [NSMutableArray array];
    self.cont = [NSMutableArray array];
    self.cono = nil;
    self.coni = nil;

    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = self.bgdc.CGColor;

    self.crsx = [NSMutableArray array];
    self.crsy = [NSMutableArray array];
    self.crsz = [NSMutableArray array];

    self.outp = [NSMutableArray array];
    self.otxt = [NSMutableArray array];
    self.oclp = [NSMutableArray array];
    self.oscr = [NSMutableArray array];
    self.outv = [NSMutableArray array];
    self.inpt = [NSMutableArray array];
    self.itxt = [NSMutableArray array];
    self.iclp = [NSMutableArray array];
    self.iscr = [NSMutableArray array];
    self.inpv = [NSMutableArray array];

    self.tabs = [NSMutableArray array];
    self.tabl = [NSMutableArray array];

    self.titz = [NSMutableArray array];

    self.diva = [[NSView alloc] init];
    self.diva.wantsLayer = YES;
    self.diva.translatesAutoresizingMaskIntoConstraints = NO;
    self.diva.layer.backgroundColor = self.tabc.CGColor;
    self.diva.layer.cornerRadius = (DIVH / TWOV);
    self.diva.clipsToBounds = YES;

    self.divb = [[NSView alloc] init];
    self.divb.wantsLayer = YES;
    self.divb.translatesAutoresizingMaskIntoConstraints = NO;
    self.divb.layer.backgroundColor = self.tabc.CGColor;
    self.divb.layer.cornerRadius = (DIVH / TWOV);
    self.divb.clipsToBounds = YES;

    self.divc = [[NSView alloc] init];
    self.divc.wantsLayer = YES;
    self.divc.translatesAutoresizingMaskIntoConstraints = NO;
    self.divc.layer.backgroundColor = self.tabc.CGColor;
    self.divc.layer.cornerRadius = (DIVH / TWOV);
    self.divc.clipsToBounds = YES;

    self.topv = [[NSView alloc] initWithFrame:NSZeroRect];
    self.topv.wantsLayer = YES;
    self.topv.layer.masksToBounds = YES;
    self.topv.translatesAutoresizingMaskIntoConstraints = NO;

    self.titl = [NSTextField labelWithString:@""];
    self.titl.editable = NO;
    self.titl.selectable = NO;
    self.titl.bordered = NO;
    self.titl.drawsBackground = NO;
    self.titl.alignment = NSTextAlignmentCenter;
    self.titl.translatesAutoresizingMaskIntoConstraints = NO;
    self.titl.attributedStringValue = [[NSAttributedString alloc] initWithString:@"SimpleShell" attributes:self.atrf];
    [self.topv addSubview:self.titl];

    self.titi = [NSTextField labelWithString:@""];
    self.titi.editable = NO;
    self.titi.selectable = NO;
    self.titi.bordered = NO;
    self.titi.drawsBackground = NO;
    self.titi.alignment = NSTextAlignmentRight;
    self.titi.translatesAutoresizingMaskIntoConstraints = NO;
    self.titi.attributedStringValue = [[NSAttributedString alloc] initWithString:@"[init]" attributes:self.atrf];
    [self.topv addSubview:self.titi];

    self.tabv = [[NSStackView alloc] initWithFrame:NSZeroRect];
    self.tabv.distribution = NSStackViewDistributionFill;
    self.tabv.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.tabv.spacing = 3.5;
    self.tabv.wantsLayer = YES;
    self.tabv.layer.masksToBounds = YES;
    self.tabv.edgeInsets = NSEdgeInsetsMake(0.0, INSW, 0.0, INSW);
    [self.tabv setWantsLayer:YES];
    [self.tabv setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.spcl = [[NSView alloc] init];
    [self.spcl setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.spcr = [[NSView alloc] init];
    [self.spcr setTranslatesAutoresizingMaskIntoConstraints:NO];

    NSImageSymbolConfiguration *conf;

    self.butl = [[NSButton alloc] init];
    self.imgl = [NSImage imageWithSystemSymbolName:PLUS accessibilityDescription:nil];
    conf = [NSImageSymbolConfiguration configurationWithHierarchicalColor:self.txtc];
    self.imgl = [self.imgl imageWithSymbolConfiguration:conf];
    [self.butl setWantsLayer:YES];
    [self.butl setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.butl setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.butl setImagePosition:NSImageOnly];
    [self.butl setBordered:NO];
    [self.butl.widthAnchor constraintEqualToConstant:SIZE].active = YES;
    [self.butl.heightAnchor constraintEqualToConstant:SIZE].active = YES;
    [self.butl setImage:self.imgl];
    self.butl.target = self;
    self.butl.action = @selector(taba:);
    [self.tabv addView:self.butl inGravity:NSStackViewGravityLeading];
    [self.tabv addView:self.spcl inGravity:NSStackViewGravityLeading];

    self.butr = [[NSButton alloc] init];
    self.imgr = [NSImage imageWithSystemSymbolName:CLOS accessibilityDescription:nil];
    conf = [NSImageSymbolConfiguration configurationWithHierarchicalColor:self.txtc];
    self.imgr = [self.imgr imageWithSymbolConfiguration:conf];
    [self.butr setWantsLayer:YES];
    [self.butr setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.butr setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.butr setImagePosition:NSImageOnly];
    [self.butr setBordered:NO];
    [self.butr.widthAnchor constraintEqualToConstant:SIZE].active = YES;
    [self.butr.heightAnchor constraintEqualToConstant:SIZE].active = YES;
    [self.butr setImage:self.imgr];
    self.butr.target = self;
    self.butr.action = @selector(tabc:);
    [self.tabv addView:self.spcr inGravity:NSStackViewGravityTrailing];
    [self.tabv addView:self.butr inGravity:NSStackViewGravityTrailing];

    self.allv = [[NSStackView alloc] initWithFrame:NSZeroRect];
    self.allv.distribution = NSStackViewDistributionFill;
    self.allv.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.allv.spacing = 0.0;
    self.allv.layer.masksToBounds = YES;
    [self.allv setWantsLayer:YES];
    [self.allv setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.sttv = [[NSStackView alloc] initWithFrame:NSZeroRect];
    self.sttv.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.sttv.distribution = NSStackViewDistributionFillEqually;
    self.sttv.spacing = 9.0;
    self.sttv.edgeInsets = NSEdgeInsetsMake(3.0, INSW, 3.0, INSW);
    self.sttv.translatesAutoresizingMaskIntoConstraints = NO;
    self.sttv.wantsLayer = YES;
    self.sttv.layer.backgroundColor = [NSColor clearColor].CGColor;

    void (^configureLabel)(NSTextField *) = ^(NSTextField *tf) {
        tf.editable = NO;
        tf.selectable = NO;
        tf.bordered = NO;
        tf.drawsBackground = NO;
        tf.alignment = NSTextAlignmentCenter;
    };

    self.cpuv = [NSTextField labelWithString:@""];
    configureLabel(self.cpuv);
    self.cpuv.attributedStringValue = [[NSAttributedString alloc] initWithString:@"CPU: ---" attributes:self.atrf];
    [self.sttv addView:self.cpuv inGravity:NSStackViewGravityCenter];

    self.ramv = [NSTextField labelWithString:@""];
    configureLabel(self.ramv);
    self.ramv.attributedStringValue = [[NSAttributedString alloc] initWithString:@"RAM: ---" attributes:self.atrf];
    [self.sttv addView:self.ramv inGravity:NSStackViewGravityCenter];

    self.netv = [NSTextField labelWithString:@""];
    configureLabel(self.netv);
    self.netv.attributedStringValue = [[NSAttributedString alloc] initWithString:@"NET: ---" attributes:self.atrf];
    [self.sttv addView:self.netv inGravity:NSStackViewGravityCenter];

    self.srcs = @0;
    self.sidx = @-1;

    self.srcv = [[NSStackView alloc] initWithFrame:NSZeroRect];
    self.srcv.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.srcv.distribution = NSStackViewDistributionFill;
    self.srcv.spacing = 9.0;
    self.srcv.edgeInsets = NSEdgeInsetsMake(3.0, INSW, 3.0, INSW + (TWOV + TWOV));
    self.srcv.translatesAutoresizingMaskIntoConstraints = NO;

    self.srct = [[NSTextField alloc] init];
    self.srct.placeholderString = @"Find";
    self.srct.bordered = NO;
    self.srct.bezeled = NO;
    self.srct.bezelStyle = NSTextFieldSquareBezel;
    self.srct.backgroundColor = [NSColor clearColor];
    self.srct.focusRingType = NSFocusRingTypeNone;
    self.srct.delegate = self;
    self.srct.target = self;
    self.srct.action = @selector(findNext:);

    self.srcp = [NSButton buttonWithTitle:@"Back" target:self action:@selector(findPrev:)];
    self.srcp.bordered = NO;

    self.srcn = [NSButton buttonWithTitle:@"Next" target:self action:@selector(findNext:)];
    self.srcn.bordered = NO;

    self.srcc = [NSButton buttonWithTitle:@"Copy" target:self action:@selector(findCopy:)];
    self.srcc.bordered = NO;

    self.srcd = [NSButton buttonWithTitle:@"Done" target:self action:@selector(findDone:)];
    self.srcd.bordered = NO;

    self.srcf = [NSTextField labelWithString:@""];
    self.srcf.editable = NO;
    self.srcf.selectable = NO;
    self.srcf.bordered = NO;
    self.srcf.drawsBackground = NO;
    self.srcf.alignment = NSTextAlignmentRight;
    self.srcf.translatesAutoresizingMaskIntoConstraints = NO;

    NSView *srcs = [[NSView alloc] init];
    srcs.translatesAutoresizingMaskIntoConstraints = NO;

    [self.srcv addView:self.srct inGravity:NSStackViewGravityLeading];
    [self.srcv addView:self.srcp inGravity:NSStackViewGravityLeading];
    [self.srcv addView:self.srcn inGravity:NSStackViewGravityLeading];
    [self.srcv addView:self.srcc inGravity:NSStackViewGravityLeading];
    [self.srcv addView:self.srcd inGravity:NSStackViewGravityLeading];
    [self.srcv addView:srcs inGravity:NSStackViewGravityTrailing];
    [self.srcv addView:self.srcf inGravity:NSStackViewGravityTrailing];
    [self.srcp.widthAnchor constraintEqualToConstant:50].active = YES;
    [self.srcn.widthAnchor constraintEqualToConstant:50].active = YES;
    [self.srcc.widthAnchor constraintEqualToConstant:50].active = YES;
    [self.srcd.widthAnchor constraintEqualToConstant:50].active = YES;

    [self sepr];
    [self blur];

    self.refr = [NSTimer scheduledTimerWithTimeInterval:0.357 target:self selector:@selector(refrLoop:) userInfo:nil repeats:YES];
    self.winr = [NSTimer scheduledTimerWithTimeInterval:0.579 target:self selector:@selector(winrLoop:) userInfo:nil repeats:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResignedKey:) name:NSWindowDidResignKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowBecameKey:) name:NSWindowDidBecomeKeyNotification object:nil];
}

@end
