//
//  SettingsController.h
//  SimpleShell
//
//  Created by jon on 2026-09-12.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@class ViewController;

@protocol SettingsDelegate <NSObject>
- (void)didChangeBgdColor:(NSColor *)color;
- (void)didChangeTabColor:(NSColor *)color;
- (void)didChangeTxtColor:(NSColor *)color;
- (void)didChangeSelColor:(NSColor *)color;
- (void)didChangeCrsColor:(NSColor *)color;
- (void)didChangeInpColor:(NSColor *)color;
- (void)didChangeBlrSlider:(CGFloat)factor;
- (void)didChangeSepString:(NSString *)string;
@end

@interface SettingsController : NSWindowController

@property (strong) NSMutableArray<ViewController *> *vcon;

@property (strong) NSColorWell *bgdColor;
@property (strong) NSColorWell *tabColor;
@property (strong) NSColorWell *txtColor;
@property (strong) NSColorWell *selColor;
@property (strong) NSColorWell *crsColor;
@property (strong) NSColorWell *inpColor;
@property (strong) NSSlider    *blrSlider;
@property (strong) NSTextField *sepString;
@property (strong) NSButton    *rotImage;
@property (strong) NSButton    *sysView;

- (void)updateColors:(NSColor *)bgd tab:(NSColor *)tab txt:(NSColor *)txt sel:(NSColor *)sel crs:(NSColor *)crs inp:(NSColor *)inp;
- (void)loadColors:(NSColor *)bgd tab:(NSColor *)tab txt:(NSColor *)txt sel:(NSColor *)sel crs:(NSColor *)crs inp:(NSColor *)inp;

@end
