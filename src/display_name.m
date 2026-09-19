/*
 * display_name.m
 *
 * Copyright (c) 2026 Ján Rusnák and contributors
 *
 * Distributed under the ISC license.
 * See the LICENSE file in the project root for details.
 */

#include <stdio.h>
#import <AppKit/AppKit.h>
#include "display_name.h"

/**
 * display_get_name
 */
int display_get_name(CGDirectDisplayID display, char *name, size_t size)
{
	@autoreleasepool {
		[NSApplication sharedApplication];
		for (NSScreen *screen in [NSScreen screens]) {
			NSNumber *number = screen.deviceDescription[@"NSScreenNumber"];
			if (number != nil && number.unsignedIntValue == display) {
				const char *s = screen.localizedName.UTF8String;
				if (s != NULL) {
					snprintf(name, size, "%s", s);
					return (0);
				}
			}
		}
	}
	snprintf(name, size, "unknown");
	return (-1);
}
