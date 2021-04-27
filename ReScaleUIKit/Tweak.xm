#import "Tweak.h"

NSString* ReScaleLocalizedString(NSString* key, NSString* value, NSString* table = @"Root") {
	static NSBundle* localizableBundle = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		localizableBundle = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/ReScalePreferences.bundle"];
	});

	return [localizableBundle localizedStringForKey:key value:value table:table];
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)arg1 {
	%orig;

	NSInteger canvasWidth = CFPreferencesGetAppIntegerValue(CFSTR("canvas_width"), CFSTR("tf.festival.rescale"), NULL);
	NSInteger canvasHeight = CFPreferencesGetAppIntegerValue(CFSTR("canvas_height"), CFSTR("tf.festival.rescale"), NULL);

	if ((canvasWidth && canvasHeight) && !CFPreferencesGetAppBooleanValue(CFSTR("confirmedResolution"), CFSTR("tf.festival.rescale"), NULL)) {
		__block NSTimer* countdownTimer;
		__block int countdownSecondsRemaining = 30;

if (@available(iOS 13, *)) {
		[[[[%c(SBLockScreenManager) sharedInstance] coverSheetViewController] idleTimerController] addIdleTimerDisabledAssertionReason:@"tf.festival.rescale2.reset-resolution"];
} else {
		[[[%c(SBLockScreenManager) sharedInstance] dashBoardViewController] addIdleTimerDisabledAssertionReason:@"tf.festival.rescale2.reset-resolution"];
}

		UIAlertController* resetDialog = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:ReScaleLocalizedString(@"RESOLUTION_APPLIED_TITLE", nil), canvasWidth, canvasHeight]
																			 message:ReScaleLocalizedString(@"RESOLUTION_APPLIED_PROMPT", nil)
																	  preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:ReScaleLocalizedString(@"GENERIC_CONFIRM", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			CFPreferencesSetAppValue(CFSTR("confirmedResolution"), (CFTypeRef)@YES, CFSTR("tf.festival.rescale"));
			CFPreferencesAppSynchronize(CFSTR("tf.festival.rescale"));

if (@available(iOS 13, *)) {
			[[[[%c(SBLockScreenManager) sharedInstance] coverSheetViewController] idleTimerController] removeIdleTimerDisabledAssertionReason:@"tf.festival.rescale2.reset-resolution"];
} else {
			[[[%c(SBLockScreenManager) sharedInstance] dashBoardViewController] removeIdleTimerDisabledAssertionReason:@"tf.festival.rescale2.reset-resolution"];
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
			CFPreferencesAppSynchronize(CFSTR("tf.festival.rescale"));

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
				[resetDialog _dismissAnimated:YES triggeringAction:cancelAction];

				return;
			}
		}];
	}
}
%end

%hook _UIStatusBarVisualProvider_iOS
+ (Class)visualProviderSubclassForScreen:(id)arg1 {
	NSString* visualProvider = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("statusBarOverride"), CFSTR("tf.festival.rescale"));
	if (visualProvider && NSClassFromString(visualProvider)) {
		return NSClassFromString(visualProvider);
	}

	return %orig;
}

+ (Class)visualProviderSubclassForScreen:(id)arg1 visualProviderInfo:(id)arg2 {
	NSString* visualProvider = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("statusBarOverride"), CFSTR("tf.festival.rescale"));
	if (visualProvider && NSClassFromString(visualProvider)) {
		return NSClassFromString(visualProvider);
	}

	return %orig;
}
%end

%ctor {
	if (access("/var/lib/dpkg/info/tf.festival.rescale2.list", F_OK) == -1) return;

	%init();
}