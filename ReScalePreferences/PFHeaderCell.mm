#import "PFHeaderCell.h"
//PFHeaderCell.mm by Pixel Fire http://pixelfire.baileyseymour.com

@interface PFHeaderCell()


@end

@implementation PFHeaderCell

+ (UIColor*)colorFromHex:(NSString*)hexString {
    unsigned rgbValue = 0;

    if ([hexString hasPrefix:@"#"]) hexString = [hexString substringFromIndex:1];
    if (hexString) {
		NSScanner* scanner = [NSScanner scannerWithString:hexString];
		[scanner setScanLocation:0];
		[scanner scanHexInt:&rgbValue];

		if (@available(iOS 10.0, *)) {
			return [UIColor colorWithDisplayP3Red:((rgbValue & 0xFF0000) >> 16) / 255.0 green:((rgbValue & 0xFF00) >> 8) / 255.0 blue:(rgbValue & 0xFF) / 255.0 alpha:1.0];
		}

		return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0 green:((rgbValue & 0xFF00) >> 8) / 255.0 blue:(rgbValue & 0xFF) / 255.0 alpha:1.0];
    }

	return [UIColor grayColor];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier*)specifier {
	if (self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier]) {
		[self prepareHeaderImage:specifier];
		[self applyHeaderImage];
	}

	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	[self setBackgroundColor:[UIColor clearColor]];
	[headerImageViewContainer setFrame:self.bounds];
	[headerImageView setCenter:(CGPoint){ CGRectGetMidX(headerImageViewContainer.bounds), CGRectGetMidY(headerImageViewContainer.bounds) }];
}

- (void)prepareHeaderImage:(PSSpecifier*)specifier {
	headerImageViewContainer = [[UIView alloc] initWithFrame:self.bounds];
	[headerImageViewContainer setTranslatesAutoresizingMaskIntoConstraints:NO];

 	if (specifier.properties[@"image"]) {
		headerImageView = [[UIImageView alloc] initWithImage:[[UIImage alloc] initWithContentsOfFile:specifier.properties[@"image"]]];
		[headerImageView setContentMode:UIViewContentModeCenter];

		[headerImageViewContainer addSubview:headerImageView];
	}

	self.backgroundColor = nil;
	if (specifier.properties[@"background"]) {
		headerImageViewContainer.backgroundColor = [PFHeaderCell colorFromHex:specifier.properties[@"background"]];
	}
}

- (void)applyHeaderImage {
	[self addSubview:headerImageViewContainer];
}

@end