#ifndef BUILTIN_DISPLAY_H
#define BUILTIN_DISPLAY_H

#include <stdbool.h>
#include <stddef.h>

int builtin_display_get_enabled(bool *enabled, char *error, size_t error_size);
int builtin_display_set_enabled(bool enabled, bool *changed, char *error, size_t error_size);

#endif
