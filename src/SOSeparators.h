//Created by Salty on 12/20/25.

#import <Foundation/Foundation.h>
#import <Appkit/Appkit.h>
#import <objc/runtime.h>

@interface SOSeparators : NSObject @end
@interface NSContextMenuItemView : NSObject @end

static bool SYSTEM_DARK_MODE;

static void (*orig_TableRowViewDrawInRect)(id, SEL, NSRect);
static CGRect LAST_REQ_SEP_RECT;

typedef BOOL (*AppearanceDrawIMP)(
    id self,
    SEL _cmd,
    CGRect rect,
    CGContextRef context,
    NSDictionary *options
);
static AppearanceDrawIMP orig_NSAppearance_drawInRect;
