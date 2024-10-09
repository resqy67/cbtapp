import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/webViewScreen.dart';

void main() {
  runApp(const MainApp());
  SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky); // hide the system UI
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  bool _isExiting = false; // check if the user is trying to exit the app
  @override
  void initState() {
    super.initState();
    // see if the app is in the background
    WidgetsBinding.instance.addObserver(this);
    // start screen pinning
    enableScreenPinning();
  }

  @override
  void dispose() {
    // remove observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // handle app lifecycle state changes if the app is in the background or inactive
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // if the app is in the background or inactive, bring the app to the foreground
    // except when the user is trying to exit the app
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        !_isExiting) {
      _bringAppToForeground();
    }
  }

  // enable screen pinning
  Future<void> enableScreenPinning() async {
    const platform = MethodChannel('com.example.cbtapp/screenPinning');
    try {
      await platform.invokeMethod(
          'enableScreenPinning'); // invoke the method channel to enable screen pinning
    } on PlatformException catch (e) {
      print("Failed to enable screen pinning: '${e.message}'.");
    }
  }

  // bring the app to the foreground
  void _bringAppToForeground() {
    const platform = MethodChannel('com.example.cbtapp/screenPinning');
    try {
      platform.invokeMethod(
          'bringToForeground'); // invoke the method channel to bring the app to the foreground
    } on PlatformException catch (e) {
      print("Failed to bring app to foreground: '${e.message}'.");
    }
  }

  // disable screen pinning
  Future<void> _disableScreenPinning() async {
    const platform = MethodChannel('com.example.cbtapp/screenPinning');
    try {
      await platform.invokeMethod(
          'disableScreenPinning'); // invoke the method channel to disable screen pinning
    } on PlatformException catch (e) {
      print("Failed to disable screen pinning: '${e.message}'.");
    }
  }

  // exit the app
  Future<void> _exitApp() async {
    setState(() {
      _isExiting =
          true; // mark bool as true after the user tries to exit the app
    });
    await _disableScreenPinning(); // disable screen pinning
    SystemNavigator.pop(); // exit the app
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // hide the debug banner
      home: WebViewScreen(
        onExitApp: _exitApp, // exit the app
      ),
    );
  }
}
