#!/bin/sh

#
# check-build-deps.sh
#
# Copyright (c) 2026 Ján Rusnák and contributors
#
# Distributed under the BSD license.
# See the LICENSE file in the project root for details.
#

LC_ALL=C
export LC_ALL

failures=0
warnings=0

ok()
{
	printf '[OK]   %s\n' "$*"
}

warn()
{
	printf '[WARN] %s\n' "$*"
	warnings=$((warnings + 1))
}

fail()
{
	printf '[FAIL] %s\n' "$*"
	failures=$((failures + 1))
}

need_cmd()
{
	if command -v "$1" >/dev/null 2>&1; then
		ok "$1: $(command -v "$1")"
	else
		fail "$1 not found"
	fi
}

printf 'mbdispctl build dependency check\n'
printf '%s\n' '--------------------------------'

if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
	macos_version=$(sw_vers -productVersion 2>/dev/null || printf 'unknown')
	arch=$(uname -m 2>/dev/null || printf 'unknown')
	ok "macOS $macos_version ($arch)"
	if [ "$arch" != "arm64" ]; then
		warn "project is currently tested on Apple Silicon (arm64)"
	fi
else
	fail "macOS is required"
fi

need_cmd xcode-select
need_cmd xcrun
need_cmd clang
need_cmd make
need_cmd codesign
need_cmd open

developer_dir=
if command -v xcode-select >/dev/null 2>&1; then
	developer_dir=$(xcode-select -p 2>/dev/null || true)
	if [ -n "$developer_dir" ] && [ -d "$developer_dir" ]; then
		ok "developer directory: $developer_dir"
	else
		fail "Apple Command Line Tools/Xcode developer directory not configured"
	fi
fi

sdk=
if command -v xcrun >/dev/null 2>&1; then
	sdk=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)
	if [ -n "$sdk" ] && [ -d "$sdk" ]; then
		sdk_version=$(xcrun --sdk macosx --show-sdk-version 2>/dev/null || printf 'unknown')
		ok "macOS SDK $sdk_version: $sdk"
	else
		fail "macOS SDK not found"
	fi
fi

if [ -n "$sdk" ]; then
	for framework in CoreFoundation CoreGraphics AppKit; do
		if [ -d "$sdk/System/Library/Frameworks/$framework.framework" ]; then
			ok "$framework.framework"
		else
			fail "$framework.framework not found in macOS SDK"
		fi
	done
fi

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/mbdispctl-deps.XXXXXX" 2>/dev/null || true)
if [ -z "$tmpdir" ] || [ ! -d "$tmpdir" ]; then
	fail "cannot create temporary directory"
else
	trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

	cat >"$tmpdir/build-test.m" <<'EOF'
#import <AppKit/AppKit.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <dlfcn.h>

int main(void)
{
	CGDirectDisplayID display = CGMainDisplayID();
	void *handle = dlopen(NULL, RTLD_LAZY);

	if (handle != NULL) {
		dlclose(handle);
	}
	return display == kCGNullDirectDisplay;
}
EOF

	if clang -std=c17 -Wall -Wextra -Wpedantic \
	    "$tmpdir/build-test.m" \
	    -framework CoreFoundation -framework CoreGraphics -framework AppKit \
	    -o "$tmpdir/build-test" >/dev/null 2>"$tmpdir/build-test.err"; then
		ok "C/Objective-C compile and framework link test"
	else
		fail "C/Objective-C compile or framework link test failed"
		sed 's/^/       /' "$tmpdir/build-test.err"
	fi

	cat >"$tmpdir/skylight-test.c" <<'EOF'
#include <dlfcn.h>
#include <stdio.h>

int main(void)
{
	void *handle;
	int configure_ok;
	int list_ok;

	handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
	    RTLD_LAZY | RTLD_LOCAL);
	if (handle == NULL) {
		return 1;
	}
	configure_ok = dlsym(handle, "SLSConfigureDisplayEnabled") != NULL ||
	    dlsym(handle, "CGSConfigureDisplayEnabled") != NULL;
	list_ok = dlsym(handle, "SLSGetDisplayList") != NULL ||
	    dlsym(handle, "CGSGetDisplayList") != NULL;
	dlclose(handle);
	return configure_ok && list_ok ? 0 : 1;
}
EOF

	if clang -std=c17 -Wall -Wextra -Wpedantic "$tmpdir/skylight-test.c" \
	    -o "$tmpdir/skylight-test" >/dev/null 2>"$tmpdir/skylight-test.err"; then
		if "$tmpdir/skylight-test"; then
			ok "SkyLight display-control runtime APIs"
		else
			fail "required SkyLight display-control runtime APIs not available"
		fi
	else
		fail "SkyLight runtime test could not be built"
		sed 's/^/       /' "$tmpdir/skylight-test.err"
	fi
fi

printf '\n'
if [ "$failures" -eq 0 ]; then
	if [ "$warnings" -eq 0 ]; then
		printf 'Result: all required build/runtime dependencies are available.\n'
	else
		printf 'Result: required dependencies are available (%d warning(s)).\n' "$warnings"
	fi
	exit 0
fi

printf 'Result: %d required check(s) failed' "$failures"
if [ "$warnings" -ne 0 ]; then
	printf ', %d warning(s)' "$warnings"
fi
printf '.\n'
exit 1
