#include <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFNotificationCenter.h>
extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter();
#include "GrayscaleLock.h"

extern "C" BOOL _AXSGrayscaleEnabled();
extern "C" void _AXSGrayscaleSetEnabled(BOOL);

@interface SBApplication
-(id)bundleIdentifier;
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

// static void log(NSString *toLog) {
// 	NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/var/mobile/log.txt"];
// 	[fileHandle seekToEndOfFile];
// 	[fileHandle writeData:[[NSString stringWithFormat:@"%@\n", toLog] dataUsingEncoding:NSUTF8StringEncoding]];
// 	[fileHandle closeFile];
// }

static void setGrayscale(BOOL status) {
	if (kCFCoreFoundationVersionNumber > 1400) {
		// iOS 11
		_AXSGrayscaleSetEnabled(false); // this works, but with true it doesn't

		// If setting grayscale, set the assistive touch option, and then trigger it
		if (status) {
			// Save the current assistive touch option
			NSArray *oldOptions = [[%c(AXSettings) sharedInstance] tripleClickOptions];
			// Set it to grayscale
			[[%c(AXSettings) sharedInstance] setTripleClickOptions:@[@10]]; // 10 = color filters
			// Trigger the triple click
			SBClickGestureRecognizer* tripleClick = [[(SpringBoard *)[%c(SpringBoard) sharedApplication] lockHardwareButton] triplePressGestureRecognizer];

			// Succeed base
			MSHookIvar<long long>(tripleClick, "_state") = UIGestureRecognizerStateEnded;
			// Fail all dependents
			// NSMutableSet *failureDependents = MSHookIvar<NSMutableSet *>(tripleClick, "_failureDependents");
			// for (UIGestureRecognizer* failureDependent in failureDependents) {
			// 	MSHookIvar<long long>(failureDependent, "_state") = UIGestureRecognizerStateFailed;
			// }

			// Invoke triple press (to toggle colorFilter)
			[[(SpringBoard *)[%c(SpringBoard) sharedApplication] lockHardwareButton] triplePress:tripleClick];

			// Reset the base
			MSHookIvar<long long>(tripleClick, "_state") = UIGestureRecognizerStatePossible;

			// Reset the assistive touch options
			[[%c(AXSettings) sharedInstance] setTripleClickOptions:oldOptions];
		}
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
%group ios10
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

%group ios11
-(void)_updateProcess:(id)arg1 withState:(FBProcessState *)state {
	// App is launching
	if ([state visibility] == kForeground && ![[self bundleIdentifier] isEqualToString:lockIdentifier]) {
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

-(void)saveSnapshotForSceneHandle:(id)arg1 context:(id)arg2 completion:(/*^block*/id)arg3 {
	if ([lockIdentifier isEqualToString:[self bundleIdentifier]]) {
		lockIdentifier = @"";
		setGrayscale(springboardGray);
	}
	%orig;
}
%end
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

	if (kCFCoreFoundationVersionNumber > 1400) {
		%init(ios11);
	} else {
		%init(ios10);
	}

	%init;
}