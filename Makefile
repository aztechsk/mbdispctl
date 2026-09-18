CC = clang
TARGET = build/mbdispctl
OBJ = build/main.o build/display_name.o build/display_control.o

CSTD = -std=c17
WARN = -Wall -Wextra -Wpedantic
CFLAGS ?= -O2 -g
LDLIBS = -framework CoreFoundation -framework CoreGraphics -framework AppKit

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(LDFLAGS) $(OBJ) $(LDLIBS) -o $@

build/main.o: src/main.c src/display_name.h | build
	$(CC) $(CPPFLAGS) $(CSTD) $(WARN) $(CFLAGS) -c $< -o $@

build/display_name.o: src/display_name.m src/display_name.h | build
	$(CC) $(CPPFLAGS) $(CSTD) $(WARN) $(CFLAGS) -c $< -o $@

build/display_control.o: src/display_control.c src/display_control.h | build
	$(CC) $(CPPFLAGS) $(CSTD) $(WARN) $(CFLAGS) -c $< -o $@

build:
	mkdir -p $@

clean:
	rm -rf build
