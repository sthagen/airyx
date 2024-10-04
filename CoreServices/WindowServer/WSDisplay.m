/*
 * Copyright (C) 2024 Zoe Knox <zoe@pixin.net>
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

#import <Foundation/NSRaise.h>
#import "WSDisplay.h"

@implementation WSDisplay
-init {
    self = [super init];
    _flags = 0xFFFFFFFF;
    _openGLMask = 0x1;
    return self;
}

-(uint32_t)getDisplayID {
    return _ID;
}

-(BOOL)isActive {
    return (_flags & kWSDisplayActive);
}

-(BOOL)isOnline {
    return (_flags & kWSDisplayOnline);
}

-(BOOL)isSleeping {
    return (_flags & kWSDisplaySleeping);
}

-(BOOL)isMain {
    return (_flags & kWSDisplayMain);
}

-(uint32_t)openGLMask {
    return _openGLMask;
}

// NOTE: implement in backend subclass
-(CGRect)geometry {
    NSUnimplementedMethod();
    return NSZeroRect;
}

@end

