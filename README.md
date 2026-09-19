# mbdispctl

`mbdispctl` is a small macOS utility for controlling the MacBook built-in display.

The main use case is a MacBook used as a desktop workstation with an external monitor, while still running from its internal battery instead of being permanently connected to a charger. `mbdispctl` allows the built-in display to be switched off while keeping the MacBook open, so its keyboard and trackpad remain available and the external monitor effectively becomes the only working display.

For the best experience, the external monitor can be connected through an EDID emulator, such as the ATEN VC081A. This keeps the external display logically connected to macOS even when the monitor itself is powered off, helping preserve the desktop and window layout.

It provides both:

- a minimal graphical application,
- a command-line interface.

The project is intentionally small and has no external dependencies.

## Features

- Enable the built-in MacBook display.
- Disable the built-in display while an external display is active.
- Show current display status from the command line.
- Minimal native AppKit GUI.
- GUI automatically follows display state changes made externally.
- Single GUI application instance when launched through macOS LaunchServices.
- CLI remains usable while the GUI is running.
- No daemon, kernel extension, Homebrew package, or third-party library required.

## Requirements

The project requires macOS and Apple Command Line Tools.

Currently tested on:

- MacBook Air M1
- Apple Silicon (`arm64`)
- macOS 26.6.2
- macOS SDK 26.5
- Apple Clang
- GNU Make supplied with macOS

Required system frameworks:

- CoreFoundation
- CoreGraphics
- AppKit

The application also uses private display-control functions from the macOS SkyLight framework.

## Check build dependencies

After cloning the repository, run:

```sh
scripts/check-build-deps.sh
```

The script checks:

- macOS and CPU architecture,
- Apple Command Line Tools,
- Clang,
- Make,
- `codesign`,
- macOS SDK,
- required public frameworks,
- C/Objective-C compilation and linking,
- availability of the required SkyLight runtime APIs.

A successful check ends with:

```text
Result: all required build/runtime dependencies are available.
```

The script does not install or modify anything. Temporary test files are created only in the system temporary directory and are removed when the script exits.

## Build

Build the command-line executable:

```sh
make
```

Build the macOS application bundle:

```sh
make app
```

The resulting files are:

```text
build/mbdispctl
build/mbdispctl.app
```

The application bundle is ad-hoc signed during the build.

To remove generated files:

```sh
make clean
```

## Run the GUI

Launch the application bundle with:

```sh
open build/mbdispctl.app
```

or:

```sh
make run-app
```

Do not use `open build/mbdispctl` to launch the GUI. That path refers to the raw command-line executable rather than the macOS application bundle.

The application displays the current state of the internal display and provides a single button to switch it on or off.

Closing the main window exits the application.

Minimizing the window keeps the application running in the Dock.

## Command-line interface

Show display status:

```sh
build/mbdispctl status
```

Enable the built-in display:

```sh
build/mbdispctl on
```

Disable the built-in display:

```sh
build/mbdispctl off
```

Show version:

```sh
build/mbdispctl -v
```

or:

```sh
build/mbdispctl --version
```

Show usage:

```sh
build/mbdispctl --help
```

Version 1.00 reports:

```text
mbdispctl 1.00
```

## Display safety

Before disabling the built-in display, `mbdispctl` verifies that at least one external display is active.

If no active external display is available, the operation is refused:

```text
no active external display, refusing to disable built-in display
```

This protects against accidentally disabling the only active display.

An EDID emulator or similar device can make macOS consider an external display active even when the physical monitor itself is powered off. In such a configuration, `mbdispctl` cannot determine whether the external panel is actually visible.

## Display state

Display changes are applied for the current macOS session.

The utility does not install persistent configuration, background services, or startup components.

A reboot therefore restores normal macOS display handling.

## Implementation

Public macOS APIs are used for display discovery, status information, and the GUI.

Enabling and disabling displays requires private functions from:

```text
/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight
```

The required functions are resolved dynamically at runtime.

The implementation currently supports these symbol names:

```text
SLSConfigureDisplayEnabled
CGSConfigureDisplayEnabled

SLSGetDisplayList
CGSGetDisplayList
```

The `CGS*` symbols are used as fallbacks.

No private framework is linked directly into the executable.

## Private API warning

SkyLight is a private macOS framework.

Its API is undocumented and is not guaranteed to remain compatible with future macOS releases. A macOS update may rename, remove, or change the behavior of the private functions used by `mbdispctl`.

Run:

```sh
scripts/check-build-deps.sh
```

after significant macOS upgrades to verify that the required runtime APIs are still available.

## Application signing

`make app` applies an ad-hoc signature to the generated application bundle.

This is suitable for local builds.

The project is currently not Developer ID signed or notarized for public binary distribution.

## Project layout

```text
mbdispctl/
├── Makefile
├── README.md
├── LICENSE
├── app/
│   ├── Info.plist
│   └── mbdispctl.icns
├── scripts/
│   └── check-build-deps.sh
└── src/
    ├── main.c
    ├── gui.m
    ├── gui.h
    ├── builtin_display.c
    ├── builtin_display.h
    ├── display_control.c
    ├── display_control.h
    ├── display_name.m
    └── display_name.h
```

## License

See `LICENSE`.
