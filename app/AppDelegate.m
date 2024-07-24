#import <BareKit/BareKit.h>
#import "AppDelegate.h"
#import "app.bundle.h"
#import <UIKit/UIKit.h>


@implementation AppDelegate {
  BareWorklet *worklet;
  BareIPC *ipc;
  BareRPC *rpc;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  worklet = [[BareWorklet alloc] init];

  [worklet start:@"/main.bundle"
          source:[NSData dataWithBytes:bundle length:bundle_len]];

  // Set a default string to show before clipboard content is received
  __block NSString *ipcData = @"Waiting for Clipboard connection...";

  //////////////////////////
  // Start designing UI ///
  ////////////////////////

  // Add UIImageView to display the logo
  UIImage *logoImage = [UIImage imageNamed:@"Logo"];

  UIImageView *logoImageView = [[UIImageView alloc] initWithImage:logoImage];
  logoImageView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 100) / 5.5, 200, 250, -300); // Adjust the size and position as needed
  logoImageView.contentMode = UIViewContentModeScaleAspectFit;

  // Add UILabel to display clipboard content
  UILabel *helloLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 40)];
  // ipcData stores data received from other peer. We will update it dynamically
  helloLabel.text = ipcData;
  helloLabel.textColor = [UIColor whiteColor];
  helloLabel.backgroundColor = [self colorFromHexString:@"#1b1d29"];
  helloLabel.textAlignment = NSTextAlignmentCenter;
  helloLabel.font = [UIFont systemFontOfSize:18];

  // Create a button to copy content to clipboard
  UIButton *copyButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [copyButton setTitle:@"Copy Text" forState:UIControlStateNormal];
  [copyButton addTarget:self action:@selector(copyTextButtonTapped) forControlEvents:UIControlEventTouchUpInside];
  copyButton.frame = CGRectMake(0, 150, [UIScreen mainScreen].bounds.size.width, 40);

  //////////////////////////
  //       END UI       ///
  ////////////////////////

  // Create a UIViewController to contain the label, button, and image view
  UIViewController *rootViewController = [[UIViewController alloc] init];
  [rootViewController.view addSubview:logoImageView];
  [rootViewController.view addSubview:helloLabel];
  [rootViewController.view addSubview:copyButton];

  // Set the background color of the view controller's view
  rootViewController.view.backgroundColor =  [self colorFromHexString:@"#1b1d29"];

  // Set up the window
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];


  //////////////////////////
  //      START IPC     ///
  ////////////////////////

  // This part of code will setup IPC using bare and transfer data to and from app.js
  ipc = [[BareIPC alloc] initWithWorklet:worklet];

  // Setup Bare request handler
  BareRPCRequestHandler requestHandler = ^(BareRPCIncomingRequest *req, NSError *error) {
    // Handle ping request
    if ([req.command isEqualToString:@"ping"]) {
      CFShow([req dataWithEncoding:NSUTF8StringEncoding]);
      // Stored received data
      ipcData = [req dataWithEncoding:NSUTF8StringEncoding];
      // Update helloLabel with the latest clipboard data
      helloLabel.text = ipcData;

      CFShow(ipcData);
    }
  };

  rpc = [[BareRPC alloc] initWithIPC:ipc requestHandler:requestHandler];

  //////////////////////////
  //      END IPC       ///
  ////////////////////////

  return YES;
}

// Add a method to handle the button tap
- (void)copyTextButtonTapped {
  // Get the text from the label
  NSString *textToCopy = @"No data received yet.";

  // Create a UIPasteboard object
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];

  // Set the text to the pasteboard
  [pasteboard setString:textToCopy];

  // Log a message to the console
  NSLog(@"Text copied to clipboard!");
}

// Helper method to convert hex string to UIColor
- (UIColor *)colorFromHexString:(NSString *)hexString {
  unsigned rgbValue = 0;
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner setScanLocation:1]; // bypass '#' character
  [scanner scanHexInt:&rgbValue];
  return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                         green:((rgbValue & 0x00FF00) >> 8) / 255.0
                          blue:(rgbValue & 0x0000FF) / 255.0
                         alpha:1.0];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  [worklet suspend];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  [worklet resume];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [ipc close];
  [worklet terminate];
}

@end
