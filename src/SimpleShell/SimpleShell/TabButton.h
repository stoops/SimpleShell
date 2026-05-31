//
//  TabButton.h
//  SimpleShell
//
//  Created by jon on 2026-09-14.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

static NSPasteboardType const SSAppTabPasteboardType = @"com.simpleshell.tabtype";

@interface TabButton : NSButton <NSDraggingSource, NSPasteboardWriting, NSPasteboardReading>

- (void)setupDragAndDrop;

@end
