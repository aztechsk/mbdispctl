/*
 * main.c
 *
 * Copyright (c) 2026 Ján Rusnák and contributors
 *
 * Distributed under the ISC license.
 * See the LICENSE file in the project root for details.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <CoreGraphics/CoreGraphics.h>
#include "builtin_display.h"
#include "display_name.h"
#include "gui.h"

#define MBDISPCTL_VERSION "1.00"

/**
 * usage
 */
static void usage(FILE *out, const char *prog)
{
	fprintf(out, "usage: %s [status|on|off|-h|--help|-v|--version]\n", prog);
}

/**
 * yesno
 */
static const char *yesno(boolean_t value)
{
	return (value ? "yes" : "no");
}

/**
 * get_online_displays
 */
static int get_online_displays(CGDirectDisplayID **displays, uint32_t *count)
{
	CGError err;

	*displays = NULL;
	*count = 0;
	err = CGGetOnlineDisplayList(0, NULL, count);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: CGGetOnlineDisplayList: error %d\n", (int)err);
		return (1);
	}
	if (*count == 0) {
		fprintf(stderr, "mbdispctl: no online displays\n");
		return (1);
	}
	*displays = malloc(*count * sizeof(**displays));
	if (*displays == NULL) {
		fprintf(stderr, "mbdispctl: out of memory\n");
		return (1);
	}
	err = CGGetOnlineDisplayList(*count, *displays, count);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: CGGetOnlineDisplayList: error %d\n", (int)err);
		free(*displays);
		*displays = NULL;
		return (1);
	}
	return (0);
}

/**
 * display_status
 */
static int display_status(void)
{
	CGDirectDisplayID *displays;
	uint32_t count;

	if (get_online_displays(&displays, &count) != 0) {
		return (1);
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
	return (0);
}

/**
 * display_set_enabled
 */
static int display_set_enabled(bool enabled)
{
	char error[256];
	bool changed;

	if (builtin_display_set_enabled(enabled, &changed, error, sizeof(error)) != 0) {
		fprintf(stderr, "mbdispctl: %s\n", error);
		return (1);
	}
	if (enabled) {
		printf("built-in display %s\n", changed ? "enabled" : "already enabled");
	} else {
		printf("built-in display %s\n", changed ? "disabled" : "already disabled");
	}
	return (0);
}

/**
 * main
 */
int main(int argc, char *argv[])
{
	if (argc == 1) {
		return (gui_run());
	}
	if (argc != 2) {
		usage(stderr, argv[0]);
		return (2);
	}
	if (!strcmp(argv[1], "-h") || !strcmp(argv[1], "--help")) {
		usage(stdout, argv[0]);
		return (0);
	}
	if (!strcmp(argv[1], "-v") || !strcmp(argv[1], "--version")) {
		printf("mbdispctl %s\n", MBDISPCTL_VERSION);
		return (0);
	}
	if (!strcmp(argv[1], "status")) {
		return (display_status());
	}
	if (!strcmp(argv[1], "off")) {
		return (display_set_enabled(false));
	}
	if (!strcmp(argv[1], "on")) {
		return (display_set_enabled(true));
	}
	usage(stderr, argv[0]);
	return (2);
}
