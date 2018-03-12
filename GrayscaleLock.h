@interface SBClickGestureRecognizer: UIGestureRecognizer
@end

@interface SBLockHardwareButton : NSObject
@property(retain, nonatomic) SBClickGestureRecognizer *triplePressGestureRecognizer; // @synthesize triplePressGestureRecognizer=_triplePressGestureRecognizer;
- (void)triplePress:(id)arg1;
@end

@interface SpringBoard: UIApplication
@property(readonly, nonatomic) SBLockHardwareButton *lockHardwareButton; // @synthesize lockHardwareButton=_lockHardwareButton;
@end

// For figuring out which app has launched
@interface FBProcessState: NSObject
@property (assign,nonatomic) int visibility;                                   //@synthesize visibility=_visibility - In the implementation block
@end

#define kForeground 2
#define kBackground 1

// For changing assistive touch settings
@interface AXSettings: NSObject
+(id)sharedInstance;
-(NSArray *)tripleClickOptions;
-(void)setTripleClickOptions:(NSArray *)arg1 ;
@end