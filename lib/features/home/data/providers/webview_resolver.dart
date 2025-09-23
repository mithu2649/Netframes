import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewResolver {
  final RegExp interceptUrl;
  final List<RegExp> additionalUrls;
  final String? script;
  final int? timeout;

  WebViewResolver({
    required this.interceptUrl,
    this.additionalUrls = const [],
    this.script,
    this.timeout,
  });

  Future<String> resolve(String url) async {
    final completer = Completer<String>();

    late final WebViewController webViewController;
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (script != null) {
              webViewController.runJavaScript(script!);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (interceptUrl.hasMatch(request.url)) {
              if (!completer.isCompleted) {
                completer.complete(request.url);
              }
              return NavigationDecision.prevent;
            }
            for (final additionalUrl in additionalUrls) {
              if (additionalUrl.hasMatch(request.url)) {
                if (!completer.isCompleted) {
                  completer.complete(request.url);
                }
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    if (timeout != null) {
      return completer.future.timeout(Duration(milliseconds: timeout!));
    } else {
      return completer.future;
    }
  }
}