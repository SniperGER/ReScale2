#include <dlfcn.h>
#include <spawn.h>
#include <substrate.h>

#import <UIKit/UIKit.h>

@class SBDashBoardIdleTimerController;

@interface SBIdleTimerDefaults
- (void)setDisableAutoDim:(BOOL)arg1;
@end

@interface SpringBoard : UIApplication
@end

@interface UIAlertController (Private)
- (void)dismissAnimated:(BOOL)arg1;
- (void)_dismissAnimated:(BOOL)arg1 triggeringAction:(id)arg2;
@end



static SBIdleTimerDefaults* idleTimerDefaults;