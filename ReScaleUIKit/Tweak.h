#include <dlfcn.h>
#include <spawn.h>
#include <substrate.h>

#import <UIKit/UIKit.h>

@class SBDashBoardIdleTimerController;

@interface CSCoverSheetViewController : UIViewController
- (SBDashBoardIdleTimerController*)idleTimerController;
@end

@interface SBDashBoardIdleTimerController : NSObject // ios 13 and up
- (void)addIdleTimerDisabledAssertionReason:(id)arg1;
- (void)removeIdleTimerDisabledAssertionReason:(id)arg1;
@end

@interface SBDashBoardViewController : NSObject // ios 12
- (void)addIdleTimerDisabledAssertionReason:(id)arg1;
- (void)removeIdleTimerDisabledAssertionReason:(id)arg1;
@end

@interface SBLockScreenManager
@property(readonly, nonatomic) SBDashBoardViewController *dashBoardViewController; // ios 12
+ (id)sharedInstance;
- (CSCoverSheetViewController*)coverSheetViewController;
@end

@interface SpringBoard : UIApplication
@end

@interface UIAlertController (Private)
- (void)dismissAnimated:(BOOL)arg1;
- (void)_dismissAnimated:(BOOL)arg1 triggeringAction:(id)arg2;
@end