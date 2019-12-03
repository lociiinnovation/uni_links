#import "UniLinksPlugin.h"

static NSString *const kMessagesChannel = @"uni_links/messages";
static NSString *const kEventsChannel = @"uni_links/events";
static BOOL isAppAlreadyLaunchedOnce;

@interface UniLinksPlugin () <FlutterStreamHandler>
@property(nonatomic, copy) NSString *initialLink;
@property(nonatomic, copy) NSString *latestLink;
@end

@implementation UniLinksPlugin {
  FlutterEventSink _eventSink;
}

static id _instance;

+ (UniLinksPlugin *)sharedInstance {
  if (_instance == nil) {
    _instance = [[UniLinksPlugin alloc] init];
  }
  return _instance;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  UniLinksPlugin *instance = [UniLinksPlugin sharedInstance];

  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kMessagesChannel
                                  binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:channel];

  FlutterEventChannel *chargingChannel =
      [FlutterEventChannel eventChannelWithName:kEventsChannel
                                binaryMessenger:[registrar messenger]];
  [chargingChannel setStreamHandler:instance];

  [registrar addApplicationDelegate:instance];
}

- (void)setLatestLink:(NSString *)latestLink {
  static NSString *key = @"latestLink";

  [self willChangeValueForKey:key];
  _latestLink = [latestLink copy];
  [self didChangeValueForKey:key];

  if (_eventSink) _eventSink(_latestLink);
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
      isAppAlreadyLaunchedOnce = UserDefaults.isFirstLaunch() 
  NSURL *url = (NSURL *)launchOptions[UIApplicationLaunchOptionsURLKey];
  self.initialLink = [url absoluteString];
  self.latestLink = self.initialLink;
  return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  self.latestLink = [url absoluteString];
  return YES;
}

- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler {
  if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
    self.latestLink = [userActivity.webpageURL absoluteString];
    if (!_eventSink) {
      self.initialLink = self.latestLink;
    }
    return YES;
  }
  return NO;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"getInitialLink" isEqualToString:call.method]) {
    result(self.initialLink);
     } else if ([@"getInstallReferrer" isEqualToString:call.method] ) {
       NSString *referrer = nil;
       if (isAppAlreadyLaunchedOnce) {
       NSString *url = call.arguments[@"url"];
     referrer = [self getReferrer: url];
       }
       else {
         referrer = @"isAppAlreadyLaunchedOnce";
       }
         result(referrer);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)eventSink {
  _eventSink = eventSink;
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  _eventSink = nil;
  return nil;
}

- (NSString *) getReferrer : (NSString *) url {
    NSString* userAgent = @"trUUthKYCApp/1.0 (iPhone)";
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];

    NSError *error = nil;
    NSHTTPURLResponse *responseCode = nil;
    NSData *JSONData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %i", url, [responseCode statusCode]);
        return [request valueForHTTPHeaderField:@"User-Agent"];
    }
        id jsonResult = [NSJSONSerialization JSONObjectWithData:JSONData options:kNilOptions error:nil];
   // return jsonResult[@"referrer"];
   return jsonResult[@"referrer"];
}

@end
