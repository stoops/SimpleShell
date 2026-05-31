//
//  SettingsController.m
//  SimpleShell
//
//  Created by jon on 2026-09-12.
//

#import "SettingsController.h"
#import "ViewController.h"

@implementation SettingsController

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 360, 240)
                                                   styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [window setTitle:@"Preferences"];
    [window setMinSize:NSMakeSize(360, 240)];
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

    NSStackView *rotImage = [[NSStackView alloc] init];
    rotImage.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    rotImage.spacing = 12.0;
    rotImage.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *rotLabel = [NSTextField labelWithString:@"Dock Icon:"];
    [rotLabel setAlignment:NSTextAlignmentRight];
    [rotLabel.widthAnchor constraintEqualToConstant:115].active = YES;

    self.rotImage = [NSButton checkboxWithTitle:@"" target:self action:@selector(rotImageDidChange:)];
    [self.rotImage.widthAnchor constraintEqualToConstant:150].active = YES;

    BOOL rotFlag = [[NSUserDefaults standardUserDefaults] boolForKey:@"roti"];
    self.rotImage.state = rotFlag ? NSControlStateValueOn : NSControlStateValueOff;

    [rotImage addView:rotLabel inGravity:NSStackViewGravityLeading];
    [rotImage addView:self.rotImage inGravity:NSStackViewGravityTrailing];
    [stackView addView:rotImage inGravity:NSStackViewGravityCenter];

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
    self.csrColor = [self addRowToStack:stackView label:@"    Cursor Color:" action:@selector(csrChanged:)];

    NSStackView *sliderRow = [[NSStackView alloc] init];
    sliderRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    sliderRow.spacing = 12.0;
    sliderRow.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *sliderLabel = [NSTextField labelWithString:@"Blur Opacity:"];
    [sliderLabel setAlignment:NSTextAlignmentRight];
    [sliderLabel.widthAnchor constraintEqualToConstant:115].active = YES;

    self.blrSlider = [NSSlider sliderWithValue:0.55 minValue:0.0 maxValue:1.0 target:self action:@selector(blrSliderChanged:)];
    [self.blrSlider.widthAnchor constraintEqualToConstant:150].active = YES;

    [sliderRow addView:sliderLabel inGravity:NSStackViewGravityLeading];
    [sliderRow addView:self.blrSlider inGravity:NSStackViewGravityTrailing];
    [stackView addView:sliderRow inGravity:NSStackViewGravityCenter];

    NSStackView *seprRow = [[NSStackView alloc] init];
    seprRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    seprRow.spacing = 12.0;
    seprRow.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *seprlLabel = [NSTextField labelWithString:@"Selection String:"];
    [seprlLabel setAlignment:NSTextAlignmentRight];
    [seprlLabel.widthAnchor constraintEqualToConstant:115].active = YES;

    self.sepString = [[NSTextField alloc] init];
    [self.sepString.widthAnchor constraintEqualToConstant:150].active = YES;
    self.sepString.target = self;
    self.sepString.action = @selector(sepChanged:);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sepStringDidChange:) name:NSControlTextDidChangeNotification object:self.sepString];

    [seprRow addView:seprlLabel inGravity:NSStackViewGravityLeading];
    [seprRow addView:self.sepString inGravity:NSStackViewGravityTrailing];
    [stackView addView:seprRow inGravity:NSStackViewGravityCenter];

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

- (void)updateColors:(NSColor *)bgd tab:(NSColor *)tab txt:(NSColor *)txt sel:(NSColor *)sel csr:(NSColor *)csr {
    [self.bgdColor deactivate];
    [self.tabColor deactivate];
    [self.txtColor deactivate];
    [self.selColor deactivate];
    [self.csrColor deactivate];

    self.bgdColor.color = bgd;
    self.tabColor.color = tab;
    self.txtColor.color = txt;
    self.selColor.color = sel;
    self.csrColor.color = csr;
}

- (void)bgdChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        [vcon didChangeBgdColor:sender.color];
    }
    [self saveColorPref:sender.color forKey:@"bgdc"];
}

- (void)tabChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        [vcon didChangeTabColor:sender.color];
    }
    [self saveColorPref:sender.color forKey:@"tabc"];
}

- (void)txtChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        [vcon didChangeTxtColor:sender.color];
    }
    [self saveColorPref:sender.color forKey:@"txtc"];
}

- (void)selChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        [vcon didChangeSelColor:sender.color];
    }
    [self saveColorPref:sender.color forKey:@"selc"];
}

- (void)csrChanged:(NSColorWell *)sender {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        [vcon didChangeCsrColor:sender.color];
    }
    [self saveColorPref:sender.color forKey:@"csrc"];
}

- (void)loadColors:(NSColor *)bgd tab:(NSColor *)tab txt:(NSColor *)txt sel:(NSColor *)sel csr:(NSColor *)csr {
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        vcon.bgdc = [self loadColorPref:@"bgdc" defaultColor:bgd];
        vcon.tabc = [self loadColorPref:@"tabc" defaultColor:tab];
        vcon.txtc = [self loadColorPref:@"txtc" defaultColor:txt];
        vcon.selc = [self loadColorPref:@"selc" defaultColor:sel];
        vcon.csrc = [self loadColorPref:@"csrc" defaultColor:csr];
        if ([vcon respondsToSelector:@selector(refc)]) {
            [vcon refc];
        }
        if ([vcon respondsToSelector:@selector(refs)]) {
            [vcon refs];
        }
        double factor = [[NSUserDefaults standardUserDefaults] objectForKey:@"blrs"] ? [[NSUserDefaults standardUserDefaults] doubleForKey:@"blrs"] : 0.91;
        self.blrSlider.doubleValue = factor;
        dispatch_async(dispatch_get_main_queue(), ^{
            [vcon didChangeBlrSlider:(CGFloat)factor];
        });
        NSString *savedSeps = [[NSUserDefaults standardUserDefaults] stringForKey:@"seps"];
        if (!savedSeps) {
            savedSeps = @"&$#@.,;:=-+~*%^|/\\";
            [[NSUserDefaults standardUserDefaults] setObject:savedSeps forKey:@"seps"];
        }
        self.sepString.stringValue = savedSeps;
        if ([vcon respondsToSelector:@selector(didChangeSepString:)]) {
            [vcon didChangeSepString:savedSeps];
        }
    }
}

- (void)blrSliderChanged:(NSSlider *)sender {
    double factor = sender.doubleValue;
    [[NSUserDefaults standardUserDefaults] setDouble:factor forKey:@"blrs"];
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        [vcon didChangeBlrSlider:factor];
    }
}

- (void)sepChanged:(NSTextField *)sender {
    [self saveSepString:sender.stringValue];
}

- (void)sepStringDidChange:(NSNotification *)obj {
    NSTextField *field = (NSTextField *)obj.object;
    [self saveSepString:field.stringValue];
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
    if ([NSApp.delegate respondsToSelector:NSSelectorFromString(@"updateDockIcon")]) {
        [NSApp.delegate performSelector:NSSelectorFromString(@"updateDockIcon")];
    }
}

- (void)sysViewDidChange:(NSButton *)sender {
    BOOL isChecked = (sender.state == NSControlStateValueOn);
    [[NSUserDefaults standardUserDefaults] setBool:isChecked forKey:@"sysv"];
    for (int x = 0; x < [self.vcon count]; ++x) {
        ViewController *vcon = [self.vcon objectAtIndex:x];
        if ([vcon respondsToSelector:@selector(refc)]) {
            [vcon refc];
        }
        if ([vcon respondsToSelector:@selector(refs)]) {
            [vcon refs];
        }
    }
}

@end
