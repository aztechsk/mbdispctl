#include <stdio.h>
#include <string.h>

static void usage(FILE *out, const char *prog)
{
	fprintf(out, "usage: %s {status|on|off}\n", prog);
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
	if (!strcmp(argv[1], "status") || !strcmp(argv[1], "on") ||
	    !strcmp(argv[1], "off"))
		return not_implemented(argv[1]);
	usage(stderr, argv[0]);
	return 2;
}
