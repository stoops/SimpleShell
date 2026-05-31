//
//  SettingsController.m
//  SimpleShell
//
//  Created by jon on 2026-09-12.
//

#import "SettingsController.h"
#import "ViewController.h"

#define DEFS @"$#@.,;:-~|/\\"

@interface NSObject (AppDelegateMethods)
- (void)updateDockIcon;
@end

@implementation SettingsController

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 350, 150)
                                                   styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [window setTitle:@"Preferences"];
    [window setMinSize:NSMakeSize(350, 150)];
    self = [super initWithWindow:window];
    if (self) {
        [self windowDidLoad];
        [window display];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    NSWindow *win = self.window;
    NSView *contentView = win.contentView;

    [contentView setWantsLayer:YES];

    NSStackView *stackView = [[NSStackView alloc] init];
    stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
    stackView.distribution = NSStackViewDistributionFill;
    stackView.alignment = NSLayoutAttributeCenterX;
    stackView.spacing = 12.0;
    stackView.edgeInsets = NSEdgeInsetsMake(20, 20, 20, 20);
    stackView.translatesAutoresizingMaskIntoConstraints = NO;

    [contentView addSubview:stackView];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor]
    ]];

    NSStackView *rotView = [[NSStackView alloc] init];
    rotView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    rotView.spacing = 12.0;
    rotView.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *rotLabel = [NSTextField labelWithString:@"Dock Icon:"];
    [rotLabel setAlignment:NSTextAlignmentRight];
    [rotLabel.widthAnchor constraintEqualToConstant:115].active = YES;

    self.rotImage = [NSButton checkboxWithTitle:@"" target:self action:@selector(rotImageDidChange:)];
    [self.rotImage.widthAnchor constraintEqualToConstant:150].active = YES;

    BOOL rotFlag = [[NSUserDefaults standardUserDefaults] boolForKey:@"roti"];
    self.rotImage.state = rotFlag ? NSControlStateValueOn : NSControlStateValueOff;

    [rotView addView:rotLabel inGravity:NSStackViewGravityLeading];
    [rotView addView:self.rotImage inGravity:NSStackViewGravityTrailing];
    [stackView addView:rotView inGravity:NSStackViewGravityCenter];

    NSStackView *sysView = [[NSStackView alloc] init];
    sysView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    sysView.spacing = 12.0;
    sysView.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *sysLabel = [NSTextField labelWithString:@"System Stats:"];
    [sysLabel setAlignment:NSTextAlignmentRight];
    [sysLabel.widthAnchor constraintEqualToConstant:115].active = YES;

    self.sysView = [NSButton checkboxWithTitle:@"" target:self action:@selector(sysViewDidChange:)];
    [self.sysView.widthAnchor constraintEqualToConstant:150].active = YES;

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"sysv"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"sysv"];
    }
    BOOL sysFlag = [[NSUserDefaults standardUserDefaults] boolForKey:@"sysv"];
    self.sysView.state = sysFlag ? NSControlStateValueOn : NSControlStateValueOff;

    [sysView addView:sysLabel inGravity:NSStackViewGravityLeading];
    [sysView addView:self.sysView inGravity:NSStackViewGravityTrailing];
    [stackView addView:sysView inGravity:NSStackViewGravityCenter];

    self.bgdColor = [self addRowToStack:stackView label:@"Background Color:" action:@selector(bgdChanged:)];
    self.tabColor = [self addRowToStack:stackView label:@"       Tab Color:" action:@selector(tabChanged:)];
    self.txtColor = [self addRowToStack:stackView label:@"      Text Color:" action:@selector(txtChanged:)];
    self.selColor = [self addRowToStack:stackView label:@" Highlight Color:" action:@selector(selChanged:)];
    self.crsColor = [self addRowToStack:stackView label:@"    Cursor Color:" action:@selector(crsChanged:)];
    self.inpColor = [self addRowToStack:stackView label:@"    Bottom Color:" action:@selector(inpChanged:)];

    NSStackView *sliderView = [[NSStackView alloc] init];
    sliderView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    sliderView.spacing = 12.0;
    sliderView.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *sliderLabel = [NSTextField labelWithString:@"Blur Opacity:"];
    [sliderLabel setAlignment:NSTextAlignmentRight];
    [sliderLabel.widthAnchor constraintEqualToConstant:115].active = YES;

    self.blrSlider = [NSSlider sliderWithValue:0.55 minValue:0.0 maxValue:1.0 target:self action:@selector(blrSliderChanged:)];
    [self.blrSlider.widthAnchor constraintEqualToConstant:150].active = YES;

    [sliderView addView:sliderLabel inGravity:NSStackViewGravityLeading];
    [sliderView addView:self.blrSlider inGravity:NSStackViewGravityTrailing];
    [stackView addView:sliderView inGravity:NSStackViewGravityCenter];

    NSStackView *hideView = [[NSStackView alloc] init];
    hideView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    hideView.spacing = 12.0;
    hideView.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *hideLabel = [NSTextField labelWithString:@""];
    [hideLabel setAlignment:NSTextAlignmentRight];
    [hideLabel.widthAnchor constraintEqualToConstant:115].active = YES;

    NSTextField *hideText = [[NSTextField alloc] init];
    hideText.drawsBackground = NO;
    hideText.focusRingType = NSFocusRingTypeNone;
    hideText.textColor = [NSColor clearColor];
    [hideText.widthAnchor constraintEqualToConstant:150].active = YES;

    [hideView addView:hideLabel inGravity:NSStackViewGravityLeading];
    [hideView addView:hideText inGravity:NSStackViewGravityTrailing];
    [stackView addView:hideView inGravity:NSStackViewGravityCenter];

    NSStackView *seprView = [[NSStackView alloc] init];
    seprView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    seprView.spacing = 12.0;
    seprView.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *seprlLabel = [NSTextField labelWithString:@"Selection String:"];
    [seprlLabel setAlignment:NSTextAlignmentRight];
    [seprlLabel.widthAnchor constraintEqualToConstant:115].active = YES;

    self.sepString = [[NSTextField alloc] init];
    [self.sepString.widthAnchor constraintEqualToConstant:150].active = YES;
    self.sepString.target = self;
    self.sepString.action = @selector(sepChanged:);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sepStringDidChange:) name:NSControlTextDidChangeNotification object:self.sepString];

    [seprView addView:seprlLabel inGravity:NSStackViewGravityLeading];
    [seprView addView:self.sepString inGravity:NSStackViewGravityTrailing];
    [stackView addView:seprView inGravity:NSStackViewGravityCenter];

    [contentView layoutSubtreeIfNeeded];
    [win recalculateKeyViewLoop];
}

- (NSColorWell *)addRowToStack:(NSStackView *)stack label:(NSString *)title action:(SEL)selector {
    NSStackView *row = [[NSStackView alloc] init];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.distribution = NSStackViewDistributionFill;
    row.spacing = 12.0;
    row.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *label = [NSTextField labelWithString:title];
    [label setAlignment:NSTextAlignmentRight];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];

    [label.widthAnchor constraintEqualToConstant:115].active = YES;

    NSColorWell *colorWell = [[NSColorWell alloc] init];
    colorWell.target = self;
    colorWell.action = selector;
    [colorWell setTranslatesAutoresizingMaskIntoConstraints:NO];

    [colorWell.widthAnchor constraintEqualToConstant:150].active = YES;
    [colorWell.heightAnchor constraintEqualToConstant:25].active = YES;

    [row addView:label inGravity:NSStackViewGravityLeading];
    [row addView:colorWell inGravity:NSStackViewGravityTrailing];

    [stack addView:row inGravity:NSStackViewGravityCenter];
    return colorWell;
}

- (void)saveColorPref:(NSColor *)color forKey:(NSString *)key {
    if (!color) return;
    NSError *error = nil;
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color requiringSecureCoding:YES error:&error];
    if (!error && colorData) {
        [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:key];
    }
}

- (NSColor *)loadColorPref:(NSString *)key defaultColor:(NSColor *)defaultColor {
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (!colorData) return defaultColor;
    NSError *error = nil;
    NSColor *color = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:colorData error:&error];
    if (error || !color) return defaultColor;
    return color;
}

- (void)updateColors:(NSColor *)bgd tab:(NSColor *)tab txt:(NSColor *)txt sel:(NSColor *)sel crs:(NSColor *)crs inp:(NSColor *)inp {
    [self.bgdColor deactivate];
    [self.tabColor deactivate];
    [self.txtColor deactivate];
    [self.selColor deactivate];
    [self.crsColor deactivate];
    [self.inpColor deactivate];

    self.bgdColor.color = bgd;
    self.tabColor.color = tab;
    self.txtColor.color = txt;
    self.selColor.color = sel;
    self.crsColor.color = crs;
    self.inpColor.color = inp;
}

- (void)bgdChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        vcon.bgdc = sender.color;
        [vcon refs:1];
    }
    [self saveColorPref:sender.color forKey:@"bgdc"];
}

- (void)tabChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        vcon.tabc = sender.color;
        [vcon refs:1];
    }
    [self saveColorPref:sender.color forKey:@"tabc"];
}

- (void)txtChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        vcon.txtc = sender.color;
        [vcon refs:1];
    }
    [self saveColorPref:sender.color forKey:@"txtc"];
}

- (void)selChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        vcon.selc = sender.color;
        [vcon refs:1];
    }
    [self saveColorPref:sender.color forKey:@"selc"];
}

- (void)crsChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        vcon.crsc = sender.color;
        [vcon refs:1];
    }
    [self saveColorPref:sender.color forKey:@"crsc"];
}

- (void)inpChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        vcon.inpc = sender.color;
        [vcon refs:1];
    }
    [self saveColorPref:sender.color forKey:@"inpc"];
}

- (void)blrSliderChanged:(NSSlider *)sender {
    double factor = sender.doubleValue;
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        vcon.fact = @(factor);
        [vcon refs:1];
    }
    [[NSUserDefaults standardUserDefaults] setDouble:factor forKey:@"blrs"];
}

- (void)loadColors:(NSColor *)bgd tab:(NSColor *)tab txt:(NSColor *)txt sel:(NSColor *)sel crs:(NSColor *)crs inp:(NSColor *)inp {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        vcon.bgdc = [self loadColorPref:@"bgdc" defaultColor:bgd];
        vcon.tabc = [self loadColorPref:@"tabc" defaultColor:tab];
        vcon.txtc = [self loadColorPref:@"txtc" defaultColor:txt];
        vcon.selc = [self loadColorPref:@"selc" defaultColor:sel];
        vcon.crsc = [self loadColorPref:@"crsc" defaultColor:crs];
        vcon.inpc = [self loadColorPref:@"inpc" defaultColor:inp];
        double factor = [[NSUserDefaults standardUserDefaults] objectForKey:@"blrs"] ? [[NSUserDefaults standardUserDefaults] doubleForKey:@"blrs"] : self.blrSlider.floatValue;
        self.blrSlider.doubleValue = factor;
        vcon.fact = @(factor);
        NSString *savedSeps = [[NSUserDefaults standardUserDefaults] stringForKey:@"seps"];
        if (!savedSeps) {
            savedSeps = DEFS;
            [[NSUserDefaults standardUserDefaults] setObject:savedSeps forKey:@"seps"];
        }
        self.sepString.stringValue = savedSeps;
        [vcon didChangeSepString:savedSeps];
        BOOL sysFlag = [[NSUserDefaults standardUserDefaults] boolForKey:@"sysv"];
        vcon.stts = sysFlag ? @(1) : @(0);
        [vcon refs:1];
    }
}

- (void)sepChanged:(NSTextField *)sender {
    if ([sender.stringValue isEqualToString:@""]) {
        sender.stringValue = DEFS;
    }
    [self saveSepString:sender.stringValue];
}

- (void)sepStringDidChange:(NSNotification *)obj {
    NSTextField *sender = (NSTextField *)obj.object;
    if ([sender.stringValue isEqualToString:@""]) {
        sender.stringValue = DEFS;
    }
    [self saveSepString:sender.stringValue];
}

- (void)saveSepString:(NSString *)text {
    [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"seps"];
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        [vcon didChangeSepString:text];
    }
}

- (void)rotImageDidChange:(NSButton *)sender {
    BOOL rotFlag = (sender.state == NSControlStateValueOn);
    [[NSUserDefaults standardUserDefaults] setBool:rotFlag forKey:@"roti"];
    if ([NSApp.delegate respondsToSelector:@selector(updateDockIcon)]) {
        [NSApp.delegate performSelector:@selector(updateDockIcon)];
    }
}

- (void)sysViewDidChange:(NSButton *)sender {
    BOOL sysFlag = (sender.state == NSControlStateValueOn);
    [[NSUserDefaults standardUserDefaults] setBool:sysFlag forKey:@"sysv"];
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        vcon.stts = sysFlag ? @(1) : @(0);
        [vcon refs:1];
    }
}

@end
