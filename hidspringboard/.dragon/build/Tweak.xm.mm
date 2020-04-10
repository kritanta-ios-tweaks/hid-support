#line 1 "Tweak.xm"









  
#include <dlfcn.h>
#include <objc/runtime.h>
#include <mach/mach_port.h>
#include <mach/mach_init.h>
#include <sys/sysctl.h>

#include <mach/mach_time.h>
#include <UIKit/UIKit.h>

#include <IOKit/hid/IOHIDEvent.h>
#include <IOKit/hid/IOHIDEventSystemClient.h>
#include "rocketbootstrap.h"


#import <GraphicsServices/GSEvent.h>

#include "../hid-support-internal.h"

UIWindow *cursorWindow;
UIImageView *cursor;

template <typename Type_>
static inline void MyMSHookSymbol(Type_ *&value, const char *name, void *handle = RTLD_DEFAULT) {
    value = reinterpret_cast<Type_ *>(dlsym(handle, name));
}





@interface CAWindowServer : NSObject
+ (CAWindowServer *)serverIfRunning;
- (NSArray *)displays;
@end
@interface CAWindowServerDisplay : NSObject
- (unsigned int)clientPortAtPosition:(struct CGPoint)position;
- (int) contextIdAtPosition:(CGPoint)position;
- (mach_port_t) taskPortOfContextId:(int)context;
@end

@interface BKHIDClientConnectionManager : NSObject
- (IOHIDEventSystemConnectionRef) clientForTaskPort:(mach_port_t)port;
@end

@interface BKAccessibility : NSObject
+ (BKHIDClientConnectionManager *) _eventRoutingClientConnectionManager;
@end

#if !defined(__IPHONE_3_2) || __IPHONE_3_2 > __IPHONE_OS_VERSION_MAX_ALLOWED
typedef enum {
    UIUserInterfaceIdiomPhone,           
    UIUserInterfaceIdiomPad,             
} UIUserInterfaceIdiom;
@interface UIDevice (privateAPI)
- (BOOL) userInterfaceIdiom;
@end
#endif

@interface UIScreen (fourZeroAndLater)
@property(nonatomic,readonly) CGFloat scale;
@end

@interface SpringBoard : NSObject

-(void)resetIdleTimerAndUndim:(BOOL)fp8; 

-(void)resetIdleTimerAndUndim;

-(unsigned)_frontmostApplicationPort;
@end

@interface SBAwayController : NSObject
+ (id)sharedAwayController;
- (BOOL)undimsDisplay;
- (id)awayView;
- (void)lock;
- (void)_unlockWithSound:(BOOL)fp8;
- (void)unlockWithSound:(BOOL)fp8;
- (void)unlockWithSound:(BOOL)fp8 alertDisplay:(id)fp12;
- (void)loadPasscode;
- (id)devicePasscode;
- (BOOL)isPasswordProtected;
- (void)activationChanged:(id)fp8;
- (BOOL)isDeviceLockedOrBlocked;
- (void)setDeviceLocked:(BOOL)fp8;
- (void)applicationRequestedDeviceUnlock;
- (void)cancelApplicationRequestedDeviceLockEntry;
- (BOOL)isBlocked;
- (BOOL)isPermanentlyBlocked:(double *)fp8;
- (BOOL)isLocked;
- (void)attemptUnlock;
- (BOOL)isAttemptingUnlock;
- (BOOL)attemptDeviceUnlockWithPassword:(id)fp8 alertDisplay:(id)fp12;
- (void)cancelDimTimer;
- (void)restartDimTimer:(float)fp8;
- (id)dimTimer;
- (BOOL)isDimmed;
- (void)finishedDimmingScreen;
- (void)dimScreen:(BOOL)fp8;
- (void)undimScreen;
- (void)userEventOccurred;
- (void)activate;
- (void)deactivate;
@end


@interface SBBrightnessController : NSObject
+ (id)sharedBrightnessController;
- (void)adjustBacklightLevel:(BOOL)fp8;
@end


@interface SBLockScreenManager
+(id)sharedInstance;
-(void)unlockUIFromSource:(int)source withOptions:(id)options;
@property(readonly, assign) BOOL isUILocked;
@end

@interface SBMediaController : NSObject 
+(SBMediaController*) sharedInstance;
-(void)togglePlayPause;
-(BOOL)isPlaying;
-(void)changeTrack:(int)change;
@end


@interface SBUserAgent
+(id)sharedUserAgent;
-(void)undimScreen;
@end

@interface VolumeControl : NSObject 
+ (id)sharedVolumeControl;
- (void)toggleMute;
@end


@interface UIKeyboardImpl : NSObject
+(UIKeyboardImpl*)sharedInstance;
-(void)addInputString:(NSString*)string;
@end


typedef enum __GSHandInfoType2 {
        kGSHandInfoType2TouchDown    = 1,    
        kGSHandInfoType2TouchDragged = 2,    
        kGSHandInfoType2TouchChange  = 5,    
        kGSHandInfoType2TouchFinal   = 6,    
} GSHandInfoType2;

static CFDataRef myCallBack(CFMessagePortRef local, SInt32 msgid, CFDataRef cfData, void *info);




static GSEventRef  (*$GSEventCreateKeyEvent)(int, CGPoint, CFStringRef, CFStringRef, uint32_t, UniChar, short, short);
static GSEventRef  (*$GSCreateSyntheticKeyEvent)(UniChar, BOOL, BOOL);
static void        (*$GSEventSetKeyCode)(GSEventRef event, uint16_t keyCode);
static CGSize      (*$GSMainScreenSize)(void);
static float       (*$GSMainScreenScaleFactor)(void);
static float       (*$GSMainScreenOrientation)(void);
static CFStringRef (*$GSEventCopyCharacters)(GSEventRef event);
static GSEventType (*$GSEventGetType)(GSEventRef event);


static void (*$IOHIDEventSetSenderID)(IOHIDEventRef event, uint64_t senderID) = NULL;


static uint8_t  touchEvent[sizeof(GSEventRecord) + sizeof(GSHandInfo) + sizeof(GSPathInfo)];


static float screen_width = 320;
static float screen_height = 480;
static float retina_factor = 1.0f;
static float screen_orientation = 0.0f;


static float mouse_max_x = 0;
static float mouse_max_y = 0;


static float mouse_x = 0;
static float mouse_y = 0;


static int Level_;  


static BOOL inSpringBoard = NO;
static BOOL inBackboardd  = NO;



static int is_iPad1 = 0;

static enum { PORTRAIT, MODE_A, MODE_B } screen_rotation = PORTRAIT;

static Class $SBAwayController = objc_getClass("SBAwayController");

template <typename Type_>
static void dlset(Type_ &function, const char *name) {
    function = reinterpret_cast<Type_>(dlsym(RTLD_DEFAULT, name));
    
}


void detectOSLevel(){
    if (kCFCoreFoundationVersionNumber > 800) { 
        Level_ = 5;
        return;
    }

    if (dlsym(RTLD_DEFAULT, "GSGetPurpleWorkspacePort")){
        Level_ = 4;
        return;
    }

    if (dlsym(RTLD_DEFAULT, "GSLibraryCopyGenerationInfoValueForKey")){
        Level_ = 3;
        return;
    }
    if (dlsym(RTLD_DEFAULT, "GSKeyboardCreate")) {
        Level_ = 2;
        return;
    }
    if (dlsym(RTLD_DEFAULT, "GSEventGetWindowContextId")) {
        Level_ = 1;
        return;
    }
    Level_ = 0;
}

void FixRecord(GSEventRecord *record) {
    if (Level_ < 1) {
        memmove(&record->windowContextId, &record->windowContextId + 1, sizeof(*record) - (reinterpret_cast<uint8_t *>(&record->windowContextId + 1) - reinterpret_cast<uint8_t *>(record)) + record->infoSize);
    }
}

static float box(float min, float value, float max){
    if (value < min) return min;
    if (value > max) return max;
    return value;
}


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class UIAlertView; @class SBMediaController; @class UIApplication; @class SBBrightnessController; @class SpringBoard; @class VolumeControl; @class UIKeyboardImpl; @class SBLockScreenManager; 
static BOOL (*_logos_orig$_ungrouped$UIApplication$handleEvent$withNewEvent$)(_LOGOS_SELF_TYPE_NORMAL UIApplication* _LOGOS_SELF_CONST, SEL, GSEventRef, id); static BOOL _logos_method$_ungrouped$UIApplication$handleEvent$withNewEvent$(_LOGOS_SELF_TYPE_NORMAL UIApplication* _LOGOS_SELF_CONST, SEL, GSEventRef, id); 
static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$UIKeyboardImpl(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("UIKeyboardImpl"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBLockScreenManager(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBLockScreenManager"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$UIAlertView(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("UIAlertView"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBMediaController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBMediaController"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$UIApplication(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("UIApplication"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$VolumeControl(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("VolumeControl"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SpringBoard(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SpringBoard"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBBrightnessController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBBrightnessController"); } return _klass; }
#line 255 "Tweak.xm"
static bool isSBUserNotificationAlertVisible(void){

    if (!_logos_static_class_lookup$UIApplication()) return NO;
    if (!_logos_static_class_lookup$UIAlertView()) return NO;

    UIView * keyWindow = [[_logos_static_class_lookup$UIApplication() sharedApplication] keyWindow];
    if (!keyWindow) return false;
    if (![keyWindow.subviews count]) return false;
    UIView * firstSubview = [keyWindow.subviews objectAtIndex:0];
    return [firstSubview isKindOfClass:[_logos_static_class_lookup$UIAlertView() class]];
}

static void sendGSEvent(GSEventRecord *eventRecord, CGPoint point){

    mach_port_t port(0);
    CGPoint point2;

    switch (screen_rotation){
        case PORTRAIT:
            
            point2.x = point.x;
            point2.y = point.y;
            break;
        case MODE_A:
            
            point2.x = point.y;
            point2.y = screen_width - 1 - point.x;    
            break;
        case MODE_B:
            
            point2.x = screen_height - 1 - point.y;
            point2.y = point.x;
            break;
    }

    point2.x *= retina_factor;
    point2.y *= retina_factor;

    if (CAWindowServer *server = [CAWindowServer serverIfRunning]) {
        NSArray *displays([server displays]);
        if (displays != nil && [displays count] != 0){
            if (CAWindowServerDisplay *display = [displays objectAtIndex:0]) { 
                port = [display clientPortAtPosition:point2];
                
            }
        }
    }

    
        
    if (port) {
        
        GSSendEvent(eventRecord, port);
    } else {
        GSSendSystemEvent(eventRecord);
    }
}


static GSHandInfoType getHandInfoType(int touch_before, int touch_now){
    if (!touch_before) {
        return (GSHandInfoType) kGSHandInfoType2TouchDown;
    }
    if (touch_before == touch_now){
        return (GSHandInfoType) kGSHandInfoType2TouchDragged;        
    }
    if (touch_now) {
        return (GSHandInfoType) kGSHandInfoType2TouchChange;
    }
    return (GSHandInfoType) kGSHandInfoType2TouchFinal;
}

static void postMouseEventGS(float x, float y, int click){

    static int prev_click = 0;

    if (!click && !prev_click) return;

    CGPoint location = CGPointMake(x, y);

    
    struct GSTouchEvent {
        GSEventRecord record;
        GSHandInfo    handInfo;
    } * event = (struct GSTouchEvent*) &touchEvent;
    bzero(touchEvent, sizeof(touchEvent));
    
    
    event->record.type = kGSEventHand;
    event->record.windowLocation = location;
    event->record.timestamp = GSCurrentEventTimestamp();
    event->record.infoSize = sizeof(GSHandInfo) + sizeof(GSPathInfo);
    event->handInfo.type = getHandInfoType(prev_click, click);
    if (Level_ >= 3){
        
        event->handInfo._0x50 = 1;
    } else {
    	event->handInfo.pathInfosCount = 1;
    }
    bzero(&event->handInfo.pathInfos[0], sizeof(GSPathInfo));
    event->handInfo.pathInfos[0].pathIndex     = 1;
    event->handInfo.pathInfos[0].pathIdentity  = 2;
    event->handInfo.pathInfos[0].pathProximity = click ? 0x03 : 0x00;;
    event->handInfo.pathInfos[0].pathLocation  = location;

    
    sendGSEvent( (GSEventRecord*) event, location);  
    
    prev_click = click;  
}

static void postIOHIDEvent(IOHIDEventRef event){
    static IOHIDEventSystemClientRef ioSystemClient = NULL;
    if (!ioSystemClient){
        ioSystemClient = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
        
    }
    IOHIDEventSystemClientDispatchEvent(ioSystemClient, event);
    CFRelease(event);
}

static void postMouseEventIOHID(float x, float y, int click){

    

    static int prev_click = 0;

    uint32_t parent_flags;
    uint32_t child_flags;
    if (prev_click == 0 && click == 1) {
        parent_flags = kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventIdentity;
        child_flags  = kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch;
    } else if (prev_click == 1 && click == 1) {
        parent_flags = kIOHIDDigitizerEventPosition;
        child_flags  = kIOHIDDigitizerEventPosition;
    } else if (prev_click == 1 && click == 0) {
        parent_flags = kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventIdentity | kIOHIDDigitizerEventPosition;
        child_flags  = kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch;
    } else return;
    

    IOHIDFloat xf = x / screen_width;
    IOHIDFloat yf = y / screen_height;
    IOHIDEventRef parent = IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, mach_absolute_time(), kIOHIDDigitizerTransducerTypeHand, 1<<22, 1, parent_flags, 0, xf, yf, 0, 0, 0, 0, 0, 0);
    IOHIDEventSetIntegerValue(parent, kIOHIDEventFieldIsBuiltIn, true);
    IOHIDEventSetIntegerValue(parent, kIOHIDEventFieldDigitizerIsDisplayIntegrated, true);
    if ($IOHIDEventSetSenderID){
        
        ($IOHIDEventSetSenderID)(parent, 0x8000000817319375);
    } else {
        
    }
    IOHIDEventRef child = IOHIDEventCreateDigitizerFingerEvent(kCFAllocatorDefault, mach_absolute_time(), 3, 2, child_flags, xf, yf, 0, 0, 0, click, click, 0);
    IOHIDEventAppendEvent(parent, child);
    CFRelease(child);
    
    postIOHIDEvent(parent);
   
    prev_click = click;
}


typedef struct mapping {
    int specialFunction;
    int keyCode;
    int charCode;
    int modifier;
} mapping;

static mapping specialMapping[] = {
    { NSUpArrowFunctionKey,     0x52, 0x1e, 0x00 },
    { NSDownArrowFunctionKey,   0x51, 0x1f, 0x00 },
    { NSLeftArrowFunctionKey,   0x50, 0x1c, 0x00 },
    { NSRightArrowFunctionKey,  0x4f, 0x1d, 0x00 },

    { NSHomeFunctionKey,        0x52, 0x1e, CMD },   
    { NSEndFunctionKey,         0x51, 0x1f, CMD },   
    { NSBeginOfLineFunctionKey, 0x50, 0x1c, CMD },   
    { NSEndOfLineFunctionKey,   0x4f, 0x1d, CMD },   
};

static int specialMapppingCount = sizeof(specialMapping) / sizeof(mapping);

static void postKeyEvent(int down, uint16_t modifier, unichar unicode){
    CGPoint location = CGPointMake(100, 100);
    CFStringRef string = NULL;
    GSEventRef  event  = NULL;
    GSEventType type = down ? kGSEventKeyDown : kGSEventKeyUp;

    
    int keycode = 0;
    if (Level_ >= 2 && unicode >= 0xf700){
        for (int i = 0; i < specialMapppingCount ; i ++){
            if (specialMapping[i].specialFunction == unicode){
                NSLog(@"Mapping 0x%04x -> 0x%02x/0x%02x", unicode, specialMapping[i].charCode, specialMapping[i].keyCode);
                unicode   = specialMapping[i].charCode;
                keycode   = specialMapping[i].keyCode;
                modifier |= specialMapping[i].modifier;
                break;
            }
        }
    }

    uint32_t flags = (GSEventFlags) 0;
    if (modifier & CMD){
        flags |= 1 << 16;   
    }
    if (modifier & SHIFT){  
        flags |= kGSEventFlagMaskShift;
    }
    if (modifier & ALT){
        flags |= kGSEventFlagMaskAlternate;
    }
    if (modifier & CTRL){
        flags |= 1 << 20;   
    }
    
    if ($GSEventCreateKeyEvent) {           

        
        string = CFStringCreateWithCharacters(kCFAllocatorDefault, &unicode, 1);
        event = (*$GSEventCreateKeyEvent)(type, location, string, string, (GSEventFlags) flags, 0, 0, 1);
        if ($GSEventSetKeyCode) {
            (*$GSEventSetKeyCode)(event, keycode);
        }
    } else if ($GSCreateSyntheticKeyEvent && down) { 
        
        event = (*$GSCreateSyntheticKeyEvent)(unicode, down, YES);
        GSEventRecord *record((GSEventRecord*) _GSEventGetGSEventRecord(event));
        record->type = kGSEventSimulatorKeyDown;
        record->flags = (GSEventFlags) flags;

    } else return;

    
    if (isSBUserNotificationAlertVisible()) {
        GSSendSystemEvent((GSEventRecord*) _GSEventGetGSEventRecord(event));
    } else {
        
        sendGSEvent((GSEventRecord*) _GSEventGetGSEventRecord(event), location);
    }
        
    if (string){
        CFRelease(string);
    }
    CFRelease(event);
}

static void handleMouseEvent(const mouse_event_t *mouse_event){

    

    float new_mouse_x, new_mouse_y;
    switch (mouse_event->type) {
        case REL_MOVE:
            new_mouse_x = mouse_x + mouse_event->x;
            new_mouse_y = mouse_y + mouse_event->y;
            break;
        case ABS_MOVE:
            new_mouse_x = mouse_event->x;
            new_mouse_y = mouse_event->y;
            break;
        default:
            return;
    }
    mouse_x = box(0, new_mouse_x, mouse_max_x);
    mouse_y = box(0, new_mouse_y, mouse_max_y);

    
    

    int buttons = mouse_event->buttons ? 1 : 0;
    
    cursor.center = CGPointMake(mouse_x, mouse_y);
    if (Level_ >= 5){
        postMouseEventIOHID(mouse_x, mouse_y, buttons);
    } else {
        postMouseEventGS(mouse_x, mouse_y, buttons);
    }
}


static void handleHomeLockVolumeButtonsGS(const button_event_t * button_event){

    

    struct GSEventRecord record;
    memset(&record, 0, sizeof(record));
    record.timestamp = GSCurrentEventTimestamp();

    switch (button_event->action){
        case HWButtonHome:
            record.type = (button_event->down) != 0 ? kGSEventMenuButtonDown : kGSEventMenuButtonUp;
            GSSendSystemEvent(&record);
            break;
        case HWButtonLock:
            record.type = (button_event->down) != 0 ? kGSEventLockButtonDown : kGSEventLockButtonUp;
            GSSendSystemEvent(&record);
            break;
        case HWButtonVolumeUp:
            record.type = (button_event->down) != 0 ? kGSEventVolumeUpButtonDown : kGSEventVolumeUpButtonUp;
            GSSendSystemEvent(&record);
            break;
        case HWButtonVolumeDown:
            record.type = (button_event->down) != 0 ? kGSEventVolumeDownButtonDown : kGSEventVolumeDownButtonUp;
            GSSendSystemEvent(&record);
            break;
        default:
            break;
    }
}

static void handleHomeLockVolumeButtonsIOHID(const button_event_t * button_event){

    

    int usage_page = 0;
    int usage = 0;
    switch (button_event->action){
        case HWButtonHome:
            usage_page = 12;
            usage = 0x40;
            break;
        case HWButtonLock:
            usage_page = 12;
            usage = 0x30;
            break;
        case HWButtonVolumeUp:
            usage_page = 0xe9;
            usage = 0x40;
            break;
        case HWButtonVolumeDown:
            usage_page = 12;
            usage = 0xea;
            break;
        default:
            return;
    }
   postIOHIDEvent(IOHIDEventCreateKeyboardEvent(kCFAllocatorDefault, mach_absolute_time(), usage_page, usage, button_event->down, 0));
}

static void handleButtonEvent(const button_event_t *button_event){
    
    

    SBMediaController *mc = [_logos_static_class_lookup$SBMediaController() sharedInstance];

    switch (button_event->action){
        case HWButtonHome:
        case HWButtonLock:
        case HWButtonVolumeUp:
        case HWButtonVolumeDown:
            if (Level_ >= 5){
                return handleHomeLockVolumeButtonsIOHID(button_event);
            } else {
                return handleHomeLockVolumeButtonsGS(button_event);               
            } 
            break;
        case HWButtonVolumeMute:
            if (!button_event->down) break;
            if (Level_ < 2) return;    
            [[_logos_static_class_lookup$VolumeControl() sharedVolumeControl] toggleMute];
            break;
        case HWButtonBrightnessUp:
            if (!button_event->down) break;
            [[_logos_static_class_lookup$SBBrightnessController() sharedBrightnessController] adjustBacklightLevel:YES];
            break;
        case HWButtonBrightnessDown:
            if (!button_event->down) break;
            [[_logos_static_class_lookup$SBBrightnessController() sharedBrightnessController] adjustBacklightLevel:NO];
            break;
        case HWButtonTogglePlayPause:
            if (!button_event->down) break;
            [mc togglePlayPause];
            break;
        case HWButtonPlay:
            if (!button_event->down) break;
	        if ([mc isPlaying]) break;
		    [mc togglePlayPause];
            break;
        case HWButtonPause:
            if (!button_event->down) break;
	        if (![mc isPlaying]) break;
		    [mc togglePlayPause];
            break;
        case HWButtonPreviousTrack:
            if (!button_event->down) break;
            [mc changeTrack:-1];
            break;
        case HWButtonNextTrack:
            if (!button_event->down) break;
            [mc changeTrack:+1];
            break;
        default:
            break;
    }
}

static bool isLocked() {
    if (!inSpringBoard) return NO;

    
    if ($SBAwayController){
        return [[$SBAwayController sharedAwayController] isLocked];
    }        
    if (_logos_static_class_lookup$SBLockScreenManager()){
        
        SBLockScreenManager * sbLockScreenManager = (SBLockScreenManager*) [_logos_static_class_lookup$SBLockScreenManager() sharedInstance];
        return [sbLockScreenManager isUILocked];
    }
    return NO;
}

static void undimDisplay(){
    if (!inSpringBoard) return;

    
    if ($SBAwayController){
        
        [(SpringBoard *)[_logos_static_class_lookup$SpringBoard() sharedApplication] resetIdleTimerAndUndim:YES];
    }
    if (_logos_static_class_lookup$SBLockScreenManager()){
        
        SBUserAgent * sbUserAget = [[_logos_static_class_lookup$SpringBoard() sharedApplication] pluginUserAgent];
        [sbUserAget undimScreen];

        
        [(SpringBoard *)[_logos_static_class_lookup$SpringBoard() sharedApplication] resetIdleTimerAndUndim];
    }
}

static void unlockDevice(){
    if (!inSpringBoard) return;

    
    if ($SBAwayController){
        
        bool wasDimmed = [[$SBAwayController sharedAwayController] isDimmed ];
        bool wasLocked = [[$SBAwayController sharedAwayController] isLocked ];
        
        
        if ( wasDimmed || wasLocked ){
            [[$SBAwayController sharedAwayController] attemptUnlock];
            [[$SBAwayController sharedAwayController] unlockWithSound:NO];
        }
    }
    if (_logos_static_class_lookup$SBLockScreenManager()){
        
        SBLockScreenManager * sbLockScreenManager = (SBLockScreenManager*) [_logos_static_class_lookup$SBLockScreenManager() sharedInstance];
        if ([sbLockScreenManager isUILocked]){
            [sbLockScreenManager unlockUIFromSource:0 withOptions:nil];
        }
    }
}

static void keepAwake(void){
    if (!inSpringBoard) return;
    if (isLocked()){
        unlockDevice();
    }
    undimDisplay();
}

static void init_graphicsservices(void){

    
    dlset($GSEventCreateKeyEvent, "GSEventCreateKeyEvent");
    dlset($GSCreateSyntheticKeyEvent, "_GSCreateSyntheticKeyEvent");
    dlset($GSEventSetKeyCode, "GSEventSetKeyCode");
    dlset($GSMainScreenSize, "GSMainScreenSize");
    dlset($GSMainScreenScaleFactor, "GSMainScreenScaleFactor");
    dlset($GSMainScreenOrientation, "GSMainScreenOrientation");
    dlset($GSEventCopyCharacters, "GSEventCopyCharacters");
    dlset($GSEventGetType, "GSEventGetType");
}

static void detect_iPads(void){
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char machine[size];
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    is_iPad1 = strcmp(machine, "iPad1,1") == 0;
}

void initialize(void){

    init_graphicsservices();
    dlset($IOHIDEventSetSenderID, "IOHIDEventSetSenderID");
    detect_iPads();

    
    if ($GSMainScreenScaleFactor) {
        retina_factor = $GSMainScreenScaleFactor();
    }
    if ($GSMainScreenSize){
        CGSize screenSize = $GSMainScreenSize();
        screen_width = screenSize.width / retina_factor;
        screen_height = screenSize.height / retina_factor;
    }
    if ($GSMainScreenOrientation){
        screen_orientation = $GSMainScreenOrientation();
    }

    
    mouse_max_x = screen_width - 1;
    mouse_max_y = screen_height - 1;

    
    

    
    
    
    
    

    if (is_iPad1){
        
        screen_rotation = MODE_A;
    } else if (screen_orientation == 0.0f) {
        
        screen_rotation = PORTRAIT;
    } else {
        screen_rotation = MODE_B;
    }

}

static CFDataRef myCallBack(CFMessagePortRef local, SInt32 msgid, CFDataRef cfData, void *info) {

    static BOOL initialized = NO;
    if (!initialized) {
        initialize();
        initialized = true;
    }
    
    const char *data = (const char *) CFDataGetBytePtr(cfData);
    uint16_t dataLen = CFDataGetLength(cfData);
    char *buffer;
    NSString * text;
    unsigned int i;
    
    key_event_t     * key_event;
    const mouse_event_t   * mouse_event;
    dimension_t dimension_result;
    CFDataRef returnData = NULL;
    CGPoint location;

    switch ( (hid_event_type_t) msgid){
        case TEXT:
            
            if (dataLen == 0 || !data) break;
            keepAwake();
            
            buffer = (char*) malloc(dataLen + 1);
            if (!buffer) {
                break;
            }
            memcpy(buffer, data, dataLen);
            buffer[dataLen] = 0;
            text = [NSString stringWithUTF8String:buffer];
            for (i=0; i< [text length]; i++){
                
                postKeyEvent(1, 0, [text characterAtIndex:i]);
                postKeyEvent(0, 0, [text characterAtIndex:i]);
            }
            free(buffer);
            break;
            
        case KEY:
            keepAwake();
            
            key_event = (key_event_t*) data;
            key_event->down = key_event->down ? 1 : 0;
            postKeyEvent(key_event->down, key_event->modifier, key_event->unicode);
            break;
            
        case MOUSE:
            if (dataLen != sizeof(mouse_event_t) || !data) break;
            mouse_event = (const mouse_event_t *) data;
            
            if (inSpringBoard){
                if (isLocked()){
                    if (mouse_event->buttons){
                        undimDisplay();
                        unlockDevice();
                    }
                } else {
                    undimDisplay();
                }
            }
            handleMouseEvent(mouse_event);
            break;
            
        case BUTTON:
            keepAwake();
            if (dataLen != sizeof(button_event_t) || !data) break;
              handleButtonEvent((const button_event_t *) data);
              break;
                    
        case GSEVENTRECORD:
            
            keepAwake();
            location = CGPointMake(100, 100);
            sendGSEvent((GSEventRecord*)data, location);
            break;
            
        case GET_SCREEN_DIMENSION:
            dimension_result.width  = screen_width;
            dimension_result.height = screen_height;
            returnData = CFDataCreate(kCFAllocatorDefault, (const uint8_t*) &dimension_result, sizeof(dimension_t));
            break;
        
        default:
            NSLog(@"HID_SUPPORT_PORT_NAME server, msgid %d not supported", (int) msgid);
            break;
    }
    return returnData;  
}

static void try_rocketbootstrap_cfmessageportexposelocal(CFMessagePortRef local){
    void * rbs_lib = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
    if (!rbs_lib) return;
    void (*cfmessageportexposelocal)(CFMessagePortRef) =(void (*)(CFMessagePortRef)) dlsym(rbs_lib, "rocketbootstrap_cfmessageportexposelocal");
    if (!cfmessageportexposelocal);
    cfmessageportexposelocal(local);
}

static void setupSpringboardMessagePort(){
    CFMessagePortRef local = CFMessagePortCreateLocal(NULL, CFSTR(HID_SUPPORT_PORT_NAME), myCallBack, NULL, NULL);
    CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(NULL, local, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
    try_rocketbootstrap_cfmessageportexposelocal(local);
}

static void setupBackboarddMessagePort(){
    CFMessagePortRef local = CFMessagePortCreateLocal(NULL, CFSTR(HID_SUPPORT_PORT_NAME_BB), myCallBack, NULL, NULL);
    CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(NULL, local, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
    try_rocketbootstrap_cfmessageportexposelocal(local);
}



static BOOL _logos_method$_ungrouped$UIApplication$handleEvent$withNewEvent$(_LOGOS_SELF_TYPE_NORMAL UIApplication* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, GSEventRef gsEvent, id arg2){
    if (Level_ >= 5 && gsEvent) {
        GSEventType gsType = $GSEventGetType(gsEvent);
        if (gsType == kGSEventKeyDown){
            CFStringRef text = $GSEventCopyCharacters(gsEvent);
            if (text){
                
                UIKeyboardImpl * keyboardImpl = (UIKeyboardImpl*) [_logos_static_class_lookup$UIKeyboardImpl() sharedInstance];
                [keyboardImpl addInputString:(NSString*)text];
                CFRelease(text);
            }
        }
    }
    return _logos_orig$_ungrouped$UIApplication$handleEvent$withNewEvent$(self, _cmd, gsEvent, arg2);
}


static void (*_logos_orig$SB$SpringBoard$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$SB$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id);  
#define cursorImage @"data:image/png;base64,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"




static void _logos_method$SB$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id application) {
    _logos_orig$SB$SpringBoard$applicationDidFinishLaunching$(self, _cmd, application);
    NSURL *url = [NSURL URLWithString:cursorImage];

    NSData *imageData = [NSData dataWithContentsOfURL:url];
    UIImage *circle = [UIImage imageWithData:imageData];

    cursorWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [cursorWindow setLevel:9999999];
    cursorWindow.userInteractionEnabled = NO;
    UIView *cursorContainer = [[UIView alloc] initWithFrame:[cursorWindow bounds]];
    cursor = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,20,20)];
    cursor.image = circle;
    [cursorContainer addSubview:cursor];
    [cursorWindow addSubview:cursorContainer];
    [cursorWindow makeKeyAndVisible];
}





static __attribute__((constructor)) void _logosLocalCtor_03ebc957(int __unused argc, char __unused **argv, char __unused **envp){
    detectOSLevel();
    

    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    

    if ([identifier isEqualToString:@"com.apple.backboardd"]){
        return;
        inBackboardd = YES;
        setupBackboarddMessagePort();
        return;
    }

   if ([identifier isEqualToString:@"com.apple.springboard"]){
        inSpringBoard = YES;
        setupSpringboardMessagePort();
        {Class _logos_class$SB$SpringBoard = objc_getClass("SpringBoard"); MSHookMessageEx(_logos_class$SB$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$SB$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$SB$SpringBoard$applicationDidFinishLaunching$);}
        return;
    }

    
    if (Level_ >= 5){
        
        {Class _logos_class$_ungrouped$UIApplication = objc_getClass("UIApplication"); MSHookMessageEx(_logos_class$_ungrouped$UIApplication, @selector(handleEvent:withNewEvent:), (IMP)&_logos_method$_ungrouped$UIApplication$handleEvent$withNewEvent$, (IMP*)&_logos_orig$_ungrouped$UIApplication$handleEvent$withNewEvent$);}
        init_graphicsservices();
    }
}
