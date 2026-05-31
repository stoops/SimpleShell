//
//  CursorText.h
//  SimpleShell
//
//  Created by jon on 2026-09-14.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface CursorText : NSTextView

@property (nonatomic, assign) CGFloat         wide;
@property (nonatomic, assign) CGFloat         high;
@property (nonatomic, strong) NSColor        *selc;
@property (nonatomic, assign) NSRange         rang;
@property (nonatomic, assign) NSInteger       indx;
@property (nonatomic,   copy) NSString       *sels;
@property (nonatomic, assign) BOOL            lock;
@property (nonatomic, strong) NSTimer        *time;
@property (nonatomic, strong) NSCharacterSet *sepr;

- (void)setLock;
- (void)applyHighlightToRange:(NSRange)range;
- (void)processCustomSelection:(NSRange)range;

@end
