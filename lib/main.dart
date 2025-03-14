import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/webView.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  final _cookieManager = WebViewCookieManager();
  final _platformChannel =
      const MethodChannel('com.example.cbtapp/screenPinning');
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isConnected = true;
  bool _showWarning = false;
  bool _isExiting = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectivityStatus);
    _enableScreenPinning();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      });
    });

    _platformChannel.setMethodCallHandler((call) async {
      if (call.method == 'showWarning' && _isInitialized) {
        setState(() => _showWarning = true);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(results);
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    if (mounted) {
      setState(() => _isConnected =
          results.isNotEmpty && results.first != ConnectivityResult.none);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        !_isExiting) {
      _bringAppToForeground();
    }
  }

  Future<void> _enableScreenPinning() async {
    try {
      await _platformChannel.invokeMethod('enableScreenPinning');
    } catch (e) {
      debugPrint("Error enabling screen pinning: $e");
    }
  }

  void _bringAppToForeground() {
    try {
      _platformChannel.invokeMethod('bringToForeground');
    } catch (e) {
      debugPrint("Error bringing app to foreground: $e");
    }
  }

  Future<void> _exitApp() async {
    setState(() => _isExiting = true);
    try {
      await _platformChannel.invokeMethod('disableScreenPinning');
    } catch (e) {
      debugPrint("Error disabling screen pinning: $e");
    }
    SystemNavigator.pop();
  }

  Future<void> _clearCookies() async => await _cookieManager.clearCookies();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            _isConnected
                ? WebViewScreen(onExitApp: _exitApp)
                : _buildNoInternetMessage(),
            if (_showWarning) _buildWarningDialog(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoInternetMessage() {
    return Center(
      child: AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 50),
        title: const Text('Tidak Ada Koneksi Internet'),
        content: const Text(
            'Aplikasi memerlukan koneksi internet untuk berjalan. Silakan cek koneksi internet Anda dan coba lagi.'),
        actions: [
          ElevatedButton(
            onPressed: _exitApp,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Dialog(
          backgroundColor: Colors.red,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Peringatan!!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Anda terdeteksi mencoba keluar dari aplikasi. Silakan klik tombol "Tutup" untuk keluar dan buka kembali aplikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Laporkan kepada pengawas untuk reset akun Anda.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _showWarning = false);
                    _clearCookies();
                    _exitApp();
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Tutup Aplikasi',
                      style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
