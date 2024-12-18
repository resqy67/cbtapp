import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              loadingPercentage = 0;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              loadingPercentage = 100;
            });
          },
          onProgress: (int progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          // onHttpError: (error) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('HTTP error: $error'),
          //     ),
          //   );
          // },
        ),
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // enable javascript
      ..loadRequest(
        Uri.parse(
            'https://guru.elearning.smkairlanggabpn.sch.id/exam.php'), // load the webview with the given url
      );
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
          WebViewWidget(
            controller: controller,
          ),
          if (loadingPercentage < 100)
            Center(
              child: CircularProgressIndicator(
                value: loadingPercentage / 100,
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
            Navigator.of(context).pop();
            widget.onExitApp();
          },
          child: const Text('Ya'),
        ),
      ],
    );
  }
}
