/*
 * display_control.h
 *
 * Copyright (c) 2026 Ján Rusnák and contributors
 *
 * Distributed under the ISC license.
 * See the LICENSE file in the project root for details.
 */

#ifndef DISPLAY_CONTROL_H
#define DISPLAY_CONTROL_H

#include <stdbool.h>
#include <CoreGraphics/CoreGraphics.h>

/**
 * display_control_init
 */
int display_control_init(void);

/**
 * display_control_api
 */
const char *display_control_api(void);

/**
 * display_control_get_displays
 */
CGError display_control_get_displays(uint32_t max_displays, CGDirectDisplayID *displays, uint32_t *count);

/**
 * display_control_set_enabled
 */
CGError display_control_set_enabled(CGDisplayConfigRef config, CGDirectDisplayID display, bool enabled);

#endif
