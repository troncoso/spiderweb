import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("Application should NOT terminate after last window closed");
        return false;
    }
    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("Application should handle reopen");
        return true;
    }
    
    override func applicationWillFinishLaunching(_ notification: Notification) {
        print("Application will finish launching");
    }
    override func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application finished launching");
    }
    
    override func applicationWillUnhide(_ notification: Notification) {
        print("Application will unhide");
    }
    override func applicationDidUnhide(_ notification: Notification) {
        print("Application unhidden");
    }
    
    override func applicationWillHide(_ notification: Notification) {
        print("Application will hide");
    }
    override func applicationDidHide(_ notification: Notification) {
        print("Application hidden");
    }
    
    override func applicationWillBecomeActive(_ notification: Notification) {
        print("Application will become active");
    }
    override func applicationDidBecomeActive(_ notification: Notification) {
        print("Application became active");
    }
    
    override func applicationWillResignActive(_ notification: Notification) {
        print("Application will resign active");
    }
    override func applicationDidResignActive(_ notification: Notification) {
        print("Application resigned active");
    }
    
    override func applicationWillUpdate(_ notification: Notification) {
//         print("Application will update");
    }
    override func applicationDidUpdate(_ notification: Notification) {
//         print("Application updated");
    }
}
