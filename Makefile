CC = clang
TARGET = build/mbdispctl
SRC = src/main.c
OBJ = build/main.o

CSTD = -std=c17
WARN = -Wall -Wextra -Wpedantic
CFLAGS ?= -O2 -g
LDLIBS = -framework CoreFoundation -framework CoreGraphics

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(LDFLAGS) $(OBJ) $(LDLIBS) -o $@

$(OBJ): $(SRC) | build
	$(CC) $(CPPFLAGS) $(CSTD) $(WARN) $(CFLAGS) -c $< -o $@

build:
	mkdir -p $@

clean:
	rm -rf build
