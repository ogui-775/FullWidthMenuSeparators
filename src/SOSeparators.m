//Created by Salty on 12/20/25.

#import "SOSeparators.h"

static BOOL isXPCService(void){
    NSBundle * bundle = [NSBundle mainBundle];
    NSString * path = bundle.bundlePath;
    return [path containsString:@".xpc"];
}

static BOOL isDockXPC(void){
    NSString * bundleId = [NSBundle mainBundle].bundleIdentifier;
    return [bundleId containsString:@"dock"];
}

@implementation SOSeparators

+ (void)load{
    if (!isXPCService() || isDockXPC()){
        [self.class widenTableSeparators];
        [self.class swizzleAppearanceDrawInRect];
    }
}

static NSString * const kThreadSeparatorRectKey = @"com.salty.LastSeparatorRect";

+ (void)widenTableSeparators {
    Class cls = NSClassFromString(@"NSContextMenuItemView");
    SEL sel = NSSelectorFromString(@"drawRect:");
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return;

    orig_TableRowViewDrawInRect = (void *)method_getImplementation(m);

    IMP new_TableRowViewDrawInRect = imp_implementationWithBlock(^(id selfObj, NSRect rect){
        if ([[selfObj menuItem] isSeparatorItem]){
            CGFloat y = NSMidY(rect) - 0.5;
            CGRect sepRect = CGRectMake(0, y, [selfObj superview].bounds.size.width, 1.0);

            NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
            threadDict[kThreadSeparatorRectKey] = @{
                @"x": @(sepRect.origin.x),
                @"y": @(sepRect.origin.y),
                @"width": @(sepRect.size.width),
                @"height": @(sepRect.size.height)
            };

            [selfObj setNeedsDisplayInRect:sepRect];
        }

        orig_TableRowViewDrawInRect(selfObj, sel, rect);
    });

    method_setImplementation(m, new_TableRowViewDrawInRect);
}

+ (void)swizzleAppearanceDrawInRect {
    Class cls = NSClassFromString(@"NSAppearance");
    if (!cls) return;

    SEL sel = NSSelectorFromString(@"_drawInRect:context:options:");
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return;

    orig_NSAppearance_drawInRect =
        (AppearanceDrawIMP)method_getImplementation(m);

    IMP newImp = imp_implementationWithBlock(
        ^BOOL(id self, CGRect rect, CGContextRef ctx, NSDictionary *options) {
            NSDictionary *rectDict = [[NSThread currentThread].threadDictionary objectForKey:kThreadSeparatorRectKey];
            
            if (rectDict && [[options valueForKey:@"widget"] isEqualToString:@"kCUIWidgetMenuItemSeparator"]) {
                rect = CGRectMake(
                    [rectDict[@"x"] doubleValue],
                    [rectDict[@"y"] doubleValue],
                    [rectDict[@"width"] doubleValue],
                    [rectDict[@"height"] doubleValue]
                );
            }

            return orig_NSAppearance_drawInRect(self, sel, rect, ctx, options);
        }
    );

    method_setImplementation(m, newImp);
}

@end
