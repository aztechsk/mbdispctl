/*
 * display_control.c
 *
 * Copyright (c) 2026 Ján Rusnák and contributors
 *
 * Distributed under the ISC license.
 * See the LICENSE file in the project root for details.
 */

#include <dlfcn.h>
#include <string.h>
#include "display_control.h"

typedef CGError (*configure_display_enabled_fn)(CGDisplayConfigRef, CGDirectDisplayID, bool);
typedef CGError (*get_display_list_fn)(uint32_t, CGDirectDisplayID *, uint32_t *);

static void *skylight;
static configure_display_enabled_fn configure_display_enabled;
static get_display_list_fn get_display_list;
static const char *api_name;

/**
 * open_skylight
 */
static int open_skylight(void)
{
	if (skylight != NULL) {
		return (0);
	}
	skylight = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY | RTLD_LOCAL);
	return (skylight != NULL ? 0 : -1);
}

/**
 * load_configure_api
 */
static int load_configure_api(const char *name)
{
	void *symbol;

	symbol = dlsym(skylight, name);
	if (symbol == NULL) {
		return (-1);
	}
	memcpy(&configure_display_enabled, &symbol, sizeof(configure_display_enabled));
	api_name = name;
	return (0);
}

/**
 * load_display_list_api
 */
static int load_display_list_api(const char *name)
{
	void *symbol;

	symbol = dlsym(skylight, name);
	if (symbol == NULL) {
		return (-1);
	}
	memcpy(&get_display_list, &symbol, sizeof(get_display_list));
	return (0);
}

/**
 * display_control_init
 */
int display_control_init(void)
{
	if (configure_display_enabled != NULL) {
		return (0);
	}
	if (open_skylight() != 0) {
		return (-1);
	}
	if (load_configure_api("SLSConfigureDisplayEnabled") == 0 ||
	    load_configure_api("CGSConfigureDisplayEnabled") == 0) {
		return (0);
	}
	return (-1);
}

/**
 * display_control_api
 */
const char *display_control_api(void)
{
	return (api_name);
}

/**
 * display_control_get_displays
 */
CGError display_control_get_displays(uint32_t max_displays, CGDirectDisplayID *displays, uint32_t *count)
{
	if (open_skylight() != 0) {
		return (kCGErrorFailure);
	}
	if (get_display_list == NULL && load_display_list_api("SLSGetDisplayList") != 0 &&
	    load_display_list_api("CGSGetDisplayList") != 0) {
		return (kCGErrorFailure);
	}
	return (get_display_list(max_displays, displays, count));
}

/**
 * display_control_set_enabled
 */
CGError display_control_set_enabled(CGDisplayConfigRef config, CGDirectDisplayID display, bool enabled)
{
	if (display_control_init() != 0) {
		return (kCGErrorFailure);
	}
	return (configure_display_enabled(config, display, enabled));
}
