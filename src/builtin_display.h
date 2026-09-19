/*
 * builtin_display.h
 *
 * Copyright (c) 2026 Ján Rusnák and contributors
 *
 * Distributed under the BSD license.
 * See the LICENSE file in the project root for details.
 */

#ifndef BUILTIN_DISPLAY_H
#define BUILTIN_DISPLAY_H

#include <stdbool.h>
#include <stddef.h>

/**
 * builtin_display_get_enabled
 */
int builtin_display_get_enabled(bool *enabled, char *error, size_t error_size);

/**
 * builtin_display_set_enabled
 */
int builtin_display_set_enabled(bool enabled, bool *changed, char *error, size_t error_size);

#endif
