#include <spawn.h>

#include "ReScaleCustomResolutionController.h"

@implementation ReScaleCustomResolutionController

+ (NSString*)localizedStringForKey:(NSString*)key value:(NSString*)value table:(NSString*)table {
	static NSBundle* bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundle = [NSBundle bundleForClass:self];
    });

	return [bundle localizedStringForKey:key value:value table:table];
}

- (BOOL)editable {
	return _resolutions && _resolutions.count;
}

- (void)reloadSpecifiers {
	[super reloadSpecifiers];

	_resolutions = [(__bridge NSArray*)CFPreferencesCopyAppValue(CFSTR("customResolutions"), CFSTR("tf.festival.rescale")) mutableCopy];

	if (_resolutions && _resolutions.count) {
		// [self setEditButtonEnabled:YES];
		PSSpecifier* resolutionGroupSpecifier = [self specifierAtIndex:0];

		[[[_resolutions reverseObjectEnumerator] allObjects] enumerateObjectsUsingBlock:^(NSDictionary* resolution, NSUInteger index, BOOL* stop) {
			PSSpecifier* resolutionSpecifier = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"%@x%@", resolution[@"canvas_width"], resolution[@"canvas_height"]]
																			target:self
																				set:nil
																				get:nil
																			detail:nil
																				cell:PSListItemCell
																				edit:nil];
			[resolutionSpecifier setButtonAction:@selector(applyResolutionFromSpecifier:)];
			[resolutionSpecifier setProperty:NSStringFromSelector(@selector(removedResolution:)) forKey:PSDeletionActionKey];

			[self insertSpecifier:resolutionSpecifier afterSpecifier:resolutionGroupSpecifier];
		}];
	} else {
		PSSpecifier* noEntrySpecifier = [PSSpecifier preferenceSpecifierNamed:[self.class localizedStringForKey:@"CUSTOM_RESOLUTION_LIST_NO_ENTRIES" value:nil table:@"Root"]
                                                                	   target:self
																		  set:nil
																		  get:nil
                                                                	   detail:nil
																		 cell:PSStaticTextCell
																		 edit:nil];

		[self insertSpecifier:noEntrySpecifier afterSpecifier:[self specifierAtIndex:0]];
	}
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"CustomResolutions" target:self];
	}

	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[self.navigationItem setTitle:[self.class localizedStringForKey:@"CUSTOM_RESOLUTION_LIST_TITLE" value:nil table:@"Root"]];
	[self reloadSpecifiers];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self setEditButtonEnabled:self.editable];
}

#pragma mark - Instance Methods

- (void)applyCanvasWidth:(NSUInteger)canvasWidth canvasHeight:(NSUInteger)canvasHeight {
	CFPreferencesSetAppValue(CFSTR("canvas_width"), (CFTypeRef)[NSNumber numberWithInteger:canvasWidth], CFSTR("tf.festival.rescale"));
	CFPreferencesSetAppValue(CFSTR("canvas_height"), (CFTypeRef)[NSNumber numberWithInteger:canvasHeight], CFSTR("tf.festival.rescale"));

	CFPreferencesAppSynchronize(CFSTR("tf.festival.rescale"));
}

- (void)applyResolutionFromSpecifier:(PSSpecifier*)specifier {
	NSInteger specifierIndex = [self indexOfSpecifier:specifier];

	[self confirmResolution:[_resolutions objectAtIndex:specifierIndex - 1] forInterfaceIdiom:UIUserInterfaceIdiomPhone];
}

- (void)confirmResolution:(NSDictionary*)resolution forInterfaceIdiom:(UIUserInterfaceIdiom)interfaceIdiom {
	NSUInteger canvasWidth = [resolution[@"canvas_width"] integerValue],
			   canvasHeight = [resolution[@"canvas_height"] integerValue];

	BOOL isiPad = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;

	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[self.class localizedStringForKey:@"CUSTOM_RESOLUTION_TITLE" value:nil table:@"Root"]
																			 message:[NSString stringWithFormat:[self.class localizedStringForKey:@"APPLY_RESOLUTION_PROMPT" value:nil table:@"Root"], canvasWidth, canvasHeight]
																	  preferredStyle:(isiPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet)];

	UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"APPLY_RESOLUTION_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
		[self applyCanvasWidth:canvasWidth canvasHeight:canvasHeight];

		[self respring];
	}];
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CANCEL" value:nil table:@"Root"] style:UIAlertActionStyleCancel handler:nil];

	[alertController addAction:confirmAction];
	[alertController addAction:cancelAction];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)removedResolution:(PSSpecifier*)specifier {
	NSInteger specifierIndex = [self indexOfSpecifier:specifier];

	[_resolutions removeObjectAtIndex:specifierIndex - 1];
	CFPreferencesSetAppValue(CFSTR("customResolutions"), (CFPropertyListRef)_resolutions, CFSTR("tf.festival.rescale"));

	if (!_resolutions.count) {
		[self editDoneTapped];
		[self setEditButtonEnabled:NO];

		[self reloadSpecifiers];
	}
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
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[self.class localizedStringForKey:@"GENERIC_CONFIRM" value:nil table:@"Root"] style:UIAlertActionStyleCancel handler:nil];

	[alertController addAction:confirmAction];
	[alertController addAction:cancelAction];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (UITableViewCellEditingStyle)tableView:(id)arg1 editingStyleForRowAtIndexPath:(id)arg2 {
	if (!self.editable) return UITableViewCellEditingStyleNone;

	return UITableViewCellEditingStyleDelete;
}

@end
