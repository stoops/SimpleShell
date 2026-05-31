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
        self.usesFontPanel = NO;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = YES;
        _time = nil;
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

- (void)setNeedsDisplayInRect:(NSRect)invalidRect avoidAdditionalLayout:(BOOL)flag {
    if ((invalidRect.size.width <= 3.1337) && (self.lock == YES)) { return; }
    [super setNeedsDisplayInRect:invalidRect avoidAdditionalLayout:flag];
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag {
    if (self.wide > 0) { rect.size.width = self.wide; }
    if (self.high > 0) { rect.size.height = self.high; }
    [color set];
    NSRectFill(rect);
    [super drawInsertionPointInRect:rect color:color turnedOn:YES];
}

- (void)setSelectedTextAttributes:(NSDictionary<NSAttributedStringKey,id> *)attributeDictionary {
    [super setSelectedTextAttributes:attributeDictionary];
    if (self.layoutManager && self.selectedRange.length > 0) {
        [self.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:self.selectedRange];
        [self.layoutManager invalidateDisplayForCharacterRange:self.selectedRange];
    }
}

- (void)changeColor:(id)sender {
    /* no-op */
}

- (NSDictionary<NSAttributedStringKey,id> *)selectedTextAttributes {
    NSColor *bgColr = self.selc ? self.selc : [NSColor selectedTextBackgroundColor];
    NSColor *fgColr = self.textColor ? self.textColor : [NSColor textColor];
    return @{
        NSBackgroundColorAttributeName: bgColr,
        NSForegroundColorAttributeName: fgColr,
    };
}

- (void)mouseDown:(NSEvent *)event {
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
