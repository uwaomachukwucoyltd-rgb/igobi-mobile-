import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';

/// Result returned from the Flutterwave hosted page.
///
/// - [CheckoutResult.completed] — webview hit our [CheckoutWebViewScreen.callbackUrl].
///   The caller must still call payment-service `/verify` before showing success,
///   because the redirect alone does not guarantee a SUCCESS status (Flutterwave
///   redirects on any terminal state including abandonment).
/// - [CheckoutResult.cancelled] — user closed the webview before completing.
enum CheckoutResultKind { completed, cancelled }

class CheckoutResult {
  const CheckoutResult(this.kind);
  final CheckoutResultKind kind;
}

class CheckoutWebViewScreen extends StatefulWidget {
  const CheckoutWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.callbackUrl,
  });

  final String authorizationUrl;

  /// Any navigation whose URL starts with this prefix counts as "checkout
  /// finished" — Flutterwave redirects to it on success, failure, or abandonment.
  final String callbackUrl;

  @override
  State<CheckoutWebViewScreen> createState() => _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends State<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (request) {
          if (request.url.startsWith(widget.callbackUrl)) {
            _completed = true;
            // Pop with completed result. The caller verifies before showing
            // success — Flutterwave redirects here on any terminal state.
            Navigator.of(context).pop(
              const CheckoutResult(CheckoutResultKind.completed),
            );
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  Future<bool> _confirmExit() async {
    if (_completed) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel checkout?'),
        content: const Text(
          'Your payment has not been confirmed. You can resume from your cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit() && mounted) {
          Navigator.of(context).pop(
            const CheckoutResult(CheckoutResultKind.cancelled),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'Secure checkout',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              if (await _confirmExit() && mounted) {
                Navigator.of(context).pop(
                  const CheckoutResult(CheckoutResultKind.cancelled),
                );
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.emerald,
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }
}
