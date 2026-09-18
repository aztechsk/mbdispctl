#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <CoreGraphics/CoreGraphics.h>

#include "display_name.h"

static void usage(FILE *out, const char *prog)
{
	fprintf(out, "usage: %s {status|on|off}\n", prog);
}

static const char *yesno(boolean_t value)
{
	return value ? "yes" : "no";
}

static int display_status(void)
{
	CGDirectDisplayID *displays;
	uint32_t count = 0;
	CGError err;

	err = CGGetOnlineDisplayList(0, NULL, &count);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: CGGetOnlineDisplayList: error %d\n", (int)err);
		return 1;
	}
	if (count == 0) {
		fprintf(stderr, "mbdispctl: no online displays\n");
		return 1;
	}
	displays = malloc(count * sizeof(*displays));
	if (displays == NULL) {
		fprintf(stderr, "mbdispctl: out of memory\n");
		return 1;
	}
	err = CGGetOnlineDisplayList(count, displays, &count);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "mbdispctl: CGGetOnlineDisplayList: error %d\n", (int)err);
		free(displays);
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

static int not_implemented(const char *command)
{
	fprintf(stderr, "mbdispctl: %s: not implemented\n", command);
	return 1;
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
	if (!strcmp(argv[1], "on") || !strcmp(argv[1], "off")) {
		return not_implemented(argv[1]);
	}
	usage(stderr, argv[0]);
	return 2;
}
