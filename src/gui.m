#import <AppKit/AppKit.h>

#include "builtin_display.h"
#include "gui.h"

#define WINDOW_WIDTH 300.0
#define WINDOW_HEIGHT 160.0
#define BUTTON_WIDTH 140.0
#define BUTTON_HEIGHT 52.0

@interface MBDisplayStateView : NSView {
	BOOL state_known;
	BOOL display_enabled;
}
- (void)setDisplayEnabled:(BOOL)enabled known:(BOOL)known;
@end

@implementation MBDisplayStateView
- (void)setDisplayEnabled:(BOOL)enabled known:(BOOL)known
{
	display_enabled = enabled;
	state_known = known;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSColor *color;

	(void)dirtyRect;
	if (!state_known) {
		color = [NSColor windowBackgroundColor];
	} else {
		color = display_enabled ? [NSColor systemGreenColor] : [NSColor systemRedColor];
	}
	[color setFill];
	NSRectFill([self bounds]);
}
@end

@interface MBAppDelegate : NSObject <NSApplicationDelegate> {
	NSWindow *window;
	MBDisplayStateView *state_view;
	NSButton *toggle_button;
}
@end

@implementation MBAppDelegate
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

- (void)refreshState:(BOOL)show_error
{
	char error[256];
	bool enabled;

	if (builtin_display_get_enabled(&enabled, error, sizeof(error)) != 0) {
		[state_view setDisplayEnabled:NO known:NO];
		[toggle_button setEnabled:NO];
		if (show_error) {
			[self showError:error];
		}
		return;
	}
	[state_view setDisplayEnabled:enabled known:YES];
	[toggle_button setEnabled:YES];
	[toggle_button setTitle:enabled ? @"OFF" : @"ON"];
	[toggle_button setBezelColor:enabled ? [NSColor systemRedColor] : [NSColor systemGreenColor]];
}

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

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSRect frame;
	NSRect button_frame;
	NSWindowStyleMask style;

	(void)notification;
	frame = NSMakeRect(0.0, 0.0, WINDOW_WIDTH, WINDOW_HEIGHT);
	style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
	window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
	[window setTitle:@"mbdispctl"];
	[window setReleasedWhenClosed:NO];
	state_view = [[MBDisplayStateView alloc] initWithFrame:frame];
	[window setContentView:state_view];
	[state_view release];
	button_frame = NSMakeRect((WINDOW_WIDTH - BUTTON_WIDTH) / 2.0, (WINDOW_HEIGHT - BUTTON_HEIGHT) / 2.0,
	    BUTTON_WIDTH, BUTTON_HEIGHT);
	toggle_button = [[NSButton alloc] initWithFrame:button_frame];
	[toggle_button setButtonType:NSButtonTypeMomentaryPushIn];
	[toggle_button setBezelStyle:NSBezelStyleRounded];
	[toggle_button setFont:[NSFont boldSystemFontOfSize:22.0]];
	[toggle_button setTarget:self];
	[toggle_button setAction:@selector(toggleDisplay:)];
	[state_view addSubview:toggle_button];
	[toggle_button release];
	[window center];
	[window makeKeyAndOrderFront:nil];
	[NSApp activate];
	[self refreshState:YES];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	(void)notification;
	if (window != nil) {
		[self refreshState:NO];
	}
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	(void)sender;
	return YES;
}

- (void)dealloc
{
	[window release];
	[super dealloc];
}
@end

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
	return 0;
}
