#ifndef DISPLAY_CONTROL_H
#define DISPLAY_CONTROL_H

#include <stdbool.h>
#include <CoreGraphics/CoreGraphics.h>

int display_control_init(void);
const char *display_control_api(void);
CGError display_control_set_enabled(CGDisplayConfigRef config, CGDirectDisplayID display, bool enabled);

#endif
