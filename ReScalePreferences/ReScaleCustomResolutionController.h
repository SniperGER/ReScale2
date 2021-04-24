#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface PSEditableListController : PSListController
- (void)setEditButtonEnabled:(BOOL)arg1;
- (void)editDoneTapped;
@end

@interface ReScaleCustomResolutionController : PSEditableListController {
	NSMutableArray* _resolutions;
}

@end
