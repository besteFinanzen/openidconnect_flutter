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
    //Create the url

    flutterWebView.WebViewController _webviewcontroller =
        flutterWebView.WebViewController();

    late final flutterWebView.PlatformWebViewControllerCreationParams params;
    if (flutterWebView.WebViewPlatform.instance
        is flutterWebViewIOS.WebKitWebViewPlatform) {
      params = flutterWebViewIOS.WebKitWebViewControllerCreationParams();
    } else {
      params = const flutterWebView.PlatformWebViewControllerCreationParams();
    }

    final flutterWebView.WebViewController controller =
        flutterWebView.WebViewController.fromPlatformCreationParams(params)
          ..setJavaScriptMode(flutterWebView.JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(authorizationUrl))
          ..setNavigationDelegate(flutterWebView.NavigationDelegate(
            onNavigationRequest: (navigation) async {
              if (navigation.url.startsWith(redirectUrl)) {
                if (context.mounted) {
                  Navigator.pop(context, navigation.url);
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
          ))
          ..enableZoom(false);

    if (controller.platform is flutterWebViewIOS.WebKitWebViewController) {
      (controller.platform as flutterWebViewIOS.WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    } else if (controller.platform
        is flutterWebViewAndroid.AndroidWebViewController) {}

    String? result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Visibility(
          visible: !inBackground,
          child: AlertDialog(
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
                    child: flutterWebView.WebViewWidget(
                      controller: controller,
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
