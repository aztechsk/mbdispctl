#include <dlfcn.h>
#include <string.h>

#include "display_control.h"

typedef CGError (*configure_display_enabled_fn)(CGDisplayConfigRef, CGDirectDisplayID, bool);

static void *skylight;
static configure_display_enabled_fn configure_display_enabled;
static const char *api_name;

static int load_api(const char *name)
{
	void *symbol;

	symbol = dlsym(skylight, name);
	if (symbol == NULL) {
		return -1;
	}
	memcpy(&configure_display_enabled, &symbol, sizeof(configure_display_enabled));
	api_name = name;
	return 0;
}

int display_control_init(void)
{
	if (configure_display_enabled != NULL) {
		return 0;
	}
	skylight = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY | RTLD_LOCAL);
	if (skylight == NULL) {
		return -1;
	}
	if (load_api("SLSConfigureDisplayEnabled") == 0 || load_api("CGSConfigureDisplayEnabled") == 0) {
		return 0;
	}
	dlclose(skylight);
	skylight = NULL;
	return -1;
}

const char *display_control_api(void)
{
	return api_name;
}

CGError display_control_set_enabled(CGDisplayConfigRef config, CGDirectDisplayID display, bool enabled)
{
	if (display_control_init() != 0) {
		return kCGErrorFailure;
	}
	return configure_display_enabled(config, display, enabled);
}
