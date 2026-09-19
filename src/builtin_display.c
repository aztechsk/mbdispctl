/*
 * builtin_display.c
 *
 * Copyright (c) 2026 Ján Rusnák and contributors
 *
 * Distributed under the BSD license.
 * See the LICENSE file in the project root for details.
 */

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include <CoreGraphics/CoreGraphics.h>

#include "builtin_display.h"
#include "display_control.h"

#define MAX_DISPLAYS 16

static void set_error(char *error, size_t error_size, const char *fmt, ...)
{
	va_list ap;

	if (error == NULL || error_size == 0) {
		return;
	}
	va_start(ap, fmt);
	vsnprintf(error, error_size, fmt, ap);
	va_end(ap);
}

static int get_builtin_display(CGDirectDisplayID *builtin, char *error, size_t error_size)
{
	CGDirectDisplayID displays[MAX_DISPLAYS];
	uint32_t count = 0;
	CGError err;

	*builtin = kCGNullDirectDisplay;
	err = display_control_get_displays(MAX_DISPLAYS, displays, &count);
	if (err != kCGErrorSuccess) {
		set_error(error, error_size, "SkyLight display list API not available or failed: error %d", (int)err);
		return 1;
	}
	for (uint32_t i = 0; i < count; i++) {
		if (CGDisplayIsBuiltin(displays[i])) {
			*builtin = displays[i];
			return 0;
		}
	}
	set_error(error, error_size, "built-in display not found");
	return 1;
}

static int has_active_external_display(CGDirectDisplayID builtin, bool *active, char *error, size_t error_size)
{
	CGDirectDisplayID *displays = NULL;
	uint32_t count = 0;
	CGError err;

	*active = false;
	err = CGGetOnlineDisplayList(0, NULL, &count);
	if (err != kCGErrorSuccess) {
		set_error(error, error_size, "CGGetOnlineDisplayList: error %d", (int)err);
		return 1;
	}
	if (count == 0) {
		set_error(error, error_size, "no online displays");
		return 1;
	}
	displays = malloc(count * sizeof(*displays));
	if (displays == NULL) {
		set_error(error, error_size, "out of memory");
		return 1;
	}
	err = CGGetOnlineDisplayList(count, displays, &count);
	if (err != kCGErrorSuccess) {
		set_error(error, error_size, "CGGetOnlineDisplayList: error %d", (int)err);
		free(displays);
		return 1;
	}
	for (uint32_t i = 0; i < count; i++) {
		if (displays[i] != builtin && CGDisplayIsActive(displays[i])) {
			*active = true;
			break;
		}
	}
	free(displays);
	return 0;
}

int builtin_display_get_enabled(bool *enabled, char *error, size_t error_size)
{
	CGDirectDisplayID builtin;

	if (get_builtin_display(&builtin, error, error_size) != 0) {
		return 1;
	}
	*enabled = CGDisplayIsOnline(builtin) != 0;
	return 0;
}

int builtin_display_set_enabled(bool enabled, bool *changed, char *error, size_t error_size)
{
	CGDirectDisplayID builtin;
	CGDisplayConfigRef config = NULL;
	bool external_active;
	bool current;
	CGError err;

	if (changed != NULL) {
		*changed = false;
	}
	if (get_builtin_display(&builtin, error, error_size) != 0) {
		return 1;
	}
	current = CGDisplayIsOnline(builtin) != 0;
	if (current == enabled) {
		return 0;
	}
	if (!enabled) {
		if (has_active_external_display(builtin, &external_active, error, error_size) != 0) {
			return 1;
		}
		if (!external_active) {
			set_error(error, error_size, "no active external display, refusing to disable built-in display");
			return 1;
		}
	}
	if (display_control_init() != 0) {
		set_error(error, error_size, "SkyLight display control API not available");
		return 1;
	}
	err = CGBeginDisplayConfiguration(&config);
	if (err != kCGErrorSuccess) {
		set_error(error, error_size, "CGBeginDisplayConfiguration: error %d", (int)err);
		return 1;
	}
	err = display_control_set_enabled(config, builtin, enabled);
	if (err != kCGErrorSuccess) {
		set_error(error, error_size, "%s: error %d", display_control_api(), (int)err);
		CGCancelDisplayConfiguration(config);
		return 1;
	}
	err = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
	if (err != kCGErrorSuccess) {
		set_error(error, error_size, "CGCompleteDisplayConfiguration: error %d", (int)err);
		return 1;
	}
	if (changed != NULL) {
		*changed = true;
	}
	return 0;
}
