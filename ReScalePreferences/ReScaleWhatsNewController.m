#import "ReScaleWhatsNewController.h"

@implementation ReScaleWhatsNewController

+ (NSString*)localizedStringForKey:(NSString*)key value:(NSString*)value table:(NSString*)table {
	static NSBundle* bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundle = [NSBundle bundleForClass:self];
    });

	return [bundle localizedStringForKey:key value:value table:table];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[self setTitle:[self.class localizedStringForKey:@"WHATS_NEW_TITLE" value:nil table:@"Root"]];

	UIBarButtonItem* rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
	self.navigationItem.rightBarButtonItem = rightButton;

	webView = [[WKWebView alloc] initWithFrame:CGRectZero];
	[webView setNavigationDelegate:self];
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"index" ofType:@"html"]]]];

	[self.view addSubview:webView];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[webView setFrame:self.view.bounds];
}

- (void)dismiss {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
	[coordinator animateAlongsideTransition:^(id  _Nonnull context) {
        [webView setFrame:self.view.bounds];
    } completion:nil];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
		if (navigationAction.request.URL) {
			[[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:nil];
			decisionHandler(WKNavigationActionPolicyCancel);
		} else {
			decisionHandler(WKNavigationActionPolicyAllow);
		}
	} else {
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

@end