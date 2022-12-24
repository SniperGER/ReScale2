#import "Tweak.h"

NSString* ReScaleLocalizedString(NSString* key, NSString* value, NSString* table = @"Root") {
	static NSBundle* localizableBundle = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		localizableBundle = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/ReScalePreferences.bundle"];
	});

	return [localizableBundle localizedStringForKey:key value:value table:table];
}

%group SpringBoard
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)arg1 {
	%orig;

	// Should not have used this in the first place. Sorry, @everyone!
	[idleTimerDefaults setDisableAutoDim:NO];

	NSInteger canvasWidth = CFPreferencesGetAppIntegerValue(CFSTR("canvas_width"), CFSTR("tf.festival.rescale"), NULL);
	NSInteger canvasHeight = CFPreferencesGetAppIntegerValue(CFSTR("canvas_height"), CFSTR("tf.festival.rescale"), NULL);

	if ((canvasWidth && canvasHeight) && !CFPreferencesGetAppBooleanValue(CFSTR("confirmedResolution"), CFSTR("tf.festival.rescale"), NULL)) {
		__block NSTimer* countdownTimer;
		__block int countdownSecondsRemaining = 30;

		UIAlertController* resetDialog = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:ReScaleLocalizedString(@"RESOLUTION_APPLIED_TITLE", nil), canvasWidth, canvasHeight]
																			 message:ReScaleLocalizedString(@"RESOLUTION_APPLIED_PROMPT", nil)
																	  preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:ReScaleLocalizedString(@"GENERIC_CONFIRM", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			CFPreferencesSetAppValue(CFSTR("confirmedResolution"), (CFTypeRef)@YES, CFSTR("tf.festival.rescale"));
			CFPreferencesAppSynchronize(CFSTR("tf.festival.rescale"));

			if (@available(iOS 13, *)) {
				[[%c(SBIdleTimerGlobalStateMonitor) sharedInstance] _updateAutoDimDisabled];
			} else if (@available(iOS 12, *)) {
				[[%c(SBIdleTimerGlobalCoordinator) sharedInstance] _updateAutoDimDisableAssertion];
			} else if (@available(iOS 111, *)) {
				[[%c(SBIdleTimerGlobalCoordinator) sharedInstance] _idleTimerPrefsChanged];
			} else {
				[[%c(SBBacklightController) sharedInstance] autoLockPrefsChanged];
			}

			if (countdownTimer) {
				[countdownTimer invalidate];
				countdownTimer = nil;
			}
		}];
		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:ReScaleLocalizedString(@"RESOLUTION_APPLIED_CANCEL", nil), countdownSecondsRemaining] style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
			CFPreferencesSetAppValue(CFSTR("canvas_width"), NULL, CFSTR("tf.festival.rescale"));
			CFPreferencesSetAppValue(CFSTR("canvas_height"), NULL, CFSTR("tf.festival.rescale"));
			CFPreferencesSetAppValue(CFSTR("confirmedResolution"), NULL, CFSTR("tf.festival.rescale"));
			CFPreferencesSetAppValue(CFSTR("statusBarOverride"), NULL, CFSTR("tf.festival.rescale"));
			CFPreferencesAppSynchronize(CFSTR("tf.festival.rescale"));

			if (@available(iOS 13, *)) {
				[[%c(SBIdleTimerGlobalStateMonitor) sharedInstance] _updateAutoDimDisabled];
			} else if (@available(iOS 12, *)) {
				[[%c(SBIdleTimerGlobalCoordinator) sharedInstance] _updateAutoDimDisableAssertion];
			} else if (@available(iOS 111, *)) {
				[[%c(SBIdleTimerGlobalCoordinator) sharedInstance] _idleTimerPrefsChanged];
			} else {
				[[%c(SBBacklightController) sharedInstance] autoLockPrefsChanged];
			}

			pid_t pid;
			int status;
			const char* args[] = {"killall", "-9", "backboardd", "aggregated", NULL};
			posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
			waitpid(pid, &status, WEXITED);
		}];

		[resetDialog addAction:confirmAction];
		[resetDialog addAction:cancelAction];

		if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
			[UIApplication.sharedApplication.windows enumerateObjectsUsingBlock:^(UIWindow* window, NSUInteger index, BOOL* stop) {
				if ([window isKindOfClass:%c(SBCoverSheetWindow)]) {
					[window.rootViewController presentViewController:resetDialog animated:YES completion:nil];
					*stop = YES;
				}
			}];
		} else {
			[UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:resetDialog animated:YES completion:nil];
		}

		countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer* timer) {
			[cancelAction setValue:[NSString stringWithFormat:ReScaleLocalizedString(@"RESOLUTION_APPLIED_CANCEL", nil), --countdownSecondsRemaining] forKeyPath:@"title"];

			if (countdownSecondsRemaining <= 0) {
				[timer invalidate];
				// [resetDialog _dismissAnimated:YES triggeringAction:cancelAction];
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

				return;
			}
		}];
	}
}
%end	/// %hook SpringBoard

%hook SBIdleTimerDefaults
- (id)init {
	idleTimerDefaults = %orig;
	return idleTimerDefaults;
}

- (BOOL)disableAutoDim {
	NSInteger canvasWidth = CFPreferencesGetAppIntegerValue(CFSTR("canvas_width"), CFSTR("tf.festival.rescale"), NULL);
	NSInteger canvasHeight = CFPreferencesGetAppIntegerValue(CFSTR("canvas_height"), CFSTR("tf.festival.rescale"), NULL);

	if ((canvasWidth && canvasHeight) && !CFPreferencesGetAppBooleanValue(CFSTR("confirmedResolution"), CFSTR("tf.festival.rescale"), NULL)) {
		return YES;
	}

	return %orig;
}
%end	/// %hook SBIdleTimerDefaults
%end	// %group SpringBoard

%group Applications
%hook _UIStatusBarVisualProvider_iOS
+ (Class)visualProviderSubclassForScreen:(id)arg1 {
	NSString* visualProvider = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("statusBarOverride"), CFSTR("tf.festival.rescale"));
	if (visualProvider && NSClassFromString(visualProvider)) {
		return NSClassFromString(visualProvider);
	} else {
		if (!NSClassFromString(visualProvider)) {
			NSLog(@"[ReScale2] no status bar provider for class %@", visualProvider);
		}
	}

	return %orig;
}

+ (Class)visualProviderSubclassForScreen:(id)arg1 visualProviderInfo:(id)arg2 {
	NSString* visualProvider = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("statusBarOverride"), CFSTR("tf.festival.rescale"));
	if (visualProvider && NSClassFromString(visualProvider)) {
		return NSClassFromString(visualProvider);
	} else {
		if (!NSClassFromString(visualProvider)) {
			NSLog(@"[ReScale2] no status bar provider for class %@", visualProvider);
		}
	}

	return %orig;
}
%end	/// %hook _UIStatusBarVisualProvider_iOS
%end	// %group Applications

%ctor {
	if (access("/var/lib/dpkg/info/tf.festival.rescale2.list", F_OK) == -1) return;

	if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
		%init(SpringBoard)
	}

	if (UIApplication.sharedApplication) {
		%init(Applications);
	}
}