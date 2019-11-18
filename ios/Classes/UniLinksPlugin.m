#import "UniLinksPlugin.h"

static NSString *const kMessagesChannel = @"uni_links/messages";
static NSString *const kEventsChannel = @"uni_links/events";

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
     } else if ([@"getInstallReferrer" isEqualToString:call.method]) {
       NSString *referrer = @"test";
       //check app first launch
//  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isAppAlreadyLaunchedOnce"])
//{
 //   [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isAppAlreadyLaunchedOnce"];
 //   [[NSUserDefaults standardUserDefaults] synchronize];
       NSString *url = call.arguments[@"url"];
    // referrer = [self getReferrer:url];
// }
         result(url);
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

- (NSString *) getReferrer : (NSString *)url {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
   // NSString *url = @"https://jsonplaceholder.typicode.com/todos/1";
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    NSError *error = nil;
    NSHTTPURLResponse *responseCode = nil;
    NSData *JSONData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %i", url, [responseCode statusCode]);
        return @"nothing";
    }
        id jsonResult = [NSJSONSerialization JSONObjectWithData:JSONData options:kNilOptions error:nil];
   // return jsonResult[@"referrer"];
   return jsonResult[@"title"];
}

@end
