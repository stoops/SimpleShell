//
//  TabButton.m
//  SimpleShell
//
//  Created by jon on 2026-09-14.
//

#import "TabButton.h"

@implementation TabButton

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupDragAndDrop];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDragAndDrop];
    }
    return self;
}

- (void)setupDragAndDrop {
    [self setWantsLayer:YES];
    [self registerForDraggedTypes:@[SSAppTabPasteboardType]];
}

#pragma mark - Mouse / Drag Initiation

- (void)mouseDown:(NSEvent *)event {
    NSPoint initialLocation = [self convertPoint:[event locationInWindow] fromView:nil];

    while (YES) {
        NSEvent *nextEvent = [self.window nextEventMatchingMask:NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged];
        if (!nextEvent) break;

        if (nextEvent.type == NSEventTypeLeftMouseDragged) {
            NSPoint currentLocation = [self convertPoint:[nextEvent locationInWindow] fromView:nil];

            CGFloat deltaX = currentLocation.x - initialLocation.x;
            CGFloat deltaY = currentLocation.y - initialLocation.y;
            CGFloat distance = sqrt(deltaX * deltaX + deltaY * deltaY);

            if (distance >= 3.0) {
                [self mouseDragged:nextEvent];
                break;
            }
        } else if (nextEvent.type == NSEventTypeLeftMouseUp) {
            NSPoint upLocation = [self convertPoint:[nextEvent locationInWindow] fromView:nil];
            if (NSPointInRect(upLocation, self.bounds)) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                if (self.target && self.action) {
                    [self.target performSelector:self.action withObject:self];
                }
                #pragma clang diagnostic pop
            }
            break;
        }
    }
}

- (void)mouseDragged:(NSEvent *)event {
    NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:self];

    NSRect dragFrame = self.bounds;
    NSImage *dragImage = [[NSImage alloc] initWithSize:dragFrame.size];

    [dragImage lockFocus];
    [self drawRect:dragFrame];
    [dragImage unlockFocus];

    dragItem.draggingFrame = dragFrame;
    [dragItem setDraggingFrame:dragFrame contents:dragImage];

    [self beginDraggingSessionWithItems:@[dragItem] event:event source:self];
}

#pragma mark - NSDraggingSource Protocol

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return NSDragOperationMove;
}

#pragma mark - NSPasteboardWriting Protocol

- (NSArray<NSPasteboardType> *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return @[SSAppTabPasteboardType];
}

- (id)pasteboardPropertyListForType:(NSPasteboardType)type {
    if ([type isEqualToString:SSAppTabPasteboardType]) {
        return [NSString stringWithFormat:@"%ld", (long)self.tag];
    }
    return nil;
}

#pragma mark - NSPasteboardReading Protocol

+ (NSArray<NSPasteboardType> *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    return @[SSAppTabPasteboardType];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSPasteboardType)type {
    if ([type isEqualToString:SSAppTabPasteboardType]) {
        return NSPasteboardReadingAsString;
    }
    return NSPasteboardReadingAsData;
}

#pragma mark - Drag and Drop Destination Interception

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if ([[[sender draggingPasteboard] types] containsObject:SSAppTabPasteboardType]) {
        return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:SSAppTabPasteboardType]) {
        NSString *sourceTagStr = [pboard stringForType:SSAppTabPasteboardType];
        NSInteger sourceTag = [sourceTagStr integerValue];
        NSInteger destinationTag = self.tag;

        if (sourceTag != destinationTag && self.target != nil) {
            SEL moveSelector = NSSelectorFromString(@"moveTabSrcTag:dstTag:");
            if ([self.target respondsToSelector:moveSelector]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self.target performSelector:moveSelector withObject:@(sourceTag) withObject:@(destinationTag)];
                #pragma clang diagnostic pop
                return YES;
            }
        }
    }
    return NO;
}

@end
