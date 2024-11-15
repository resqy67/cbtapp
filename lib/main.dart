import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/webViewScreen.dart';
import 'package:webview_flutter/webview_flutter.dart';
// import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
  bool _showWarning = false; // show warning dialog
  bool _isInitialized = false; // check if the app is initialized
  final cookieManager = WebViewCookieManager(); // cookie manager
  String _appVersion = 'Unknown'; // app version

  @override
  void initState() {
    super.initState();
    // see if the app is in the background
    WidgetsBinding.instance.addObserver(this);
    // start screen pinning
    enableScreenPinning();
    // _getAppVersion();
    // if (await _isVivoDevice()){
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Timer(const Duration(seconds: 5), () {
    //     setState(() {
    //       _isInitialized = true; // Tandai bahwa aplikasi sudah berjalan
    //     });
    //   });
    // });
    // }
    enableScreenPinning();

    // Tunggu 10 detik sebelum menandai bahwa aplikasi sudah berjalan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 5), () {
        setState(() {
          _isInitialized = true; // Tandai bahwa aplikasi sudah berjalan
          print('isInitialized aktif: $_isInitialized');
        });
      });
    });
    // listen for method channel messages
    MethodChannel('com.example.cbtapp/screenPinning')
        .setMethodCallHandler((call) async {
      if (call.method == 'showWarning') {
        if (_isInitialized) {
          // Tampilkan warning jika aplikasi sudah berjalan
          setState(() {
            _showWarning = true;
            print('showWarning aktif: $_showWarning');
          });
        } else {
          print(
              'showWarning ditunda karena aplikasi belum berjalan cukup lama');
        }
      }
    });
  }

  @override
  void dispose() {
    // remove observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // check if the device is a Vivo device
  // Future<bool> _isVivoDevice() async {
  //   final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   final androidInfo = await deviceInfo.androidInfo;
  //   return androidInfo.brand.toLowerCase() == 'vivo';
  // }

  Future<void> _getAppVersion() async {
    const platform = MethodChannel('com.example.cbtapp/screenPinning');
    String version;
    try {
      version = await platform.invokeMethod('getAppVersion');
    } on PlatformException catch (e) {
      version = "Failed to get version: '${e.message}'.";
    }
    print('versionnya $version');

    setState(() {
      _appVersion = version;
    });
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
      // getVersion();
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
                  color: Colors.red,
                  child: Dialog(
                    backgroundColor: Colors.red,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Peringatan!!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Anda terdeteksi mencoba keluar dari aplikasi, silahkan klik tombol "tutup" untuk keluar dari aplikasi lalu buka kembali aplikasi.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                            "laporkan kepada pengawas untuk reset akun anda",
                            textAlign: TextAlign.justify,
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
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Tutup Aplikasi',
                              style: TextStyle(fontSize: 18)),
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
