/*
 * display_name.h
 *
 * Copyright (c) 2026 Ján Rusnák and contributors
 *
 * Distributed under the ISC license.
 * See the LICENSE file in the project root for details.
 */

#ifndef DISPLAY_NAME_H
#define DISPLAY_NAME_H

#include <stddef.h>
#include <CoreGraphics/CoreGraphics.h>

/**
 * display_get_name
 */
int display_get_name(CGDirectDisplayID display, char *name, size_t size);

#endif
