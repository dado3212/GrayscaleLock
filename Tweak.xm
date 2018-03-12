#include <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFNotificationCenter.h>
extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter();

extern "C" BOOL _AXSGrayscaleEnabled();
extern "C" void _AXSGrayscaleSetEnabled(BOOL);

@interface SpringBoard
-(void)_relaunchSpringBoardNow;
@end

@interface SBApplication
-(id)bundleIdentifier;
@end

@interface BKSApplicationLaunchSettings
@property(nonatomic) int interfaceOrientation;
@end

static bool enabled = NO;
static bool grayscaleDefault = NO;
static bool springboardGray = NO;
static NSMutableArray* appsToInvert = nil;
static NSString* lockIdentifier = @"";

static NSMutableDictionary *getDefaults() {
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  [defaults setObject:@NO forKey:@"enabled"];
  [defaults setObject:@NO forKey:@"springboardGray"];
  [defaults setObject:@NO forKey:@"grayscaleDefault"];

  return defaults;
}

static void setGrayscale(BOOL status) {
	if (kCFCoreFoundationVersionNumber > 1400) {
		// iOS 11
	} else {
		_AXSGrayscaleSetEnabled(status);
	}
}

static void loadPreferences() {
	NSString* plist = @"/var/mobile/Library/Preferences/com.hackingdartmouth.grayscalelock.plist";
	NSMutableDictionary* settings = [[NSMutableDictionary alloc] initWithContentsOfFile:plist];
	if (settings == nil) {
		settings = getDefaults();
	}

	if ([appsToInvert count]) {
	  [appsToInvert removeAllObjects];
	}

	return;

	NSNumber* value = [settings valueForKey:@"enabled"];
	if (value != nil) {
		enabled = [value boolValue];
	}
	NSNumber* grayscale = [settings valueForKey:@"grayscaleDefault"];
	if (grayscale != nil) {
		grayscaleDefault = [grayscale boolValue];
	}
	NSNumber* springboard = [settings valueForKey:@"springboardGray"];
	if (springboard != nil) {
		springboardGray = [springboard boolValue];
	}

	if (!enabled) {
		return;
	}

	NSString* identifier;
	for (NSString* key in [settings allKeys]) {
		if ([[settings valueForKey:key] boolValue]) {
			if ([key hasPrefix:@"invert-"]) {
				identifier = [key substringFromIndex:7];
				
				[appsToInvert addObject:identifier];
			}
		}
	}
}

static void updateSettings(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  loadPreferences();

	// Handle it currently
	if (!enabled) {
		setGrayscale(false);
	} else {
		NSString *identifier = @"com.apple.Preferences";
		if (
			(grayscaleDefault && ![appsToInvert containsObject:identifier]) ||
			(!grayscaleDefault && [appsToInvert containsObject:identifier])
		) {
			setGrayscale(true);
		} else {
			setGrayscale(false);
		}
	}
}

%hook SBApplication
-(void)willActivate {
	if (enabled) {
		NSString* identifier = [self bundleIdentifier];

		// If grayscaleDefault and no app, then set it to grayscale
		// If grayscaleDefault and yes app, then set it to normal
		// If NOT grayscaleDefault and no app, then set it to normal
		// If NOT grayscaleDefault and yes app, then set it to grayscale
		if (
			(grayscaleDefault && ![appsToInvert containsObject:identifier]) ||
			(!grayscaleDefault && [appsToInvert containsObject:identifier])
		) {
			setGrayscale(true);
		} else {
			setGrayscale(false);
		}

		lockIdentifier = identifier;
	}
	return %orig;
}

-(void)didDeactivateForEventsOnly:(bool)arg1 {
	// Going to springboard
	if ([lockIdentifier isEqualToString:[self bundleIdentifier]]) {
		lockIdentifier = @"";
		setGrayscale(springboardGray);
	}
	%orig;
}
%end

%ctor {
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDistributedCenter(),
		NULL,
		&updateSettings,
		CFSTR("com.hackingdartmouth.grayscalelock/settingschanged"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);

	appsToInvert = [[NSMutableArray alloc] init];

	loadPreferences();

	%init;
}