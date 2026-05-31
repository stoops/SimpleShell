//
//  CursorText.h
//  SimpleShell
//
//  Created by jon on 2026-09-14.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface CursorText : NSTextView

@property (assign) BOOL            lock;
@property (assign) CGFloat         wide;
@property (assign) CGFloat         high;
@property (assign) NSRange         rang;
@property (assign) NSInteger       indx;
@property (strong) NSColor        *selc;
@property (strong) NSString       *sels;
@property (strong) NSTimer        *time;
@property (strong) NSCharacterSet *sepr;
@property (strong) NSView         *bloc;

- (void)setLock;
- (void)applyHighlightToRange:(NSRange)range;
- (void)processCustomSelection:(NSRange)range;
- (void)insrCursor:(int)mode cidx:(int)cidx rows:(int)rows cols:(int)cols stor:(NSTextStorage *)stor crsc:(NSColor *)crsc bgdc:(NSColor *)bgdc;
- (void)drawCursor:(int)mode cidx:(int)cidx fntw:(CGFloat)fntw fnth:(CGFloat)fnth insx:(CGFloat)insx insy:(CGFloat)insy;

@end
