import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../utils/app_colors.dart';

class VNPayWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const VNPayWebViewScreen({super.key, required this.paymentUrl});

  @override
  State<VNPayWebViewScreen> createState() => _VNPayWebViewScreenState();
}

class _VNPayWebViewScreenState extends State<VNPayWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Can be used to update a progress bar if needed
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[VNPayWebView] Web resource error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('[VNPayWebView] Navigating to: ${request.url}');
            // Chặn đường dẫn return URL từ VNPay
            if (request.url.contains('luxebag-backend.onrender.com/api/payments/vnpay/return')) {
              debugPrint('[VNPayWebView] Return URL detected: ${request.url}');
              final uri = Uri.parse(request.url);
              final responseCode = uri.queryParameters['vnp_ResponseCode'];
              final txnRef = uri.queryParameters['vnp_TxnRef'] ?? '';
              
              // Đóng WebView và trả về kết quả
              Navigator.of(context).pop({
                'vnp_ResponseCode': responseCode,
                'vnp_TxnRef': txnRef,
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Thanh Toán VNPay',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(), // Đóng WebView khi click Back
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: _isLoading
              ? const LinearProgressIndicator(
                  minHeight: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  backgroundColor: Colors.transparent,
                )
              : const Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
