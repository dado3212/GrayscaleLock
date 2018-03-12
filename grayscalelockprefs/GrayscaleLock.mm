#import <Preferences/Preferences.h>
#include <CoreFoundation/CoreFoundation.h>

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

@interface GrayscaleLockListController : PSListController <UIAlertViewDelegate> {
	NSMutableDictionary *prefs;
}
@end

#define kPrefPath @"/var/mobile/Library/Preferences/com.hackingdartmouth.grayscalelock.plist"

static NSMutableDictionary *getDefaults() {
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  [defaults setObject:@NO forKey:@"enabled"];
  [defaults setObject:@NO forKey:@"springboardGray"];
  [defaults setObject:@NO forKey:@"grayscaleDefault"];

  return defaults;
}

@implementation GrayscaleLockListController
- (void)viewDidLoad {
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
  if (prefs == nil) {
    prefs = getDefaults();
  }

  [prefs writeToFile:kPrefPath atomically:YES];
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath]; // prevents weird crash on saving for the first time

  [super viewDidLoad];
}

- (id)specifiers {
	if (_specifiers == nil) {
    NSMutableArray *specs = [NSMutableArray array];
    prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];

    // Enable for groups
    PSSpecifier *toggle = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                           target:self
                              set:@selector(setPreferenceValue:specifier:)
                              get:@selector(readPreferenceValue:)
                           detail:Nil
                             cell:PSSwitchCell
                             edit:Nil];
    [specs addObject:toggle];

    PSSpecifier* group = [PSSpecifier preferenceSpecifierNamed:@"Springboard"
                          target:self
                             set:NULL
                             get:NULL
                          detail:Nil
                            cell:PSGroupCell
                            edit:Nil];
    [group setProperty:@"Enable if the default springboard should be grayscale" forKey:@"footerText"];
    [specs addObject:group];

    toggle = [PSSpecifier preferenceSpecifierNamed:@"Grayscale"
                           target:self
                              set:@selector(setPreferenceValue:specifier:)
                              get:@selector(readPreferenceValue:)
                           detail:Nil
                             cell:PSSwitchCell
                             edit:Nil];
    [specs addObject:toggle];

    group = [PSSpecifier preferenceSpecifierNamed:@"Grayscale Default"
                          target:self
                             set:NULL
                             get:NULL
                          detail:Nil
                            cell:PSGroupCell
                            edit:Nil];
    [group setProperty:@"If it's grayscale by default, then the app-specific toggle will make it normal.  Otherwise, the app-specific toggle will make the app in question grayscale." forKey:@"footerText"];
    [specs addObject:group];

    toggle = [PSSpecifier preferenceSpecifierNamed:@"Grayscale By Default"
                           target:self
                              set:@selector(setPreferenceValue:specifier:)
                              get:@selector(readPreferenceValue:)
                           detail:Nil
                             cell:PSSwitchCell
                             edit:Nil];
    [specs addObject:toggle];
    
    // Reset
    group = [PSSpecifier preferenceSpecifierNamed:@""
             target:self
                set:NULL
                get:NULL
             detail:Nil
               cell:PSGroupCell
               edit:Nil];
    [group setProperty:@"Clear all selected apps" forKey:@"footerText"];
    [specs addObject:group];

    PSSpecifier *button = [PSSpecifier preferenceSpecifierNamed:@"Reset Settings"
              target:self
                 set:NULL
                 get:NULL
              detail:Nil
                cell:PSButtonCell
                edit:Nil];
    [button setButtonAction:@selector(resetSettings)];
    [specs addObject:button];

    // About section
    group = [PSSpecifier preferenceSpecifierNamed:@"About"
             target:self
                set:NULL
                get:NULL
             detail:Nil
               cell:PSGroupCell
               edit:Nil];
    [specs addObject:group];

    button = [PSSpecifier preferenceSpecifierNamed:@"Donate to Developer"
              target:self
                 set:NULL
                 get:NULL
              detail:Nil
                cell:PSButtonCell
                edit:Nil];
    [button setButtonAction:@selector(donate)];
    [button setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MercuryPrefs.bundle/paypal.png"] forKey:@"iconImage"];
    [specs addObject:button];

    button = [PSSpecifier preferenceSpecifierNamed:@"Source Code on Github"
      target:self
      set:NULL
      get:NULL
      detail:Nil
      cell:PSButtonCell
      edit:Nil];
    [button setButtonAction:@selector(source)];
    [button setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MercuryPrefs.bundle/github.png"] forKey:@"iconImage"];
    [specs addObject:button];

    button = [PSSpecifier preferenceSpecifierNamed:@"Email Developer"
      target:self
      set:NULL
      get:NULL
      detail:Nil
      cell:PSButtonCell
      edit:Nil];
    [button setButtonAction:@selector(email)];
    [button setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/MercuryPrefs.bundle/mail.png"] forKey:@"iconImage"];
    [specs addObject:button];

    // Year footer
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    NSString *yearString = [formatter stringFromDate:[NSDate date]];

    group = [PSSpecifier emptyGroupSpecifier];
    if ([yearString isEqualToString:@"2018"]) {
      [group setProperty:@"© 2018 Alex Beals" forKey:@"footerText"];
    } else {
      [group setProperty:[NSString stringWithFormat: @"© 2018-%@ Alex Beals", yearString] forKey:@"footerText"];
    }
    [group setProperty:@(1) forKey:@"footerAlignment"];
    [specs addObject:group];

    _specifiers = [[NSArray arrayWithArray:specs] retain];
	}
	return _specifiers;
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
  if ([[specifier name] isEqualToString:@"Enabled"]) {
    return prefs[@"enabled"];
  } else if ([[specifier name] isEqualToString:@"Grayscale"]) {
    return prefs[@"springboardGray"];
  } else if ([[specifier name] isEqualToString:@"Grayscale By Default"]) {
    return prefs[@"grayscaleDefault"];
  }
  // } else if ([[specifier name] isEqualToString:@"Enabled for Group Conversations"]) {
  //   return [prefs[kTypeKey] intValue] != 3 ? prefs[kGroupsKey] : @NO;
  // } else if ([[specifier name] isEqualToString:@"Radius"]) {
  //   return prefs[kRadiusKey];
  // }
  return nil;
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
  prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPrefPath];
  if ([[specifier name] isEqualToString:@"Enabled"]) {
    [prefs setValue:value forKey:@"enabled"];
  } else if ([[specifier name] isEqualToString:@"Grayscale"]) {
    [prefs setValue:value forKey:@"springboardGray"];
  } else if ([[specifier name] isEqualToString:@"Grayscale By Default"]) {
    [prefs setValue:value forKey:@"grayscaleDefault"];
  }
  // } else if ([[specifier name] isEqualToString:@"Enabled for Group Conversations"]) {
  //   [prefs setValue:value forKey:kGroupsKey];
  // } else if ([[specifier name] isEqualToString:@"Radius"]) {
  //   [prefs setValue:value forKey:kRadiusKey];
  // }
  [prefs writeToFile:kPrefPath atomically:YES];
  [self reloadSpecifiers];

  CFNotificationCenterPostNotification(
  	CFNotificationCenterGetDistributedCenter(),
		CFSTR("com.hackingdartmouth.grayscalelock/settingschanged"),
		NULL,
		NULL,
		kCFNotificationDeliverImmediately
	);
}

- (void)source {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/dado3212/GrayscaleLock"]];
}

- (void)donate {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/AlexBeals/5"]];
}

- (void)email {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:Alex.Beals.18@dartmouth.edu?subject=Cydia%3A%20GrayscaleLock"]];
}

- (void)resetSettings {
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
		NSDictionary* settings = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];

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

		[settingsToSave writeToFile:kPrefPath atomically:YES];
		[self reloadSpecifiers];
	}
}
@end
