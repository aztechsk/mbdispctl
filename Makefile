CC = clang
TARGET = build/mbdispctl
APP = build/mbdispctl.app
APP_ICON = app/mbdispctl.icns
OBJ = build/main.o build/gui.o build/builtin_display.o build/display_name.o build/display_control.o

CSTD = -std=c17
WARN = -Wall -Wextra -Wpedantic
CFLAGS ?= -O2 -g
LDLIBS = -framework CoreFoundation -framework CoreGraphics -framework AppKit

.PHONY: all app run-app clean

all: $(TARGET)

app: $(APP)/Contents/Info.plist $(APP)/Contents/MacOS/mbdispctl $(APP)/Contents/Resources/mbdispctl.icns
	codesign --force --sign - $(APP)

run-app: app
	open $(APP)

$(TARGET): $(OBJ)
	$(CC) $(LDFLAGS) $(OBJ) $(LDLIBS) -o $@

$(APP)/Contents/Info.plist: app/Info.plist
	mkdir -p $(APP)/Contents
	cp $< $@

$(APP)/Contents/MacOS/mbdispctl: $(TARGET)
	mkdir -p $(APP)/Contents/MacOS
	cp $< $@

$(APP)/Contents/Resources/mbdispctl.icns: $(APP_ICON)
	mkdir -p $(APP)/Contents/Resources
	cp $< $@

build/main.o: src/main.c src/builtin_display.h src/display_name.h src/gui.h | build
	$(CC) $(CPPFLAGS) $(CSTD) $(WARN) $(CFLAGS) -c $< -o $@

build/gui.o: src/gui.m src/gui.h src/builtin_display.h | build
	$(CC) $(CPPFLAGS) $(CSTD) $(WARN) $(CFLAGS) -c $< -o $@

build/builtin_display.o: src/builtin_display.c src/builtin_display.h src/display_control.h | build
	$(CC) $(CPPFLAGS) $(CSTD) $(WARN) $(CFLAGS) -c $< -o $@

build/display_name.o: src/display_name.m src/display_name.h | build
	$(CC) $(CPPFLAGS) $(CSTD) $(WARN) $(CFLAGS) -c $< -o $@

build/display_control.o: src/display_control.c src/display_control.h | build
	$(CC) $(CPPFLAGS) $(CSTD) $(WARN) $(CFLAGS) -c $< -o $@

build:
	mkdir -p $@

clean:
	rm -rf build
