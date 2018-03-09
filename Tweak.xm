#include <UIKit/UIKit.h>

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

static void loadPreferences() {
	NSString* plist = @"/var/mobile/Library/Preferences/com.hackingdartmouth.grayscalelock.plist";
	NSDictionary* settings = [NSDictionary dictionaryWithContentsOfFile:plist];

	if ([appsToInvert count]) {
	  [appsToInvert removeAllObjects];
	}

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

static void receivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSString* notificationName = (NSString*)name;

	if ([notificationName isEqualToString:@"com.hackingdartmouth.grayscalelock/settingschanged"]) {
		loadPreferences();
		// Handle it currently
		if (!enabled) {
			_AXSGrayscaleSetEnabled(false);
		} else {
			NSString *identifier = @"com.apple.Preferences";
			if (
				(grayscaleDefault && ![appsToInvert containsObject:identifier]) ||
				(!grayscaleDefault && [appsToInvert containsObject:identifier])
			) {
				_AXSGrayscaleSetEnabled(true);
			} else {
				_AXSGrayscaleSetEnabled(false);
			}
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
			_AXSGrayscaleSetEnabled(true);
		} else {
			_AXSGrayscaleSetEnabled(false);
		}

		lockIdentifier = identifier;
	}
	return %orig;
}

-(void)didDeactivateForEventsOnly:(bool)arg1 {
	// Going to springboard
	if ([lockIdentifier isEqualToString:[self bundleIdentifier]]) {
		lockIdentifier = @"";
		_AXSGrayscaleSetEnabled(springboardGray);
	}
	%orig;
}
%end

%ctor {
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		receivedNotification,
		CFSTR("com.hackingdartmouth.grayscalelock/settingschanged"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);

	appsToInvert = [NSMutableArray array];

	loadPreferences();

	%init;
}