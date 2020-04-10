#line 1 "Tweak.xm"




 
#include <objc/runtime.h>
#include "../hid-support-internal.h"
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <mach/mach.h>    
#include <mach/mach_time.h>    
#include <IOKit/hid/IOHIDEvent.h>   
#define KEYCODE_RETURN     '\n'
#define KEYCODE_ESCAPE      27

@interface BRWindow : NSObject
+ (BOOL)dispatchEvent:(id)event;    
@end

@interface BREvent : NSObject
+ (id)eventWithAction:(int)action value:(int)value atTime:(double)time originator:(unsigned)originator eventDictionary:(id)dictionary allowRetrigger:(BOOL)retrigger;   
@end
@interface BRApplicationStackManager:NSObject

+ (id)singleton;
- (id)stack;

@end;
@interface BRControllerStack:NSObject
- (id)peekController;
@end
@interface BRMenuController:NSObject
-(id)controls;
@end
@interface MoviesController:NSObject
@end
@interface BRViewController:NSObject
@end
@interface BRTextEntryControl:NSObject
-(void)deviceKeyboardClose;
- (void)_invokeInputActionWithDictionary:(id)dictionary;
@end
@interface BRMainMenuController:NSObject
@end
@interface BRTextEntryController:NSObject
@property(readonly, retain) BRTextEntryControl *editor;
@end
@interface BRSettingsFacade:NSObject
+ (id)singleton;
- (id)versionOS;    
- (id)versionOSBuild;   
- (id)versionSoftware;  
- (id)versionSoftwareBuild;
@end
static Class $BRSettingsFacade          = objc_getClass("BRSettingsFacade");
static Class $BRMainMenuController      = objc_getClass("BRMainMenuController");
static Class $BREvent                   = objc_getClass("BREvent");
static Class $BRWindow                  = objc_getClass("BRWindow");
static Class $BRApplicationStackManager = objc_getClass("BRApplicationStackManager");
static Class $BRControllerStack         = objc_getClass("BRControllerStack");
static Class $BRMenuController          = objc_getClass("BRMenuController");
static Class $MoviesController          = objc_getClass("MoviesController");
static Class $BRTextEntryController     = objc_getClass("BRTextEntryController");
static Class $BRViewController          = objc_getClass("BRViewController");
static Class $BRMediaMenuController     = objc_getClass("BRMediaMenuController");
static Class $BRTextEntryControl        = objc_getClass("BRTextEntryControl");
static void injectRemoteAction(int action, int down){
    
    BREvent * event = [$BREvent eventWithAction:action value:down atTime:7400.0 originator:5 eventDictionary:nil allowRetrigger:1];
    [$BRWindow dispatchEvent:event];
}

static BRRemoteAction_t getRemoteActionForKey(uint16_t key){
    switch (key){
        case KEYCODE_ESCAPE:
            return BRRemoteActionMenu;
        case KEYCODE_RETURN:
            return BRRemoteActionSelect;
        case NSRightArrowFunctionKey:
            return BRRemoteActionRight;
        case NSLeftArrowFunctionKey:
            return BRRemoteActionLeft;
        case NSDownArrowFunctionKey:
            return BRRemoteActionDown;
        case NSUpArrowFunctionKey:
            return BRRemoteActionUp;
        default:
            return BRRemoteActionInvalid;
    }
}
static CFDataRef myCallBack(CFMessagePortRef local, SInt32 msgid, CFDataRef cfData, void *info) {
    
    const char *data = (const char *) CFDataGetBytePtr(cfData);
    UInt16 dataLen = CFDataGetLength(cfData);
    char *buffer;
    NSString * text;
    BREvent *event = nil;
    BRRemoteAction_t action;
    NSDictionary * eventDictionary;
    
    key_event_t     * key_event;
    remote_action_t * remote_action;
    unichar           theChar;
    
    
    

    switch ( (hid_event_type_t) msgid){

        case TEXT:
            
            if (dataLen == 0 || !data) break;
            
            buffer = (char*) malloc( dataLen + 1);
            if (!buffer) {
                break;
            }
            memcpy(buffer, data, dataLen);
            buffer[dataLen] = 0;
            text = [NSString stringWithUTF8String:buffer];
            
            eventDictionary = [NSDictionary dictionaryWithObject:text forKey:@"kBRKeyEventCharactersKey"];
            event = [$BREvent eventWithAction:BRRemoteActionKey value:1 atTime:7400.0 originator:5 eventDictionary:eventDictionary allowRetrigger:1];
            [$BRWindow dispatchEvent:event];
            free(buffer);
            break;
            
        case KEY: {
            
            key_event = (key_event_t*) data;
            key_event->down = key_event->down ? 1 : 0;
            
            
            if(key_event->unicode == KEYCODE_RETURN &&  
               key_event->down){                        
               
                id c = [[[$BRApplicationStackManager singleton] stack] peekController];
                if([c isKindOfClass:$BRTextEntryController])
                {
                    [[c editor] _invokeInputActionWithDictionary:[NSDictionary dictionaryWithObject:@"_inputActionEscape:" forKey:@"Action"]];
                    break;
                }
                
            }
            action = getRemoteActionForKey(key_event->unicode);

            if (action){
                if (action == BRRemoteActionMenu   &&  key_event->down) break; 
                if (action == BRRemoteActionSelect && !key_event->down) break; 
                injectRemoteAction(action, key_event->down);
                break;
            }
            
            
            if (!key_event->down) break;
            
            theChar = key_event->unicode;
            text = [NSString stringWithCharacters:&theChar length:1];
            if([text isEqualToString:@" "]) {
                id c = [[[$BRApplicationStackManager singleton] stack] peekController];
                if (([c isKindOfClass:$BRMenuController]||
                    [c isKindOfClass:$BRViewController]||
                    [c isKindOfClass:$BRMainMenuController]) && 
                    ![c isKindOfClass:$BRTextEntryController]) {

                    NSInteger v = [[c controls]indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                        if ([obj isKindOfClass:$BRTextEntryControl]) {
                                *stop = YES;
                                return YES;
                            }
                            return NO;
                            }];
                    if(v==NSNotFound) {
                        injectRemoteAction(BRRemoteActionSelect,1);
                        break;
                    }
                }
            }
            
            NSString *osBuild = [[$BRSettingsFacade singleton]versionOSBuild];
            int dicEventKeyCode = 48;
            if([osBuild isEqualToString:@"8M89"])
                dicEventKeyCode = 47;
            else if([osBuild isEqualToString:@"8C154"]||[osBuild isEqualToString:@"8C150"])
                dicEventKeyCode = 48;
                






            eventDictionary = [NSDictionary dictionaryWithObject:text forKey:@"kBRKeyEventCharactersKey"];
            event = [$BREvent eventWithAction:dicEventKeyCode value:key_event->down atTime:7400.0 originator:5 eventDictionary:eventDictionary allowRetrigger:1];
            [$BRWindow dispatchEvent:event];
            break;
        }
            
        case REMOTE:
            
            remote_action = (remote_action_t*) data;
            remote_action->down = remote_action->down ? 1 : 0;
            injectRemoteAction(remote_action->action, remote_action->down);
            break;
            
        default:
            NSLog(@"HID_SUPPORT_PORT_NAME server, msgid %d not supported", (int) msgid);
    }
    return NULL;  
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

@class LTAppDelegate; 
static void (*_logos_orig$_ungrouped$LTAppDelegate$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL LTAppDelegate* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$LTAppDelegate$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL LTAppDelegate* _LOGOS_SELF_CONST, SEL, id); 

#line 219 "Tweak.xm"

static void _logos_method$_ungrouped$LTAppDelegate$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL LTAppDelegate* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id fp8) {
NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    CFMessagePortRef local = CFMessagePortCreateLocal(NULL, CFSTR(HID_SUPPORT_PORT_NAME), myCallBack, NULL, NULL);
    CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(NULL, local, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    [pool release]; 
    
    _logos_orig$_ungrouped$LTAppDelegate$applicationDidFinishLaunching$(self, _cmd, fp8);
    
}

static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$LTAppDelegate = objc_getClass("LTAppDelegate"); MSHookMessageEx(_logos_class$_ungrouped$LTAppDelegate, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$_ungrouped$LTAppDelegate$applicationDidFinishLaunching$, (IMP*)&_logos_orig$_ungrouped$LTAppDelegate$applicationDidFinishLaunching$);} }
#line 231 "Tweak.xm"
