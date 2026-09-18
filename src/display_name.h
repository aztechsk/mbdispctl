#ifndef DISPLAY_NAME_H
#define DISPLAY_NAME_H

#include <stddef.h>
#include <CoreGraphics/CoreGraphics.h>

int display_get_name(CGDirectDisplayID display, char *name, size_t size);

#endif
