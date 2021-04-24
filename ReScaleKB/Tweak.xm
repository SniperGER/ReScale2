#include <substrate.h>
#include <dlfcn.h>

#import <UIKit/UIKit.h>

@interface UIKeyboardImpl : UIView
+ (UIEdgeInsets)deviceSpecificPaddingForInterfaceOrientation:(NSInteger)arg1 inputMode:(id)arg2;
+ (CGSize)defaultSizeForInterfaceOrientation:(UIInterfaceOrientation)arg1;
+ (CGSize)keyboardSizeForInterfaceOrientation:(UIInterfaceOrientation)arg1;
+ (CGSize)sizeForInterfaceOrientation:(UIInterfaceOrientation)arg1;
@end

%hook UIKeyboardImpl
+ (CGSize)defaultSizeForInterfaceOrientation:(UIInterfaceOrientation)arg1 {
	CGSize r = %orig;

	if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		return (CGSize){ CGRectInset(UIScreen.mainScreen.bounds, [self deviceSpecificPaddingForInterfaceOrientation:arg1 inputMode:nil].left, 0).size.width, r.height };
	}

	return r;
}

+ (CGSize)keyboardSizeForInterfaceOrientation:(UIInterfaceOrientation)arg1 {
	CGSize r = %orig;

	if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		return (CGSize){ CGRectInset(UIScreen.mainScreen.bounds, [self deviceSpecificPaddingForInterfaceOrientation:arg1 inputMode:nil].left, 0).size.width, r.height };
	}

	return r;
}

+ (CGSize)sizeForInterfaceOrientation:(UIInterfaceOrientation)arg1 {
	CGSize r = %orig;

	if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		return (CGSize){ CGRectInset(UIScreen.mainScreen.bounds, [self deviceSpecificPaddingForInterfaceOrientation:arg1 inputMode:nil].left, 0).size.width, r.height };
	}

	return r;
}
%end

%hook UIKeyboardLayoutStar
- (void)setFrame:(CGRect)arg1 {
	if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)) {
		%orig((CGRect){ CGPointZero, [UIKeyboardImpl keyboardSizeForInterfaceOrientation:UIApplication.sharedApplication.statusBarOrientation] });

		return;
	}

	%orig;
}
%end

%ctor {
	if (access("/var/lib/dpkg/info/tf.festival.rescale2.list", F_OK) == -1) return;

	%init();
}