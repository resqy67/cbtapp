import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key, required this.onExitApp}) : super(key: key);
  final VoidCallback onExitApp;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController controller;
  final cookieManager = WebViewCookieManager(); // cookie manager
  bool _isLoading = true;
  bool _hasError = false;
  var loadingPercentage = 0; // loading percentage
  String _errorMessage = '';
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => _handlePageStarted(),
        onPageFinished: (_) => _handlePageFinished(),
        onProgress: (progress) => _handlePageProgress(progress),
        onWebResourceError: (error) => _handleError(error.description),
      ))
      ..loadRequest(
          Uri.parse('https://guru.elearning.smkairlanggabpn.sch.id/exam.php'));

    _startConnectionCheck();
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    super.dispose();
  }

  void _handlePageStarted() {
    setState(() {
      loadingPercentage = 0;

      _isLoading = true;
      _hasError = false;
    });
    _restartConnectionCheck();
  }

  void _handlePageFinished() {
    setState(() {
      loadingPercentage = 100;

      _isLoading = false;
    });
    _restartConnectionCheck();
  }

  void _handlePageProgress(int progress) {
    setState(() {
      loadingPercentage = progress;
    });
  }

  void _handleError(String error) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = error;
    });
  }

  void _startConnectionCheck() {
    _connectionTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      if (_isLoading) {
        setState(() {
          _hasError = true;
        });
      }
    });
  }

  void _restartConnectionCheck() {
    _connectionTimer?.cancel();
    _startConnectionCheck();
  }

  Future<void> _exitApp() async {
    try {
      await MethodChannel('com.example.cbtapp/screenPinning')
          .invokeMethod('disableScreenPinning');
    } catch (e) {
      debugPrint("Failed to disable screen pinning: '${e.toString()}'");
    }
    _onClearCookies();
    SystemNavigator.pop();
    widget.onExitApp();
  }

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
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          if (!_hasError) WebViewWidget(controller: controller),
          if (_isLoading) Center(child: CircularProgressIndicator()),
          if (_hasError) _buildNoInternetMessage(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: LinearProgressIndicator(
          value: loadingPercentage / 100,
          backgroundColor: Colors.white,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
      title: const Text('CBT SKARLA'),
      centerTitle: true,
      actions: [
        IconButton(
            icon: Icon(Icons.refresh), onPressed: () => controller.reload()),
        IconButton(
            icon: Icon(Icons.exit_to_app), onPressed: () => _showExitDialog()),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Keluar Aplikasi'),
        content: Text(
            'Apakah Anda yakin ingin keluar aplikasi? Pastikan telah submit ujian.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Tidak')),
          TextButton(
              onPressed: () {
                _onClearCookies();
                Navigator.pop(context);
                widget.onExitApp();
              },
              child: Text('Ya')),
        ],
      ),
    );
  }

  Widget _buildNoInternetMessage() {
    return AlertDialog(
      title: Text('Terdapat Masalah Koneksi Internet di smartphone Anda'),
      content: Text(
          'Silakan cek koneksi internet Anda dan Klik OK untuk keluar atau refresh halaman. Jika masih terlihat kode error, silakan hubungi Panitia Ujian. $_errorMessage'),
      actions: [
        ElevatedButton(
          onPressed: _exitApp,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('OK', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
