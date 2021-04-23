#include <substrate.h>
#include <dlfcn.h>

#import <UIKit/UIKit.h>

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