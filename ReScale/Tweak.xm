#include "substrate.h"

#import <UIKit/UIKit.h>

extern "C" CFIndex _CFPreferencesGetAppIntegerValueWithContainer(CFStringRef key, CFStringRef applicationID, id container, Boolean *keyExistsAndHasValidFormat);

// MSHook(CFIndex, _CFPreferencesGetAppIntegerValueWithContainer, CFStringRef key, CFStringRef applicationID, id container, Boolean *keyExistsAndHasValidFormat) {
// 	if (CFStringCompare(applicationID, CFSTR("com.apple.iokit.IOMobileGraphicsFamily"), 0) == kCFCompareEqualTo) {
// 		NSLog(@"ReScale: %@ %@", (__bridge NSString*)applicationID, (__bridge NSString*)key);
// 		if (CFStringCompare(key, CFSTR("canvas_width"), 0) == kCFCompareEqualTo) {
// 			return CFPreferencesGetAppIntegerValue(key, CFSTR("tf.festival.rescale"), keyExistsAndHasValidFormat);
// 		}

// 		if (CFStringCompare(key, CFSTR("canvas_height"), 0) == kCFCompareEqualTo) {
// 			return CFPreferencesGetAppIntegerValue(key, CFSTR("tf.festival.rescale"), keyExistsAndHasValidFormat);
// 		}
// 	}

// 	return __CFPreferencesGetAppIntegerValueWithContainer(key, applicationID, container, keyExistsAndHasValidFormat);
// }

%hookf(CFIndex, _CFPreferencesGetAppIntegerValueWithContainer, CFStringRef key, CFStringRef applicationID, id container, Boolean *keyExistsAndHasValidFormat) {
	if (CFStringCompare(applicationID, CFSTR("com.apple.iokit.IOMobileGraphicsFamily"), 0) == kCFCompareEqualTo) {
		if (CFStringCompare(key, CFSTR("canvas_width"), 0) == kCFCompareEqualTo) {
			return CFPreferencesGetAppIntegerValue(key, CFSTR("tf.festival.rescale"), keyExistsAndHasValidFormat);
		}

		if (CFStringCompare(key, CFSTR("canvas_height"), 0) == kCFCompareEqualTo) {
			return CFPreferencesGetAppIntegerValue(key, CFSTR("tf.festival.rescale"), keyExistsAndHasValidFormat);
		}
	}

	return %orig;
}

%ctor {
	if (access("/var/lib/dpkg/info/tf.festival.rescale2.list", F_OK) == -1) return;

	%init();
}