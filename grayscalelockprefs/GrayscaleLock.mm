#import <Preferences/Preferences.h>

@interface GrayscaleLockListController : PSListController <UIAlertViewDelegate> {}
@end

#define kPlistPath @"/var/mobile/Library/Preferences/com.hackingdartmouth.grayscalelock.plist"

static NSMutableDictionary *getDefaults() {
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  [defaults setObject:@NO forKey:@"enabled"];
  [defaults setObject:@NO forKey:@"springboardGray"];
  [defaults setObject:@NO forKey:@"grayscaleDefault"];

  return defaults;
}

@implementation GrayscaleLockListController
-(id)specifiers {
	if (_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"GrayscaleLock" target:self] retain];
	}

	return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kPlistPath];
	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:kPlistPath];
	if (settings == nil) {
		settings = getDefaults();
	}
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:kPlistPath atomically:YES];
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
