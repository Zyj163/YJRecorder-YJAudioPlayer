
#define YJSingleton_h(name) + (instancetype)shared##name;


#if __has_feature(objc_arc)
    #define YJSingleton_m(name)\
    \
    static id _instance = nil;\
    \
    + (instancetype)shared##name {\
        static dispatch_once_t once;\
        dispatch_once(&once, ^{\
        _instance = [[self alloc]init];\
        });\
        return _instance;\
    }\
    \
    + (instancetype)allocWithZone:(struct _NSZone *)zone {\
        static dispatch_once_t once;\
        dispatch_once(&once, ^{\
        _instance = [super allocWithZone:zone];\
        });\
        return _instance;\
    }\
    \
    - (id)copyWithZone:(NSZone *)zone {\
    return _instance;\
    }
#else
    #define YJSingleton_m(name)\
    \
    static id _instance = nil;\
    \
    + (instancetype)shared##name {\
        static dispatch_once_t once;\
        dispatch_once(&once, ^{\
        _instance = [[self alloc]init];\
        });\
        return _instance;\
    }\
    \
    + (instancetype)allocWithZone:(struct _NSZone *)zone {\
        static dispatch_once_t once;\
        dispatch_once(&once, ^{\
        _instance = [super allocWithZone:zone];\
        });\
        return _instance;\
    }\
    \
    - (id)copyWithZone:(NSZone *)zone {\
        return _instance;\
    }\
    - (oneway void)release {\
        \
    }\
    \
    - (id)retain {\
        return _instance;\
    }\
    \
    - (NSUInteger)retainCount {\
        return 1;\
    }\
    \
    - (id)autorelease {\
        return _instance;\
    }
#endif


