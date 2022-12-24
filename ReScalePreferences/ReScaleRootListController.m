#include <spawn.h>

#include "ReScaleRootListController.h"

@implementation ReScaleRootListController

+ (NSString*)localizedStringForKey:(NSString*)key value:(NSString*)value table:(NSString*)table {
	static NSBundle* bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundle = [NSBundle bundleForClass:self];
    });

	return [bundle localizedStringForKey:key value:value table:table];
}

- (void)reloadSpecifiers {
	[super reloadSpecifiers];

	_resolutions = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"Resolutions" ofType:@"plist"]];

	PSSpecifier* iphoneGroupSpecifier = [self specifierForID:@"IPHONE"];
	PSSpecifier* ipadGroupSpecifier = [self specifierForID:@"IPAD"];

	[[[[_resolutions objectForKey:@"0"] reverseObjectEnumerator] allObjects] enumerateObjectsUsingBlock:^(NSDictionary* resolution, NSUInteger index, BOOL* stop) {
		PSSpecifier* resolutionSpecifier = [PSSpecifier preferenceSpecifierNamed:[[NSBundle bundleForClass:self.class] localizedStringForKey:resolution[@"deviceType"] value:nil table:@"Root"]
																		  target:self
																		     set:nil
																		     get:nil
																		  detail:nil
																		    cell:PSButtonCell
																			edit:nil];
		[resolutionSpecifier setButtonAction:@selector(applyResolutionFromSpecifier:)];

		BOOL isSupported = YES;

		if (resolution[@"minOSVersion"]) {
			isSupported = isSupported && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(resolution[@"minOSVersion"]);
		}

		[self insertSpecifier:resolutionSpecifier afterSpecifier:iphoneGroupSpecifier];
	}];

	[[[[_resolutions objectForKey:@"1"] reverseObjectEnumerator] allObjects] enumerateObjectsUsingBlock:^(NSDictionary* resolution, NSUInteger index, BOOL* stop) {
		PSSpecifier* resolutionSpecifier = [PSSpecifier preferenceSpecifierNamed:[[NSBundle bundleForClass:self.class] localizedStringForKey:resolution[@"deviceType"] value:nil table:@"Root"]

																		  target:self
																		     set:nil
																		     get:nil
																		  detail:nil
																		    cell:PSButtonCell
																			edit:nil];
		[resolutionSpecifier setButtonAction:@selector(applyResolutionFromSpecifier:)];

		BOOL isSupported = YES;

		if (resolution[@"minOSVersion"]) {
			isSupported = isSupported && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(resolution[@"minOSVersion"]);
		}

		[self insertSpecifier:resolutionSpecifier afterSpecifier:ipadGroupSpecifier];
	}];
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[self reloadSpecifiers];
}

#pragma mark - Instance Methods

- (void)applyCanvasWidth:(NSUInteger)canvasWidth canvasHeight:(NSUInteger)canvasHeight {
	// if (SYSTEM_VERSION_LESS_THAN(@"10.0")) {
	// 	// iOS 9 (possibily other versions as well) invert the width and height
	// 	CFPreferencesSetAppValue(CFSTR("canvas_height"), (CFTypeRef)@(canvasWidth), CFSTR("tf.festival.rescale"));
	// 	CFPreferencesSetAppValue(CFSTR("canvas_width"), (CFTypeRef)@(canvasHeight), CFSTR("tf.festival.rescale"));
	// } else {
		CFPreferencesSetAppValue(CFSTR("canvas_width"), (CFTypeRef)@(canvasWidth), CFSTR("tf.festival.rescale"));
		CFPreferencesSetAppValue(CFSTR("canvas_height"), (CFTypeRef)@(canvasHeight), CFSTR("tf.festival.rescale"));

		CFPreferencesSetAppValue(CFSTR("confirmedResolution"), (CFTypeRef)@NO, CFSTR("tf.festival.rescale"));
	// }

	CFPreferencesAppSynchronize(CFSTR("tf.festival.rescale"));
}

- (void)applyCustomResolution {
	[self.view endEditing:YES];

	if (!_customCanvasWidth ||
		!_customCanvasHeight ||
		_customCanvasWidth < CGRectGetWidth(UIScreen.mainScreen.nativeBounds) / UIScreen.mainScreen.scale ||
		_customCanvasHeight < CGRectGetHeight(UIScreen.mainScreen.nativeBounds) / UIScreen.mainScreen.scale) {

		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[self.class localizedStringForKey:@"CUSTOM_RESOLUTION_INVALID_TITLE" value:nil table:@"Root"]
																				 message:[NSString stringWithFormat:[self.class localizedStringForKey:@"CUSTOM_RESOLUTION_INVALID_DESCRIPTION" value:nil table:@"Root"], _customCanvasWidth, _customCanvasHeight, UIScreen.mainScreen.scale]
																		  preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleDefault handler:nil];

		[alertController addAction:confirmAction];
		[self presentViewController:alertController animated:YES completion:nil];

		return;
	}

	BOOL isiPad = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;

	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[self.class localizedStringForKey:@"CUSTOM_RESOLUTION_TITLE" value:nil table:@"Root"]
																			 message:[NSString stringWithFormat:[self.class localizedStringForKey:@"APPLY_RESOLUTION_PROMPT" value:nil table:@"Root"], _customCanvasWidth, _customCanvasHeight]
																	  preferredStyle:(isiPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet)];

	UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"APPLY_RESOLUTION_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
		[self applyCanvasWidth:_customCanvasWidth canvasHeight:_customCanvasHeight];

		[self respring];
	}];
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CANCEL" value:nil table:@"Root"] style:UIAlertActionStyleCancel handler:nil];

	[alertController addAction:confirmAction];
	[alertController addAction:cancelAction];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)applyResolutionFromSpecifier:(PSSpecifier*)specifier {
	NSInteger phoneGroupIndex = [self indexOfSpecifier:specifier] - [self indexOfSpecifier:[self specifierForID:@"IPHONE"]];
	NSInteger padGroupIndex = [self indexOfSpecifier:specifier] - [self indexOfSpecifier:[self specifierForID:@"IPAD"]];

	if (padGroupIndex < 0) {
		[self confirmResolution:[_resolutions[@"0"] objectAtIndex:phoneGroupIndex - 1] forInterfaceIdiom:UIUserInterfaceIdiomPhone];
	} else {
		[self confirmResolution:[_resolutions[@"1"] objectAtIndex:padGroupIndex - 1] forInterfaceIdiom:UIUserInterfaceIdiomPad];
	}
}

- (void)confirmResolution:(NSDictionary*)resolution forInterfaceIdiom:(UIUserInterfaceIdiom)interfaceIdiom {
	NSUInteger canvasWidth = [resolution[@"canvas_width"] integerValue],
			   canvasHeight = [resolution[@"canvas_height"] integerValue];
	CGFloat screenScale = [resolution[@"screenScale"] integerValue];

	NSString* minOSVersion = resolution[@"minOSVersion"];
	NSString* maxOSVersion = resolution[@"maxOSVersion"];


	BOOL isiPad = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;
	BOOL isSupported = (UIDevice.currentDevice.userInterfaceIdiom == interfaceIdiom);

	if (minOSVersion) {
		isSupported = isSupported && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(minOSVersion);
	}

	if (maxOSVersion) {
		isSupported = isSupported && SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(maxOSVersion);
	}

	if (!isSupported) {
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[self.class localizedStringForKey:@"NOT_SUPPORTED_TITLE" value:nil table:@"Root"]
																				message:[NSString stringWithFormat:[self.class localizedStringForKey:@"NOT_SUPPORTED_DESCRIPTION" value:nil table:@"Root"], canvasWidth, canvasHeight, screenScale]
																		preferredStyle:(isiPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet)];

		UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"NOT_SUPPORTED_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
			[self applyCanvasWidth:canvasWidth canvasHeight:canvasHeight];

			[self respring];
		}];
		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CANCEL" value:nil table:@"Root"] style:UIAlertActionStyleCancel handler:nil];

		[alertController addAction:confirmAction];
		[alertController addAction:cancelAction];
		[self presentViewController:alertController animated:YES completion:nil];

		return;
	}

	if (screenScale != UIScreen.mainScreen.scale) {
		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[self.class localizedStringForKey:@"SCALE_MISMATCH_TITLE" value:nil table:@"Root"]
																				message:[NSString stringWithFormat:[self.class localizedStringForKey:@"SCALE_MISMATCH_PROMPT" value:nil table:@"Root"], canvasWidth, canvasHeight, screenScale, UIScreen.mainScreen.scale]
																		preferredStyle:(isiPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet)];

		UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
			NSInteger width = floorf((canvasWidth / screenScale) * UIScreen.mainScreen.scale);
			NSInteger height = floorf((canvasHeight / screenScale) * UIScreen.mainScreen.scale);

			[self applyCanvasWidth:width canvasHeight:height];
			[self respring];
		}];

		UIAlertAction* unmodifiedResolutionAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"SCALE_MISMATCH_USE_RESOLUTION" value:nil table:@"Root"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
			[self applyCanvasWidth:canvasWidth canvasHeight:canvasHeight];
			[self respring];
		}];

		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CANCEL" value:nil table:@"Root"] style:UIAlertActionStyleCancel handler:nil];

		[alertController addAction:confirmAction];
		[alertController addAction:unmodifiedResolutionAction];
		[alertController addAction:cancelAction];
		[self presentViewController:alertController animated:YES completion:nil];

		return;
	}

	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[self.class localizedStringForKey:@"APPLY_RESOLUTION_TITLE" value:nil table:@"Root"]
																			 message:[NSString stringWithFormat:[self.class localizedStringForKey:@"APPLY_RESOLUTION_PROMPT" value:nil table:@"Root"], canvasWidth, canvasHeight, screenScale]
																	  preferredStyle:(isiPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet)];

	UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"APPLY_RESOLUTION_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[self applyCanvasWidth:canvasWidth canvasHeight:canvasHeight];
		[self respring];
	}];

	UIAlertAction* confirmInvertedAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"APPLY_RESOLUTION_CONFIRM_INVERTED" value:nil table:@"Root"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
		[self applyCanvasWidth:canvasHeight canvasHeight:canvasWidth];
		[self respring];
	}];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CANCEL" value:nil table:@"Root"] style:UIAlertActionStyleCancel handler:nil];

	[alertController addAction:confirmAction];

	if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		[alertController addAction:confirmInvertedAction];
	}

	[alertController addAction:cancelAction];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (id)getCustomCanvasHeight {
    return _customCanvasHeight ? @(_customCanvasHeight) : nil;
}

- (id)getCustomCanvasWidth {
    return _customCanvasWidth ? @(_customCanvasWidth) : nil;
}

- (void)resetResolution {
	BOOL isiPad = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;

	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[self.class localizedStringForKey:@"RESET_RESOLUTION_TITLE" value:nil table:@"Root"]
																			 message:[self.class localizedStringForKey:@"RESET_RESOLUTION_PROMPT" value:nil table:@"Root"]
																	  preferredStyle:(isiPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet)];

	UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"RESET_RESOLUTION_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
		CFPreferencesSetAppValue(CFSTR("canvas_width"), NULL, CFSTR("tf.festival.rescale"));
		CFPreferencesSetAppValue(CFSTR("canvas_height"), NULL, CFSTR("tf.festival.rescale"));

		CFPreferencesAppSynchronize(CFSTR("tf.festival.rescale"));

		[self respring];
	}];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CANCEL" value:nil table:@"Root"] style:UIAlertActionStyleCancel handler:nil];

	[alertController addAction:confirmAction];
	[alertController addAction:cancelAction];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)respring {
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[self.class localizedStringForKey:@"RESTART_SPRINGBOARD_TITLE" value:nil table:@"Root"]
																			 message:[self.class localizedStringForKey:@"RESTART_SPRINGBOARD_PROMPT" value:nil table:@"Root"]
																	  preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"RESTART_SPRINGBOARD_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
		pid_t pid;
		int status;
		const char* args[] = {"killall", "-9", "backboardd", "aggregated", NULL};
		posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
		waitpid(pid, &status, WEXITED);
	}];
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"RESTART_SPRINGBOARD_CANCEL" value:nil table:@"Root"] style:UIAlertActionStyleCancel handler:nil];

	[alertController addAction:confirmAction];
	[alertController addAction:cancelAction];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)saveCustomResolution {
	[self.view endEditing:YES];

	if (!_customCanvasWidth ||
		!_customCanvasHeight ||
		_customCanvasWidth < CGRectGetWidth(UIScreen.mainScreen.nativeBounds) / UIScreen.mainScreen.scale ||
		_customCanvasHeight < CGRectGetHeight(UIScreen.mainScreen.nativeBounds) / UIScreen.mainScreen.scale) {

		UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[self.class localizedStringForKey:@"CUSTOM_RESOLUTION_INVALID_TITLE" value:nil table:@"Root"]
																				 message:[NSString stringWithFormat:[self.class localizedStringForKey:@"CUSTOM_RESOLUTION_INVALID_DESCRIPTION" value:nil table:@"Root"], _customCanvasWidth, _customCanvasHeight, UIScreen.mainScreen.scale]
																		  preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleDefault handler:nil];

		[alertController addAction:confirmAction];
		[self presentViewController:alertController animated:YES completion:nil];

		return;
	}

	CFArrayRef storedResolutions;
	if ((storedResolutions = (CFArrayRef)CFPreferencesCopyAppValue(CFSTR("customResolutions"), CFSTR("tf.festival.rescale")))) {
		NSMutableArray* customResolutions = [(__bridge NSArray*)storedResolutions mutableCopy];

		[customResolutions addObject:@{
			@"canvas_width": @(_customCanvasWidth),
			@"canvas_height": @(_customCanvasHeight)
		}];

		CFPreferencesSetAppValue(CFSTR("customResolutions"), (CFPropertyListRef)customResolutions, CFSTR("tf.festival.rescale"));
	} else {
		NSArray* customResolutions = @[
			@{
				@"canvas_width": @(_customCanvasWidth),
				@"canvas_height": @(_customCanvasHeight)
			}
		];

		CFPreferencesSetAppValue(CFSTR("customResolutions"), (CFPropertyListRef)customResolutions, CFSTR("tf.festival.rescale"));
	}

	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[self.class localizedStringForKey:@"CUSTOM_RESOLUTION_SAVED_TITLE" value:nil table:@"Root"]
																			 message:[NSString stringWithFormat:[self.class localizedStringForKey:@"CUSTOM_RESOLUTION_SAVED_DESCRIPTION" value:nil table:@"Root"], _customCanvasWidth, _customCanvasHeight]
																	  preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleDefault handler:nil];

	[alertController addAction:confirmAction];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)setCustomCanvasHeight:(id)value {
    _customCanvasHeight = [value integerValue];
}

- (void)setCustomCanvasWidth:(id)value {
    _customCanvasWidth = [value integerValue];
}

@end
