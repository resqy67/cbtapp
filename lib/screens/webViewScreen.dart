import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key, required this.onExitApp}) : super(key: key);
  final VoidCallback onExitApp; // callback function to exit the app

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController controller; // webview controller
  var loadingPercentage = 0; // loading percentage
  final cookieManager = WebViewCookieManager(); // cookie manager
  bool _isLoading = true;
  bool _isExiting = false; // check if the user is trying to exit the app
  bool _hasError = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _startTimeoutTimer();
    controller = WebViewController()
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              loadingPercentage = 0;
              _isLoading = true;
              _hasError = false;
            });

            _timeoutTimer?.cancel();
            _startTimeoutTimer();
          },
          onPageFinished: (String url) {
            setState(() {
              loadingPercentage = 100;
              _isLoading = false;
            });
            _timeoutTimer?.cancel();
          },
          onProgress: (int progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // print('WebResourceError: ${error}');
            _handleError(error.description);
          },
        ),
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // enable javascript
      ..loadRequest(
        Uri.parse(
            'https://guru.elearning.smkairlanggabpn.sch.id/exam.php'), // load the webview with the given url
      );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer.periodic(Duration(seconds: 60), (timer) async {
      // Periksa apakah halaman masih dalam proses loading
      if (_isLoading) {
        setState(() {
          // _isLoading = false;
          _hasError = true;
        });
        _handleError('Timeout: The page took too long to load.');
      }
    });
  }

  // invoke the method channel to disable screen pinning
  Future<void> _disableScreenPinning() async {
    const platform = MethodChannel('com.example.cbtapp/screenPinning');
    try {
      await platform.invokeMethod('disableScreenPinning');
    } on PlatformException catch (e) {
      print("Failed to disable screen pinning: '${e.message}'.");
    }
  }

  // check if user is trying to exit the app and delete the cookies
  Future<void> _onClearCookies() async {
    final hadCookies = await cookieManager.clearCookies();
    String message = 'There were cookies. Now, they are gone!';
    if (!hadCookies) {
      message = 'There were no cookies to clear.';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

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
    return PopScope(
      // PopScope is a custom widget that prevents the app from exiting button back press
      canPop: false,
      onPopInvoked: (bool didpop) async {
        if (kDebugMode) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Ketahuan mencoba keluar apps'),
          ));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: LinearProgressIndicator(
              value: loadingPercentage / 100,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          centerTitle: true,
          title: const Text('CBT SKARLA'),
          actions: [
            IconButton(
              // padding: const EdgeInsets.only(right: 16),
              onPressed: () {
                controller.reload(); // reload the webview
              },
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              // padding: const EdgeInsets.only(right: 25),
              onPressed: () {
                // _onClearCookies(); // clear cookies if needed
                // widget.onExitApp();
                showDialog(
                  context: context,
                  builder: (context) => _dialogExitApp(context),
                );
              },
              icon: const Icon(Icons.exit_to_app),
            ),
          ],
        ),
        body: Stack(children: [
          if (_isLoading) Center(child: CircularProgressIndicator()),
          if (_hasError) _buildNoInternetMessage(),
          WebViewWidget(
            controller: controller,
          ),
          if (loadingPercentage < 100)
            Center(
              child: CircularProgressIndicator(
                  // value: loadingPercentage / 100,
                  ),
            ),
        ]),
      ),
    );
  }

  Widget _dialogExitApp(BuildContext Context) {
    return AlertDialog(
      title: const Text('Keluar Aplikasi'),
      content: const Text(
          'Apakah anda yakin ingin keluar aplikasi?. Jangan lupa untuk submit ujian terlebih dahulu.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Tidak'),
        ),
        TextButton(
          onPressed: () {
            _onClearCookies();
            Navigator.of(context).pop();
            widget.onExitApp();
          },
          child: const Text('Ya'),
        ),
      ],
    );
  }

  Widget _buildNoInternetMessage() {
    return Center(
      child: AlertDialog(
        title: const Text('Tidak Ada Koneksi Internet'),
        content: Text(
            'Aplikasi memerlukan koneksi internet untuk berjalan. Silahkan cek koneksi internet Anda dan coba lagi.'),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  _exitApp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleError(String error) {
    setState(() {
      // _isLoading = false;
      _hasError = true;
    });
    controller.loadHtmlString('''
      <!DOCTYPE html>
      <html lang="id">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Error - Koneksi Internet</title>
          <style>
              body {
                  font-family: Arial, sans-serif;
                  background-color: #f8f9fa;
                  text-align: center;
                  padding: 50px;
                  color: #333;
              }
              .container {
                  background: #fff;
                  padding: 30px;
                  border-radius: 10px;
                  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
                  max-width: 500px;
                  margin: auto;
              }
              h1 {
                  color: #d9534f;
                  font-size: 24px;
              }
              p {
                  font-size: 16px;
                  line-height: 1.5;
              }
              .error-message {
                  font-weight: bold;
                  font-size: 18px;
                  color: #d9534f;
                  background: #ffe6e6;
                  padding: 10px;
                  border-radius: 5px;
                  display: inline-block;
                  margin: 10px 0;
                  border: 1px solid #d9534f;
              }
              .error-icon {
                  font-size: 50px;
                  color: #d9534f;
                  margin-bottom: 10px;
              }
              .button {
                  display: inline-block;
                  padding: 10px 20px;
                  margin-top: 15px;
                  font-size: 16px;
                  color: #fff;
                  background-color: #0275d8;
                  border-radius: 5px;
                  text-decoration: none;
                  transition: 0.3s;
              }
              .button:hover {
                  background-color: #025aa5;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="error-icon">⚠️</div>
              <h1>Koneksi Internet Smartphone terganggu</h1>
              <p class="error-message">$error</p>
              <p>Ujian tidak dapat dilanjutkan.</p>
              <p>Tunjukkan kepada Panitia Ujian untuk mengetahui apa yang terjadi di smartphone kamu!</p>
          </div>
      </body>
      </html>
      ''');
    _buildNoInternetMessage();
  }
}
