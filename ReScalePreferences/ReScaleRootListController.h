#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface ReScaleRootListController : PSListController {
	NSInteger _customCanvasHeight;
	NSInteger _customCanvasWidth;
	NSDictionary* _resolutions;
}

@end
