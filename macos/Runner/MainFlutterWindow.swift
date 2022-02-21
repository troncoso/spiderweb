import Cocoa
import FlutterMacOS
import bitsdojo_window_macos

class MainFlutterWindow: BitsdojoWindow {
    override func bitsdojo_window_configure() -> UInt {
        return BDW_HIDE_ON_STARTUP;
    }

    override func awakeFromNib() {
          let flutterViewController = FlutterViewController.init();
          let windowFrame = self.frame;
          
          self.contentViewController = flutterViewController;
          self.setFrame(windowFrame, display: true);

          // Make the corners rounded
          self.isOpaque = false;
          self.backgroundColor = NSColor.clear;
          self.contentView?.wantsLayer = true;
          self.contentView?.layer?.backgroundColor = NSColor.clear.cgColor;
          self.contentView?.layer?.masksToBounds = true;
          self.contentView?.layer?.cornerRadius = 8.0;
          // Ensure this app is always on top when it is visible
          self.level = .floating;
          // If this app loses focus, hide it
//           self.hidesOnDeactivate = true;
          
          RegisterGeneratedPlugins(registry: flutterViewController);

          super.awakeFromNib();
    }
}
