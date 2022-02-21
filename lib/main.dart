import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spiderweb/github_issues.dart';
import 'package:tray_manager/tray_manager.dart';

const appDimensions = Size(600, 800);

void main() {
  runApp(const MyApp());
  doWhenWindowReady(() {
    trayManager
    // First thing we do is add the icon to the tray
        .setIcon('images/tray_icon_inactive.png')
    // Then we want to get the position of the tray icon
        .then((noValue) {
      var listener = TrayClickListener();
      trayManager.addListener(listener);
      if (kDebugMode) {
        listener.onTrayIconRightMouseUp();
      }
    });
  });
}

class TrayClickListener extends TrayListener {
  @override
  void onTrayIconMouseUp() {
    if (appWindow.isVisible) {
      trayManager.setIcon('images/tray_icon_inactive.png').then((noValue) {
        appWindow.hide();
      });
    } else {
      trayManager
          .setIcon('images/tray_icon_active.png')
      // Get the tray icon position so we can properly place the window
          .then((noValue) => trayManager.getBounds())
          .then((rect) {
        // Set these all the same so the window can't resize
        appWindow.minSize = appDimensions;
        appWindow.maxSize = appDimensions;
        appWindow.size = appDimensions;

        // I have found that the left/top properties can be mixed depending on
        // when the getBounds method is called. We know for a fact that the y
        // position should always be close to zero (if not zero), so we can assume
        // the smaller number is always the y value
        var x = rect.left > rect.top ? rect.left : rect.top;
        var y = x == rect.left ? rect.top : rect.left;

        // Set the position so the icon is above the middle of the window
        appWindow.position = Offset(x - (appDimensions.width / 2), y + 4);
        appWindow.title = 'Flutter Menubar App';
        appWindow.show();
      });
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spiderweb',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const GithubIssues(),
    );
  }
}
