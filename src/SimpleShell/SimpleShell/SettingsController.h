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

@property (nonatomic, strong) NSColorWell *bgdColor;
@property (nonatomic, strong) NSColorWell *tabColor;
@property (nonatomic, strong) NSColorWell *txtColor;
@property (nonatomic, strong) NSColorWell *selColor;
@property (nonatomic, strong) NSColorWell *crsColor;
@property (nonatomic, strong) NSColorWell *inpColor;
@property (nonatomic, strong) NSSlider    *blrSlider;
@property (nonatomic, strong) NSTextField *sepString;
@property (nonatomic, strong) NSButton    *rotImage;
@property (nonatomic, strong) NSButton    *sysView;

- (void)updateColors:(NSColor *)bgd tab:(NSColor *)tab txt:(NSColor *)txt sel:(NSColor *)sel crs:(NSColor *)crs inp:(NSColor *)inp;
- (void)loadColors:(NSColor *)bgd tab:(NSColor *)tab txt:(NSColor *)txt sel:(NSColor *)sel crs:(NSColor *)crs inp:(NSColor *)inp;

@end
