import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/webViewScreen.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  bool _showWarning = false;
  final cookieManager = WebViewCookieManager(); // cookie manager

  @override
  void initState() {
    super.initState();
    // see if the app is in the background
    WidgetsBinding.instance.addObserver(this);
    // start screen pinning
    enableScreenPinning();
    MethodChannel('com.example.cbtapp/screenPinning')
        .setMethodCallHandler((call) async {
      if (call.method == 'showWarning') {
        setState(() {
          _showWarning = true;
          print('show warningnya $_showWarning');
        });
      }
    });
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

  Future<void> _onClearCookies() async {
    await cookieManager.clearCookies();
    // String message = 'There were cookies. Now, they are gone!';
    // if (!hadCookies) {
    //   message = 'There were no cookies to clear.';
    // }
    // if (!mounted) return null;
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(message),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // hide the debug banner
      home: Stack(children: [
        WebViewScreen(
          onExitApp: _exitApp, // exit the app
        ),
        // show a warning dialog if the user tries to exit the app
        if (_showWarning) // Tampilkan peringatan jika diperlukan
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.red,
                  child: Dialog(
                    backgroundColor: Colors.red,
                    child: Column(
                      // mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Peringatan!!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Anda terdeteksi mencoba keluar dari aplikasi, silahkan klik tombol "tutup" untuk keluar dari aplikasi lalu buka kembali aplikasi.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                            "laporkan kepada pengawas untuk reset akun anda",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            )),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showWarning = false;
                              _onClearCookies();
                              _exitApp();
                            });
                          },
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  )),
            ),
          ),
      ]),
    );
  }
}
