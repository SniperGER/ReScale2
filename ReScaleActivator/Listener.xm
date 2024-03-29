#include <objc/runtime.h>
#include <dlfcn.h>
#include <spawn.h>
#import <libactivator/libactivator.h>

static NSString *bundleID = @"tf.festival.rescale2.activator-eventListener";
static LAActivator *_LASharedActivator;

@interface ReScaleActivatorListener : NSObject <LAListener>

+ (id)sharedInstance;

@end

@implementation ReScaleActivatorListener

+ (instancetype)sharedInstance {
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

+ (void)load {
	void *la = dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	if (!la) {
		NSLog(@"Failed to load libactivator");
		_LASharedActivator = nil;
	} else {
		_LASharedActivator = [objc_getClass("LAActivator") sharedInstance];
	}

	[self sharedInstance];
}

- (instancetype)init {
	if ([super init]) {
		// Register our listener
		if (_LASharedActivator) {
			if (_LASharedActivator.isRunningInsideSpringBoard) {
				[_LASharedActivator registerListener:self forName:bundleID];
			}
		}
	}
	return self;
}

- (void)dealloc {
	if (_LASharedActivator) {
		if (_LASharedActivator.runningInsideSpringBoard) {
			[_LASharedActivator unregisterListenerWithName:bundleID];
		}
	}
}

// Listener custom methods

- (BOOL)present {
	return NO;
}

- (BOOL)dismiss {
	return NO;
}

// LAListener protocol methods

- (void)activator:(LAActivator *)activator didChangeToEventMode:(NSString *)eventMode {
	[self dismiss];

}

// Incoming events

// Normal assigned events
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
	// Called when we receive event

	NSInteger canvasWidth = CFPreferencesGetAppIntegerValue(CFSTR("canvas_width"), CFSTR("tf.festival.rescale"), NULL);
	NSInteger canvasHeight = CFPreferencesGetAppIntegerValue(CFSTR("canvas_height"), CFSTR("tf.festival.rescale"), NULL);

	if (canvasWidth && canvasHeight) {
		if ([self present]) {
			[event setHandled:YES];
		}

		CFPreferencesSetAppValue(CFSTR("canvas_width"), NULL, CFSTR("tf.festival.rescale"));
		CFPreferencesSetAppValue(CFSTR("canvas_height"), NULL, CFSTR("tf.festival.rescale"));
		CFPreferencesSetAppValue(CFSTR("confirmedResolution"), NULL, CFSTR("tf.festival.rescale"));
		CFPreferencesSetAppValue(CFSTR("statusBarOverride"), NULL, CFSTR("tf.festival.rescale"));
		CFPreferencesAppSynchronize(CFSTR("tf.festival.rescale"));

		pid_t pid;
		int status;
		const char* args[] = {"killall", "-9", "backboardd", "aggregated", NULL};
		posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
		waitpid(pid, &status, WEXITED);
	} else {
		if ([self present]) {
			[event setHandled:YES];
		}
	}
}
// Sent when a chorded event gets escalated (short hold becoems a long hold, for example)
- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
	// Called when event is escalated to a higher event
	// (short-hold sleep button becomes long-hold shutdown menu, etc)
	[self dismiss];
}
// Sent at the lock screen when listener is not compatible with event, but potentially is able to unlock the screen to handle it
- (BOOL)activator:(LAActivator *)activator receiveUnlockingDeviceEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
	// return YES if this listener handles unlocking the device
	return NO;
}
// Sent when the menu button is pressed. Only handle if you want to suppress the standard menu button behaviour!
- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
	// Called when the home button is pressed.
	// If (and only if) we are showing UI, we should dismiss it and call setHandled:
	if ([self dismiss]) {
		[event setHandled:YES];
	}
}
// Sent when another listener has handled the event
- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event {
	// Called when some other listener received an event; we should cleanup
	[self dismiss];
}
// Sent from the settings pane when a listener is assigned
- (void)activator:(LAActivator *)activator receivePreviewEventForListenerName:(NSString *)listenerName {

}

// Metadata (may be cached)
// Listener name
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
	return @"Reset Resolution";
}
// Listener description
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
	return @"Reset the resolution to default";
}
// Group name
- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
	return @"Re:Scale 2";
}
// Prevent unassignment when trying to unassign the last event
- (NSNumber *)activator:(LAActivator *)activator requiresRequiresAssignmentForListenerName:(NSString *)listenerName {
	// Return YES if you need at least one assignment
	return [NSNumber numberWithBool:NO];
}
// Compatible event modes
- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
	return [NSArray arrayWithObjects:@"springboard", @"lockscreen", @"application", nil];
}
// Compatibility with events
- (NSNumber *)activator:(LAActivator *)activator requiresIsCompatibleWithEventName:(NSString *)eventName listenerName:(NSString *)listenerName {
	return [NSNumber numberWithBool:YES];
}
// Group assignment filtering
- (NSArray *)activator:(LAActivator *)activator requiresExclusiveAssignmentGroupsForListenerName:(NSString *)listenerName {
	return [NSArray array];
}
// Key querying
- (id)activator:(LAActivator *)activator requiresInfoDictionaryValueOfKey:(NSString *)key forListenerWithName:(NSString *)listenerName {
	NSLog(@"requiresInfoDictionaryValueOfKey: %@", key);
	return nil;
}
// Powered display
- (BOOL)activator:(LAActivator *)activator requiresNeedsPoweredDisplayForListenerName:(NSString *)listenerName {
	// Called when the listener is incompatible with the lockscreen event mode
	// Return YES if you need the display to be powered
	return YES;
}

// Icons

//  Fast path that supports scale
- (NSData *)activator:(LAActivator *)activator requiresIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
	return nil;
}
- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
	return nil;
}
//  Legacy
- (NSData *)activator:(LAActivator *)activator requiresIconDataForListenerName:(NSString *)listenerName {
	return nil;
}
- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName {
	return nil;
}
//  For cases where PNG data isn't available quickly
- (UIImage *)activator:(LAActivator *)activator requiresIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale {
	return nil;
}
- (UIImage *)activator:(LAActivator *)activator requiresSmallIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale {
	return nil;
}
// Glyph
- (id)activator:(LAActivator *)activator requiresGlyphImageDescriptorForListenerName:(NSString *)listenerName {
	return nil;
}

// Removal (useful for dynamic listeners)

- (BOOL)activator:(LAActivator *)activator requiresSupportsRemovalForListenerWithName:(NSString *)listenerName {
	// if YES, activator:requestsRemovalForListenerWithName: will be called
	return NO;
}
- (void)activator:(LAActivator *)activator requestsRemovalForListenerWithName:(NSString *)listenerName {
	// Get rid of the listener object
	return;
}

// Configuration view controller

- (NSString *)activator:(LAActivator *)activator requiresConfigurationViewControllerClassNameForListenerWithName:(NSString *)listenerName bundle:(NSBundle **)outBundle {
	*outBundle = [NSBundle bundleWithPath:@"/this/should/not/exist.bundle"];
	return nil;
}
- (id)activator:(LAActivator *)activator requestsConfigurationForListenerWithName:(NSString *)listenerName {
	return nil;
}
- (void)activator:(LAActivator *)activator didSaveNewConfiguration:(id)configuration forListenerWithName:(NSString *)listenerName {
	return;
}

@end
