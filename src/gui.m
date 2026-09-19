/*
 * gui.m
 *
 * Copyright (c) 2026 Ján Rusnák and contributors
 *
 * Distributed under the ISC license.
 * See the LICENSE file in the project root for details.
 */

#import <AppKit/AppKit.h>
#include <stdio.h>
#include <CoreGraphics/CoreGraphics.h>
#include "builtin_display.h"
#include "gui.h"

#define WINDOW_WIDTH 300.0
#define WINDOW_HEIGHT 160.0
#define BUTTON_WIDTH 140.0
#define BUTTON_HEIGHT 52.0
#define LABEL_HEIGHT 24.0

@interface MBDisplayStateView : NSView {
	BOOL state_known;
	BOOL display_enabled;
}
- (void)setDisplayEnabled:(BOOL)enabled known:(BOOL)known;
@end

@implementation MBDisplayStateView
/**
 * setDisplayEnabled:known:
 */
- (void)setDisplayEnabled:(BOOL)enabled known:(BOOL)known
{
	display_enabled = enabled;
	state_known = known;
	[self setNeedsDisplay:YES];
}

/**
 * drawRect:
 */
- (void)drawRect:(NSRect)dirtyRect
{
	NSColor *color;

	(void)dirtyRect;
	if (!state_known) {
		color = [NSColor windowBackgroundColor];
	} else {
		color = display_enabled ? [NSColor systemGreenColor] : [NSColor colorWithWhite:0.16 alpha:1.0];
	}
	[color setFill];
	NSRectFill([self bounds]);
}
@end

@interface MBAppDelegate : NSObject <NSApplicationDelegate> {
	NSWindow *window;
	MBDisplayStateView *state_view;
	NSButton *toggle_button;
	NSTextField *title_label;
	BOOL display_callback_registered;
}
- (void)displayConfigurationChanged;
@end

/**
 * display_reconfiguration_callback
 */
static void display_reconfiguration_callback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags,
    void *user_info)
{
	MBAppDelegate *delegate = (MBAppDelegate *)user_info;
	CGDisplayChangeSummaryFlags relevant_flags;

	(void)display;
	relevant_flags = kCGDisplayAddFlag | kCGDisplayRemoveFlag | kCGDisplayEnabledFlag | kCGDisplayDisabledFlag;
	if ((flags & kCGDisplayBeginConfigurationFlag) || !(flags & relevant_flags)) {
		return;
	}
	[delegate performSelectorOnMainThread:@selector(displayConfigurationChanged) withObject:nil waitUntilDone:NO];
}

@implementation MBAppDelegate
/**
 * setupMainMenu
 */
- (void)setupMainMenu
{
	NSMenu *main_menu;
	NSMenu *app_menu;
	NSMenu *window_menu;
	NSMenuItem *app_item;
	NSMenuItem *window_item;
	NSMenuItem *about_item;
	NSMenuItem *separator_item;
	NSMenuItem *quit_item;
	NSMenuItem *minimize_item;

	main_menu = [[NSMenu alloc] initWithTitle:@""];
	app_item = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
	app_menu = [[NSMenu alloc] initWithTitle:@"mbdispctl"];
	about_item = [[NSMenuItem alloc] initWithTitle:@"About mbdispctl" action:@selector(orderFrontStandardAboutPanel:)
	    keyEquivalent:@""];
	[about_item setTarget:NSApp];
	[app_menu addItem:about_item];
	separator_item = [NSMenuItem separatorItem];
	[app_menu addItem:separator_item];
	quit_item = [[NSMenuItem alloc] initWithTitle:@"Quit mbdispctl" action:@selector(terminate:) keyEquivalent:@"q"];
	[quit_item setTarget:NSApp];
	[quit_item setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
	[app_menu addItem:quit_item];
	[app_item setSubmenu:app_menu];
	[main_menu addItem:app_item];
	window_item = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
	window_menu = [[NSMenu alloc] initWithTitle:@"Window"];
	minimize_item = [[NSMenuItem alloc] initWithTitle:@"Minimize" action:@selector(performMiniaturize:)
	    keyEquivalent:@"m"];
	[minimize_item setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
	[window_menu addItem:minimize_item];
	[window_item setSubmenu:window_menu];
	[main_menu addItem:window_item];
	[NSApp setMainMenu:main_menu];
	[NSApp setWindowsMenu:window_menu];
	[minimize_item release];
	[window_menu release];
	[window_item release];
	[quit_item release];
	[about_item release];
	[app_menu release];
	[app_item release];
	[main_menu release];
}

/**
 * centerWindow
 */
- (void)centerWindow
{
	NSScreen *screen;
	NSRect screen_frame;
	NSRect window_frame;

	screen = [NSScreen mainScreen];
	if (screen == nil) {
		[window center];
		return;
	}
	screen_frame = [screen visibleFrame];
	window_frame = [window frame];
	window_frame.origin.x = NSMidX(screen_frame) - NSWidth(window_frame) / 2.0;
	window_frame.origin.y = NSMidY(screen_frame) - NSHeight(window_frame) / 2.0;
	[window setFrameOrigin:window_frame.origin];
}

/**
 * showError:
 */
- (void)showError:(const char *)error
{
	NSAlert *alert;
	NSString *text;

	text = error != NULL ? [NSString stringWithUTF8String:error] : nil;
	if (text == nil) {
		text = @"Unknown error";
	}
	alert = [[NSAlert alloc] init];
	[alert setMessageText:@"mbdispctl"];
	[alert setInformativeText:text];
	[alert setAlertStyle:NSAlertStyleWarning];
	[alert runModal];
	[alert release];
}

/**
 * refreshState:
 */
- (void)refreshState:(BOOL)show_error
{
	char error[256];
	bool enabled;

	if (builtin_display_get_enabled(&enabled, error, sizeof(error)) != 0) {
		[state_view setDisplayEnabled:NO known:NO];
		[toggle_button setEnabled:NO];
		[title_label setTextColor:[NSColor labelColor]];
		if (show_error) {
			[self showError:error];
		}
		return;
	}
	[state_view setDisplayEnabled:enabled known:YES];
	[toggle_button setEnabled:YES];
	[title_label setTextColor:enabled ? [NSColor colorWithWhite:0.10 alpha:1.0] : [NSColor whiteColor]];
	[toggle_button setTitle:enabled ? @"OFF" : @"ON"];
	[toggle_button setToolTip:enabled ? @"Disable internal display" : @"Enable internal display"];
	[toggle_button setBezelColor:enabled ? [NSColor systemRedColor] : [NSColor systemGreenColor]];
}

/**
 * displayConfigurationChanged
 */
- (void)displayConfigurationChanged
{
	[self refreshState:NO];
}

/**
 * toggleDisplay:
 */
- (void)toggleDisplay:(id)sender
{
	char error[256];
	bool enabled;

	(void)sender;
	if (builtin_display_get_enabled(&enabled, error, sizeof(error)) != 0) {
		[self showError:error];
		[self refreshState:NO];
		return;
	}
	if (builtin_display_set_enabled(!enabled, NULL, error, sizeof(error)) != 0) {
		[self showError:error];
		[self refreshState:NO];
		return;
	}
	[self refreshState:YES];
}

/**
 * applicationDidFinishLaunching:
 */
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSRect frame;
	NSRect label_frame;
	NSRect button_frame;
	NSWindowStyleMask style;
	CGError err;
	char error[256];

	(void)notification;
	[self setupMainMenu];
	frame = NSMakeRect(0.0, 0.0, WINDOW_WIDTH, WINDOW_HEIGHT);
	style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
	window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
	[window setTitle:@"mbdispctl"];
	[window setReleasedWhenClosed:NO];
	state_view = [[MBDisplayStateView alloc] initWithFrame:frame];
	[window setContentView:state_view];
	[state_view release];
	label_frame = NSMakeRect(0.0, WINDOW_HEIGHT - LABEL_HEIGHT - 18.0, WINDOW_WIDTH, LABEL_HEIGHT);
	title_label = [[NSTextField alloc] initWithFrame:label_frame];
	[title_label setStringValue:@"Internal Display"];
	[title_label setAlignment:NSTextAlignmentCenter];
	[title_label setBezeled:NO];
	[title_label setDrawsBackground:NO];
	[title_label setEditable:NO];
	[title_label setSelectable:NO];
	[title_label setFont:[NSFont boldSystemFontOfSize:18.0]];
	[state_view addSubview:title_label];
	[title_label release];
	button_frame = NSMakeRect((WINDOW_WIDTH - BUTTON_WIDTH) / 2.0, 32.0, BUTTON_WIDTH, BUTTON_HEIGHT);
	toggle_button = [[NSButton alloc] initWithFrame:button_frame];
	[toggle_button setButtonType:NSButtonTypeMomentaryPushIn];
	[toggle_button setBezelStyle:NSBezelStyleRounded];
	[toggle_button setFont:[NSFont boldSystemFontOfSize:22.0]];
	[toggle_button setTarget:self];
	[toggle_button setAction:@selector(toggleDisplay:)];
	[state_view addSubview:toggle_button];
	[toggle_button release];
	[self centerWindow];
	[window makeKeyAndOrderFront:nil];
	[NSApp activate];
	[self refreshState:YES];
	err = CGDisplayRegisterReconfigurationCallback(display_reconfiguration_callback, self);
	if (err == kCGErrorSuccess) {
		display_callback_registered = YES;
	} else {
		snprintf(error, sizeof(error), "CGDisplayRegisterReconfigurationCallback: error %d", (int)err);
		[self showError:error];
	}
}

/**
 * applicationDidBecomeActive:
 */
- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	(void)notification;
	if (window != nil) {
		[self refreshState:NO];
	}
}

/**
 * applicationShouldHandleReopen:hasVisibleWindows:
 */
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)has_visible_windows
{
	(void)sender;
	(void)has_visible_windows;
	if (window != nil) {
		if ([window isMiniaturized]) {
			[window deminiaturize:nil];
		}
		[window makeKeyAndOrderFront:nil];
		[self refreshState:NO];
	}
	return (NO);
}

/**
 * applicationShouldTerminateAfterLastWindowClosed:
 */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	(void)sender;
	return (YES);
}

/**
 * dealloc
 */
- (void)dealloc
{
	if (display_callback_registered) {
		CGDisplayRemoveReconfigurationCallback(display_reconfiguration_callback, self);
	}
	[window release];
	[super dealloc];
}
@end

/**
 * gui_run
 */
int gui_run(void)
{
	NSApplication *app;
	MBAppDelegate *delegate;

	@autoreleasepool {
		app = [NSApplication sharedApplication];
		[app setActivationPolicy:NSApplicationActivationPolicyRegular];
		delegate = [[MBAppDelegate alloc] init];
		[app setDelegate:delegate];
		[app run];
		[app setDelegate:nil];
		[delegate release];
	}
	return (0);
}
