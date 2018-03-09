#import <Preferences/Preferences.h>

@interface GrayscaleLockListController : PSListController <UIAlertViewDelegate> {}
@end

#define kPlistPath @"/var/mobile/Library/Preferences/com.hackingdartmouth.grayscalelock.plist"

@implementation GrayscaleLockListController
-(id)specifiers {
	if (_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"GrayscaleLock" target:self] retain];
	}

	return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:path atomically:YES];
	CFStringRef notificationName = (CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}
}

-(void)donate {
	NSURL* url = [[NSURL alloc] initWithString:@"https://paypal.me/AlexBeals/5"];
	[[UIApplication sharedApplication] openURL:url];
}

-(void)resetSettings {
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Reset settings"
		message:@"All selections will be lost. Are you sure?"
		delegate:self
		cancelButtonTitle:@"No"
		otherButtonTitles:@"Yes", nil];
	[alert show];
	[alert release];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [alertView cancelButtonIndex]) {
		// Do nothing
	} else {
		NSDictionary* settings = [NSDictionary dictionaryWithContentsOfFile:kPlistPath];

		NSNumber* enabled = [settings valueForKey:@"enabled"];
		NSNumber* grayscaleDefault = [settings valueForKey:@"grayscaleDefault"];
		NSNumber* springboardGray = [settings valueForKey:@"springboardGray"];

		NSMutableDictionary* settingsToSave = [NSMutableDictionary dictionaryWithCapacity:3];
		if (enabled != nil) {
			[settingsToSave setValue:enabled forKey:@"enabled"];
		}
		if (grayscaleDefault != nil) {
			[settingsToSave setValue:grayscaleDefault forKey:@"grayscaleDefault"];
		}
		if (springboardGray != nil) {
			[settingsToSave setValue:springboardGray forKey:@"springboardGray"];
		}

		[settingsToSave writeToFile:kPlistPath atomically:YES];
	}
}
@end
