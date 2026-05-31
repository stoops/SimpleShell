//
//  ViewController.h
//  SimpleShell
//
//  Created by jon on 2026-05-30.
//

#import <Cocoa/Cocoa.h>

#import "ViewController.h"

#import "SettingsController.h"

@interface ViewController : NSViewController <NSTextViewDelegate, NSTextFieldDelegate, NSTableViewDelegate, NSTableViewDataSource, SettingsDelegate>

@property (strong) NSNumber *wide;
@property (strong) NSNumber *high;
@property (strong) NSNumber *fntw;
@property (strong) NSNumber *fnth;
@property (strong) NSNumber *rows;
@property (strong) NSNumber *cols;

@property (strong) NSNumber *indx;
@property (strong) NSNumber *mode;
@property (strong) NSNumber *last;
@property (strong) NSNumber *wrap;

@property (strong) NSMutableArray<NSNumber *> *remo;

@property (strong) NSColor *bgdc;
@property (strong) NSColor *tabc;
@property (strong) NSColor *txtc;
@property (strong) NSColor *selc;
@property (strong) NSColor *crsc;
@property (strong) NSColor *inpc;

@property (strong) NSView  *blrs;
@property (strong) NSView  *olay;
@property (strong) NSVisualEffectView *glas;
@property (strong) NSMutableCharacterSet *seps;

@property (strong) NSFont *font;
@property (strong) NSDictionary *attr;
@property (strong) NSDictionary *atrf;

@property (strong) NSMutableArray<NSNumber *> *crsx;
@property (strong) NSMutableArray<NSNumber *> *crsy;
@property (strong) NSMutableArray<NSNumber *> *crsz;
@property (strong) NSMutableArray<NSNumber *> *scrp;
@property (strong) NSMutableArray<NSNumber *> *scrl;
@property (strong) NSMutableArray<NSNumber *> *ihis;

@property (strong) NSMutableArray<NSTextView *> *outp;
@property (strong) NSMutableArray<NSTextStorage *> *otxt;
@property (strong) NSMutableArray<NSClipView *> *oclp;
@property (strong) NSMutableArray<NSScrollView *> *oscr;
@property (strong) NSMutableArray<NSView *> *outv;
@property (strong) NSMutableArray<NSTextView *> *inpt;
@property (strong) NSMutableArray<NSTextStorage *> *itxt;
@property (strong) NSMutableArray<NSClipView *> *iclp;
@property (strong) NSMutableArray<NSScrollView *> *iscr;
@property (strong) NSMutableArray<NSView *> *inpv;

@property (strong) NSMutableArray<NSButton *> *tabs;
@property (strong) NSView *spcl;
@property (strong) NSView *spcr;
@property (strong) NSButton *butl;
@property (strong) NSButton *butr;
@property (strong) NSImage *imgl;
@property (strong) NSImage *imgr;
@property (strong) NSMutableArray<NSLayoutConstraint *> *cons;
@property (strong) NSMutableArray<NSLayoutConstraint *> *cont;

@property (strong) NSTextField *titl;
@property (strong) NSView *diva;
@property (strong) NSView *divb;
@property (strong) NSView *divc;
@property (strong) NSStackView *topv;
@property (strong) NSStackView *tabv;
@property (strong) NSStackView *allv;
@property (strong) NSLayoutConstraint *cono;
@property (strong) NSLayoutConstraint *coni;
@property (strong) NSNotification *noto;
@property (strong) NSNotification *noti;
@property (strong) NSView *vobj;

@property (strong) NSStackView *sttv;
@property (strong) NSTextField *cpuv;
@property (strong) NSTextField *ramv;
@property (strong) NSTextField *netv;
@property (strong) NSNumber *stts;

@property (strong) NSStackView *srcv;
@property (strong) NSTextField *srct;
@property (strong) NSNumber    *srcs;
@property (assign) NSNumber    *sidx;

@property (strong) NSTimer *refr;

- (CGFloat)tell:(char)kind indx:(int)indx;
- (int)sets:(NSString *)text wide:(CGFloat)wide high:(CGFloat)high;
- (int)newt:(NSString *)text wide:(CGFloat)wide high:(CGFloat)high;
- (int)next:(int)iidx dirs:(int)dirs;
- (int)tabt:(NSString *)text indx:(int)indx;
- (int)show:(NSString *)text data:(NSAttributedString *)data pref:(NSString *)pref indx:(int)indx sels:(int)sels cidx:(int)cidx rows:(int)rows cols:(int)cols;
- (void)setTitle:(NSString *)titl;
- (void)taba:(id)sender;
- (void)tabx:(int)iidx;
- (void)findText:(int)dirs;
- (void)scro:(int)dirs;
- (void)find;
- (void)refc;
- (void)refs;

@end
