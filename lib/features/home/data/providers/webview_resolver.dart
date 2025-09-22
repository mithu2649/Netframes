import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewResolver {
  final RegExp interceptUrl;
  final List<RegExp> additionalUrls;

  WebViewResolver({
    required this.interceptUrl,
    this.additionalUrls = const [],
  });

  Future<String> resolve(String url) async {
    final completer = Completer<String>();

    late final WebViewController webViewController;
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (interceptUrl.hasMatch(request.url)) {
              completer.complete(request.url);
              return NavigationDecision.prevent;
            }
            for (final additionalUrl in additionalUrls) {
              if (additionalUrl.hasMatch(request.url)) {
                completer.complete(request.url);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    return completer.future.timeout(const Duration(milliseconds: 15000));
  }
}
