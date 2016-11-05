// compile and run from the commandline with:
//    clang -fobjc-arc -framework Cocoa  ./debounce.m  -o debounce
//    sudo ./debounce

/*
 * Keyboard debouncer, main audience is users of flaky mechanical
 * keyboards.  Script heavily inspired by Brad Allred's answer on
 * StackOverflow:
 * <http://stackoverflow.com/questions/19646108/modify-keydown-output>.
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSEvent.h>

#define DEBOUNCE_DELAY 100
#define SYNTHETIC_KB_ID 666

typedef CFMachPortRef EventTap;

@interface KeyChanger : NSObject
{
@private
  EventTap _eventTap;
  CFRunLoopSourceRef _runLoopSource;
  long long lastKeytime;
  UInt16 lastKeycode;
}
@end

CGEventRef _tapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, KeyChanger* listener);

@implementation KeyChanger

- (BOOL)tapEvents
{
  if (!_eventTap) {
    NSLog(@"Initializing an event tap.");

    _eventTap = CGEventTapCreate(kCGSessionEventTap,
                                 kCGTailAppendEventTap,
                                 kCGEventTapOptionDefault,
                                 CGEventMaskBit(kCGEventKeyDown),
                                 (CGEventTapCallBack)_tapCallback,
                                 (__bridge void *)(self));
    if (!_eventTap) {
      NSLog(@"Unable to create event tap.  Must run as root or add privlidges for assistive devices to this app.");
      return NO;
    }
  }
  CGEventTapEnable(_eventTap, TRUE);

  return [self isTapActive];
}

- (BOOL)isTapActive
{
  return CGEventTapIsEnabled(_eventTap);
}

- (void)listen
{
  if (!_runLoopSource) {
    if (_eventTap) { // Don't use [self tapActive]
      _runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault,
                                                     _eventTap, 0);
      // Add to the current run loop.
      CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource,
                         kCFRunLoopCommonModes);

      NSLog(@"Registering event tap as run loop source.");
      CFRunLoopRun();
    }else{
      NSLog(@"No Event tap in place!  You will need to call listen after tapEvents to get events.");
    }
  }
}

- (CGEventRef)processEvent:(CGEventRef)cgEvent
{
  NSEvent* event = [NSEvent eventWithCGEvent:cgEvent];

  long long currentKeytime = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  UInt16 currentKeycode = [event keyCode];
  BOOL debounce = NO;
  long long keyboard_id = CGEventGetIntegerValueField(cgEvent, kCGKeyboardEventKeyboardType);

  if (keyboard_id != SYNTHETIC_KB_ID &&
      currentKeycode == lastKeycode &&
      ![event isARepeat] &&
      (currentKeytime - lastKeytime) < DEBOUNCE_DELAY) {

    NSLog(@"BOUNCE detected!!!  Character: %@",
          event.characters);
    NSLog(@"Time between keys: %lldms (limit <%dms)",
          (currentKeytime - lastKeytime),
          DEBOUNCE_DELAY);

    // Cancel keypress event
    debounce = YES;
  }

  if(debounce) {
    return NULL;
  }

  lastKeytime = currentKeytime;
  lastKeycode = currentKeycode;

  return cgEvent;
}

- (void)dealloc
{
  if (_runLoopSource){
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
    CFRelease(_runLoopSource);
  }
  if (_eventTap){

    // Kill the event tap
    CGEventTapEnable(_eventTap, FALSE);
    CFRelease(_eventTap);
  }
}

@end

CGEventRef _tapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, KeyChanger* listener) {
  // Do not make the NSEvent here.
  // NSEvent will throw an exception if we try to make an event from the tap timeout type
  @autoreleasepool {
    if(type == kCGEventTapDisabledByTimeout) {
      NSLog(@"event tap has timed out, re-enabling tap");
      [listener tapEvents];
      return nil;
    }
    if (type != kCGEventTapDisabledByUserInput) {
      return [listener processEvent:event];
    }
  }
  return event;
}

int main(int argc, const char * argv[])
{
  @autoreleasepool {
    KeyChanger* keyChanger = [KeyChanger new];
    [keyChanger tapEvents];
    [keyChanger listen]; // This is a blocking call.
  }
  return 0;
}
