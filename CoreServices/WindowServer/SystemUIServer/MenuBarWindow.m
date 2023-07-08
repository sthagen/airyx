/*
 * Copyright (C) 2022-2023 Zoe Knox <zoe@pixin.net>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <pthread.h>
#import <AppKit/AppKit.h>
#import "desktop.h"

extern pthread_mutex_t mtx;

@implementation MenuBarWindow
- initWithFrame:(NSRect)frame forOutput:(NSScreen *)output {
    frame.origin.x = 0;
    frame.origin.y = frame.size.height - menuBarHeight;
    frame.size.height = menuBarHeight;
    self = [self initWithContentRect:frame
        styleMask:NSBorderlessWindowMask|WLWindowLayerAnchorTop
            |WLWindowLayerAnchorLeft|WLWindowLayerAnchorRight|WLWindowLayerOverlay
        backing:NSBackingStoreBuffered defer:NO screen:output];

    [self setMovableByWindowBackground:NO];

    NSNotificationCenter *nctr = [NSNotificationCenter defaultCenter];
    [nctr addObserver:self selector:@selector(notifyTick:) name:@"ClockTick" object:nil];

    float mainWidth = frame.size.width * 0.65;
    float extraWidth = frame.size.width - mainWidth;

    clockView = [[ClockView alloc] initWithFrame:frame];
    NSSize clockSize = [clockView size];

    menuView = [[MenuView alloc] initWithFrame:
	NSMakeRect(0, 0, mainWidth, menuBarHeight)];

    extrasView = [[ExtrasView alloc]
	initWithFrame:NSMakeRect(frame.size.width - extraWidth, 0,
		extraWidth - clockSize.width, menuBarHeight)];

    menuDict = [NSMutableDictionary new];
    portDict = [NSMutableDictionary new];
    _menuPort = MACH_PORT_NULL;
    activePID = 0;

    [_contentView addSubview:menuView];
    [_contentView addSubview:extrasView];
    [_contentView addSubview:clockView];
    [menuView setWindow:self];

    [_contentView setAutoresizingMask:0];

    [self setAllowsToolTipsWhenApplicationIsInactive:YES];
    
    return self;
}

- (void)notifyTick:(id)arg {
    NSString *value = [clockView currentDateValue];
    pthread_mutex_lock(&mtx);
    [clockView setStringValue:value];
    [clockView setNeedsDisplay:YES];
    pthread_mutex_unlock(&mtx);
    void *event = (__bridge_retained void *)[[NSEvent alloc]
        initWithType:NSAppKitSystem location:NSMakePoint(0,0) modifierFlags:0 window:nil];
    [NSApp postEvent:(__bridge NSEvent *)event atStart:YES];
}

- (mach_port_t)activePort {
    return _menuPort;
}

- (int)activeProcessID {
    return activePID;
}

- (void)setPort:(mach_port_t)port forPID:(unsigned int)pid {
    [portDict setObject:[NSNumber numberWithInt:port] forKey:[NSNumber numberWithInt:pid]];
    if(activePID == pid)
        _menuPort = port;
}

- (void)removePortForPID:(unsigned int)pid {
    mach_port_t port = [self portForPID:pid];
    if(port != MACH_PORT_NULL)
        mach_port_deallocate(mach_task_self(), port);
    [portDict removeObjectForKey:[NSNumber numberWithInt:pid]];
}

- (mach_port_t)portForPID:(unsigned int)pid {
    NSNumber *numPort = [portDict objectForKey:[NSNumber numberWithInt:pid]];
    if(!numPort)
        return MACH_PORT_NULL;
    return [numPort intValue];
}

- (NSMenu *)menuForPID:(unsigned int)pid {
    return [menuDict objectForKey:[NSNumber numberWithInt:pid]];
}

- (void)setMenu:(NSMenu *)menu forPID:(unsigned int)pid {
    [menuDict setObject:menu forKey:[NSNumber numberWithInt:pid]];
}

- (void)removeMenuForPID:(unsigned int)pid {
    if(pid == activePID) {
        [menuView setMenu:nil];
        [menuView setNeedsDisplay:YES];
        activePID = 0;
    }
    [menuDict removeObjectForKey:[NSNumber numberWithInt:pid]];
}

- (BOOL)activateMenuForPID:(unsigned int)pid {
    [[self platformWindow] setExclusiveZone:menuBarHeight];
    activePID = pid;
    _menuPort = [self portForPID:pid];
    NSMenu *menu = [self menuForPID:pid];
    if(menu) {
        [menuView setMenu:menu];
        [menuView setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}

- (void)addRecentItem:(NSURL *)itemURL {
    [menuView addRecentItem:itemURL];
}

- (void)addStatusItem:(NSStatusItem *)item pid:(unsigned int)pid {
    [extrasView addStatusItem:item pid:pid];
}

- (void)removeStatusItemsForPID:(unsigned int)pid {
    [extrasView removeStatusItemsForPID:pid];
}


// intercept these - we don't want this app to become activated or deactivated
-(void)platformWindowActivated:(CGWindow *)window displayIfNeeded:(BOOL)displayIfNeeded {
    // do nothing
}

-(void)platformWindowDeactivated:(CGWindow *)window checkForAppDeactivation:(BOOL)checkForAppDeactivation {
    // do nothing
}

@end

