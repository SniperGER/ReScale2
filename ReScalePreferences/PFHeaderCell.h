#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>

@interface PFHeaderCell : PSTableCell {
	UIView* headerImageViewContainer;
	UIImageView* headerImageView;
}

+ (UIColor*)colorFromHex:(NSString*)hexString;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier*)specifier;
- (void)prepareHeaderImage:(PSSpecifier*)specifier;
- (void)applyHeaderImage;

@end