#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <CoreGraphics/CoreGraphics.h>

#include "display_control.h"
#include "display_name.h"

#define MAX_DISPLAYS 16

static void usage(FILE *out, const char *prog)
{
	fprintf(out, "usage: %s {status|on|off}\n", prog);
}

static const char *yesno(boolean_t value)
{
	return value ? "yes" : "no";
}

static int get_online_displays(CGDirectDisplayID **displays, uint32_t *count)
{
	CGError err;

	*displays = NULL;
	*count = 0;
	err = CGGetOnlineDisplayList(0, NULL, count);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: CGGetOnlineDisplayList: error %d\n", (int)err);
		return 1;
	}
	if (*count == 0) {
		fprintf(stderr, "mbdispctl: no online displays\n");
		return 1;
	}
	*displays = malloc(*count * sizeof(**displays));
	if (*displays == NULL) {
		fprintf(stderr, "mbdispctl: out of memory\n");
		return 1;
	}
	err = CGGetOnlineDisplayList(*count, *displays, count);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: CGGetOnlineDisplayList: error %d\n", (int)err);
		free(*displays);
		*displays = NULL;
		return 1;
	}
	return 0;
}

static int display_status(void)
{
	CGDirectDisplayID *displays;
	uint32_t count;

	if (get_online_displays(&displays, &count) != 0) {
		return 1;
	}
	for (uint32_t i = 0; i < count; i++) {
		CGDirectDisplayID display = displays[i];
		char name[256];
		boolean_t main = CGDisplayIsMain(display);

		display_get_name(display, name, sizeof(name));
		printf("%sid=%u name=\"%s\" online=%s active=%s main=%s asleep=%s%s\n", main ? "[" : "",
		    (unsigned)display, name, yesno(CGDisplayIsOnline(display)), yesno(CGDisplayIsActive(display)),
		    yesno(main), yesno(CGDisplayIsAsleep(display)), main ? "]" : "");
	}
	free(displays);
	return 0;
}

static int display_off(void)
{
	CGDirectDisplayID *displays;
	CGDirectDisplayID builtin = kCGNullDirectDisplay;
	CGDisplayConfigRef config = NULL;
	uint32_t count;
	unsigned int external_active = 0;
	CGError err;

	if (get_online_displays(&displays, &count) != 0) {
		return 1;
	}
	for (uint32_t i = 0; i < count; i++) {
		if (CGDisplayIsBuiltin(displays[i])) {
			builtin = displays[i];
		} else if (CGDisplayIsActive(displays[i])) {
			external_active++;
		}
	}
	free(displays);
	if (builtin == kCGNullDirectDisplay) {
		fprintf(stderr, "mbdispctl: built-in display not found\n");
		return 1;
	}
	if (external_active == 0) {
		fprintf(stderr, "mbdispctl: no active external display, refusing to disable built-in display\n");
		return 1;
	}
	if (display_control_init() != 0) {
		fprintf(stderr, "mbdispctl: SkyLight display control API not available\n");
		return 1;
	}
	err = CGBeginDisplayConfiguration(&config);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: CGBeginDisplayConfiguration: error %d\n", (int)err);
		return 1;
	}
	err = display_control_set_enabled(config, builtin, false);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: %s: error %d\n", display_control_api(), (int)err);
		CGCancelDisplayConfiguration(config);
		return 1;
	}
	err = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: CGCompleteDisplayConfiguration: error %d\n", (int)err);
		return 1;
	}
	printf("built-in display disabled\n");
	return 0;
}

static int display_on(void)
{
	CGDirectDisplayID displays[MAX_DISPLAYS];
	CGDirectDisplayID builtin = kCGNullDirectDisplay;
	CGDisplayConfigRef config = NULL;
	uint32_t count = 0;
	CGError err;

	err = display_control_get_displays(MAX_DISPLAYS, displays, &count);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: SkyLight display list API not available or failed: error %d\n", (int)err);
		return 1;
	}
	for (uint32_t i = 0; i < count; i++) {
		if (CGDisplayIsBuiltin(displays[i])) {
			builtin = displays[i];
			break;
		}
	}
	if (builtin == kCGNullDirectDisplay) {
		fprintf(stderr, "mbdispctl: built-in display not found\n");
		return 1;
	}
	if (CGDisplayIsOnline(builtin)) {
		printf("built-in display already enabled\n");
		return 0;
	}
	err = CGBeginDisplayConfiguration(&config);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: CGBeginDisplayConfiguration: error %d\n", (int)err);
		return 1;
	}
	err = display_control_set_enabled(config, builtin, true);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: %s: error %d\n", display_control_api(), (int)err);
		CGCancelDisplayConfiguration(config);
		return 1;
	}
	err = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: CGCompleteDisplayConfiguration: error %d\n", (int)err);
		return 1;
	}
	printf("built-in display enabled\n");
	return 0;
}

int main(int argc, char *argv[])
{
	if (argc != 2) {
		usage(stderr, argv[0]);
		return 2;
	}
	if (!strcmp(argv[1], "-h") || !strcmp(argv[1], "--help")) {
		usage(stdout, argv[0]);
		return 0;
	}
	if (!strcmp(argv[1], "status")) {
		return display_status();
	}
	if (!strcmp(argv[1], "off")) {
		return display_off();
	}
	if (!strcmp(argv[1], "on")) {
		return display_on();
	}
	usage(stderr, argv[0]);
	return 2;
}
