@interface SBClickGestureRecognizer: UIGestureRecognizer
@end

@interface SBLockHardwareButton : NSObject
@property(retain, nonatomic) SBClickGestureRecognizer *triplePressGestureRecognizer;
- (void)triplePress:(id)arg1;
@end

@interface UIHBClickGestureRecognizer: UIGestureRecognizer
@end

@interface SBHomeHardwareButtonGestureRecognizerConfiguration: NSObject
@property(retain, nonatomic) UIHBClickGestureRecognizer *triplePressUpGestureRecognizer; // @synthesize triplePressUpGestureRecognizer=_triplePressUpGestureRecognizer;
@end

@interface SBHomeHardwareButton : NSObject
- (void)triplePressUp:(id)arg1;
@property(retain, nonatomic) SBHomeHardwareButtonGestureRecognizerConfiguration *gestureRecognizerConfiguration; // @synthesize gestureRecognizerConfiguration=_gestureRecognizerConfiguration;
@end

@interface SpringBoard: UIApplication
@property(readonly, nonatomic) SBLockHardwareButton *lockHardwareButton;
@property(readonly, nonatomic) SBHomeHardwareButton *homeHardwareButton;
@end

// For figuring out which app has launched
@interface FBProcessState: NSObject
@property (assign,nonatomic) int visibility;
@end

#define kForeground 2
#define kBackground 1

// For changing assistive touch settings
@interface AXSettings: NSObject
+(id)sharedInstance;
-(NSArray *)tripleClickOptions;
-(void)setTripleClickOptions:(NSArray *)arg1 ;
@end