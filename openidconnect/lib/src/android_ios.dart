part of openidconnect;

class OpenIdConnectAndroidiOS {
  static Future<String> authorizeInteractive({
    required BuildContext context,
    required String title,
    required String authorizationUrl,
    required String redirectUrl,
    required double popupWidth,
    required double popupHeight,
    Color? backgroundColor,
    bool inBackground = false,
    Future<flutterWebView.NavigationDecision?> Function(
            BuildContext, flutterWebView.NavigationRequest)?
        navigationInterceptor,
  }) async {
    late final flutterWebView.PlatformWebViewControllerCreationParams params;
    if (flutterWebView.WebViewPlatform.instance
        is flutterWebViewIOS.WebKitWebViewPlatform) {
      params = flutterWebViewIOS.WebKitWebViewControllerCreationParams();
    } else {
      params = const flutterWebView.PlatformWebViewControllerCreationParams();
    }

    final flutterWebView.WebViewController _webviewcontroller =
        flutterWebView.WebViewController.fromPlatformCreationParams(params)
          ..setJavaScriptMode(flutterWebView.JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(authorizationUrl))
          ..enableZoom(false)
          ..setBackgroundColor(Colors.transparent);

    if (_webviewcontroller.platform
        is flutterWebViewIOS.WebKitWebViewController) {
      (_webviewcontroller.platform as flutterWebViewIOS.WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    } else if (_webviewcontroller.platform
        is flutterWebViewAndroid.AndroidWebViewController) {}

    String? result = await showDialog<String>(
      barrierColor: Colors.transparent,
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _webviewcontroller
            .setNavigationDelegate(flutterWebView.NavigationDelegate(
          onNavigationRequest: (navigation) async {
            if (navigation.url.startsWith(redirectUrl)) {
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, navigation.url);
              }
              return flutterWebView.NavigationDecision.navigate;
            }
            if (navigationInterceptor != null) {
              var interceptionResult =
                  await navigationInterceptor.call(context, navigation);

              if (interceptionResult != null) return interceptionResult;
            }
            return flutterWebView.NavigationDecision.navigate;
          },
        ));
        return Visibility(
          visible: !inBackground,
          child: AlertDialog(
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            titlePadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            actionsPadding: EdgeInsets.zero,
            content: WillPopScope(
              // Catched back button pressed
              onWillPop: () async {
                if (await _webviewcontroller.canGoBack()) {
                  await _webviewcontroller.goBack();
                  return false;
                }
                return true;
              },
              child: Stack(
                children: [
                  Container(
                    width: min(popupWidth, MediaQuery.of(context).size.width),
                    height:
                        min(popupHeight, MediaQuery.of(context).size.height),
                    child: GestureDetector(
                      onHorizontalDragUpdate: (_) {},
                      child: flutterWebView.WebViewWidget(
                        controller: _webviewcontroller,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(20))),
                      child: IconButton(
                        key: const Key(
                            'openidconnect__close_auth_window_button'),
                        onPressed: () {
                          if (dialogContext.mounted)
                            Navigator.pop(dialogContext, null);
                        },
                        icon: Icon(Icons.close),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null) throw AuthenticationException(ERROR_USER_CLOSED);

    return result;
  }
}
