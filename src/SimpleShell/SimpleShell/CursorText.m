//
//  CursorText.m
//  SimpleShell
//
//  Created by jon on 2026-09-14.
//

#import "CursorText.h"

@implementation CursorText

- (instancetype)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container {
    self = [super initWithFrame:frameRect textContainer:container];
    if (self) {
        _lock = YES;
        _time = nil;
        self.wantsLayer = YES;
        self.usesFontPanel = NO;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = YES;
        _time = nil;
        self.wantsLayer = YES;
        self.usesFontPanel = NO;
    }
    return self;
}

- (void)setLock {
    self.lock = NO;
    if (self.time) {
        [self.time invalidate];
    }
    __weak typeof(self) wslf = self;
    self.time = [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(wslf) sslf = wslf;
            if (sslf) {
                sslf.lock = YES;
                [sslf setNeedsDisplay:YES];
            }
        });
    }];
}

- (void)setNeedsDisplayInRect:(NSRect)rect avoidAdditionalLayout:(BOOL)flag {
    if ((rect.size.width <= 3.1337) && (self.lock == YES)) {
        if (self.wide > 0.0) { rect.size.width = self.wide; }
        if (self.high > 0.0) { rect.size.height = self.high; }
        return;
    }
    [super setNeedsDisplayInRect:rect avoidAdditionalLayout:flag];
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag {
    if (self.wide > 0.0) { rect.size.width = self.wide; }
    if (self.high > 0.0) { rect.size.height = self.high; }
    [color set];
    NSRectFill(rect);
    [super drawInsertionPointInRect:rect color:color turnedOn:YES];
}

- (void)insrCursor:(int)mode cidx:(int)cidx rows:(int)rows cols:(int)cols stor:(NSTextStorage *)stor crsc:(NSColor *)crsc bgdc:(NSColor *)bgdc {
    int rown = (cidx >> 16), coln = (cidx & 0xffff);
    NSInteger crsi = ((rown * (cols + 1)) + coln);
    if (crsi >= 0 && (crsi < stor.length)) {
        NSRange rang = NSMakeRange(crsi, 1);
        NSString *targ = [stor.string substringWithRange:rang];
        NSColor *fill = crsc ? crsc : [NSColor whiteColor];
        NSColor *invr = bgdc ? bgdc : [NSColor blackColor];
        if ([targ isEqualToString:@"\n"]) {
            [stor addAttribute:NSBackgroundColorAttributeName value:fill range:rang];
        } else {
            [stor addAttribute:NSBackgroundColorAttributeName value:fill range:rang];
            [stor addAttribute:NSForegroundColorAttributeName value:invr range:rang];
        }
    }
    [self.layoutManager ensureLayoutForTextContainer:self.textContainer];
}

- (void)drawCursor:(int)mode cidx:(int)cidx fntw:(CGFloat)fntw fnth:(CGFloat)fnth insx:(CGFloat)insx insy:(CGFloat)insy {
    if (!self.bloc) {
        self.bloc = [[NSView alloc] initWithFrame:NSZeroRect];
        self.bloc.wantsLayer = YES;
        [self addSubview:self.bloc positioned:NSWindowAbove relativeTo:nil];
    }

    self.bloc.layer.backgroundColor = self.insertionPointColor.CGColor;

    int crow = (cidx >> 16);
    int ccol = (cidx & 0xffff);
    CGFloat xpos = (insx + (ccol * fntw));
    CGFloat ypos = (insy + (crow * fnth));

    if (mode != 2) {
        self.bloc.frame = NSMakeRect(xpos, ypos, fntw, fnth);
        self.bloc.hidden = NO;
    } else {
        self.bloc.hidden = YES;
    }
}

- (NSDictionary<NSAttributedStringKey,id> *)selectedTextAttributes {
    NSColor *bgColr = self.selc ? self.selc : [NSColor selectedTextBackgroundColor];
    NSColor *fgColr = self.textColor ? self.textColor : [NSColor textColor];
    return @{
        NSBackgroundColorAttributeName: bgColr,
        NSForegroundColorAttributeName: fgColr,
    };
}

- (void)setSelectedTextAttributes:(NSDictionary<NSAttributedStringKey,id> *)attributeDictionary {
    [super setSelectedTextAttributes:attributeDictionary];
}

- (void)changeColor:(id)sender {
    /* no-op */
}

- (void)mouseDown:(NSEvent *)event {
    [self.window makeFirstResponder:self];

    if (event.clickCount == 1) {
        [self setSelectedRanges:@[[NSValue valueWithRange:NSMakeRange(0, 0)]]];
        self.rang = NSMakeRange(NSNotFound, 0);
    }

    if (event.clickCount == 2) {
        if (!self.sepr) {
            NSMutableCharacterSet *allowed = [NSMutableCharacterSet alphanumericCharacterSet];
            self.sepr = allowed;
        }

        NSPoint nspt = [self convertPoint:[event locationInWindow] fromView:nil];
        CGFloat frac = 0.0;
        NSUInteger cidx = [self.layoutManager characterIndexForPoint:nspt inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:&frac];
        if ((cidx != NSNotFound) && (cidx < self.string.length)) {
            NSString *text = self.string;
            if ([self.sepr characterIsMember:[text characterAtIndex:cidx]]) {
                NSInteger begs = cidx;
                NSInteger ends = cidx;
                while (begs > 0) {
                    unichar c = [text characterAtIndex:begs - 1];
                    if (![self.sepr characterIsMember:c]) {
                        break;
                    }
                    --begs;
                }
                while (ends < text.length) {
                    unichar c = [text characterAtIndex:ends];
                    if (![self.sepr characterIsMember:c]) {
                        break;
                    }
                    ++ends;
                }

                NSRange rang = NSMakeRange(begs, ends - begs);
                if (rang.length > 0) {
                    self.indx = begs;
                    self.rang = rang;
                    [self setSelectedRanges:@[[NSValue valueWithRange:rang]]];
                    [self processCustomSelection:rang];
                    NSPasteboard *pbrd = [NSPasteboard generalPasteboard];
                    [pbrd clearContents];
                    if (self.sels) {
                        [pbrd writeObjects:@[self.sels]];
                    }
                    NSLog(@"COPY MODO [%@]", self.sels);
                    return;
                }
            }
        }
    }

    if (event.clickCount == 3) {
        NSPoint nspt = [self convertPoint:[event locationInWindow] fromView:nil];
        CGFloat frac = 0.0;
        NSUInteger cidx = [self.layoutManager characterIndexForPoint:nspt inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:&frac];
        NSString *text = self.string;
        NSInteger leng = text.length;
        if (leng > 0) {
            if (cidx >= leng) {
                cidx = leng - 1;
            }
            NSInteger begs = cidx;
            while ((begs > 0) && ([text characterAtIndex:(begs - 1)] != '\n')) {
                --begs;
            }
            NSInteger ends = cidx;
            while ((ends < leng) && ([text characterAtIndex:ends] != '\n')) {
                ++ends;
            }
            NSRange rang = NSMakeRange(begs, ends - begs);
            self.indx = begs;
            self.rang = rang;
            [self setSelectedRanges:@[[NSValue valueWithRange:rang]]];
            [self processCustomSelection:rang];
            NSPasteboard *pbrd = [NSPasteboard generalPasteboard];
            [pbrd clearContents];
            if (self.sels) {
                [pbrd writeObjects:@[self.sels]];
            }
            NSLog(@"COPY MOTO [%@]", self.sels);
            return;
        }
    }

    NSPoint nspt = [self convertPoint:[event locationInWindow] fromView:nil];
    CGFloat frac = 0.0;
    NSUInteger indx = [self.layoutManager characterIndexForPoint:nspt inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:&frac];
    self.indx = indx;
    self.rang = NSMakeRange(indx, 0);
    NSLog(@"MODO [%ld][%@]", (long)self.indx, NSStringFromRange(self.rang));
}

- (void)mouseDragged:(NSEvent *)event {
    if ((event.clickCount == 2) && (self.rang.length > 0)) { return; }

    NSPoint nspt = [self convertPoint:[event locationInWindow] fromView:nil];
    CGFloat frac = 0.0;
    NSUInteger indx = [self.layoutManager characterIndexForPoint:nspt inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:&frac];
    NSInteger bidx = MIN(self.indx, indx);
    NSInteger eidx = MAX(self.indx, indx);
    NSRange rnew = NSMakeRange(bidx, eidx - bidx);
    if (!NSEqualRanges(rnew, self.rang)) {
        self.rang = rnew;
        NSLog(@"MOMO [%ld][%@]", (long)self.indx, NSStringFromRange(self.rang));
        [self setSelectedRanges:@[[NSValue valueWithRange:self.rang]]];
    }
}

- (void)mouseUp:(NSEvent *)event {
    if ((event.clickCount == 2) && (self.rang.length > 0)) return;

    NSLog(@"MOUP [%ld][%@]", (long)self.indx, NSStringFromRange(self.rang));
    [self processCustomSelection:self.rang];

    if (self.rang.length > 0 && self.sels && self.sels.length > 0) {
        NSPasteboard *pbrd = [NSPasteboard generalPasteboard];
        [pbrd clearContents];
        [pbrd writeObjects:@[self.sels]];
        NSLog(@"COPY MOUP [%@]", self.sels);
    }
}

- (void)applyHighlightToRange:(NSRange)range {
    if (range.length == 0) {
        [self setSelectedRanges:@[[NSValue valueWithRange:NSMakeRange(0, 0)]]];
        return;
    }
    [self setSelectedRanges:@[[NSValue valueWithRange:range]]];
}

- (void)processCustomSelection:(NSRange)range {
    self.sels = [self.string substringWithRange:range];
    NSLog(@"MOZZ [%@]", self.sels);
}

@end
