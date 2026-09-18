#include <stdio.h>

#import <AppKit/AppKit.h>

#include "display_name.h"

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
					return 0;
				}
			}
		}
	}
	snprintf(name, size, "unknown");
	return -1;
}
