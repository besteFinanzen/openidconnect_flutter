part of openidconnect;

class OpenIdConnectAndroidiOS {
  static Future<String> authorizeInteractive({
    required BuildContext context,
    required String title,
    required String authorizationUrl,
    required String redirectUrl,
    required int popupWidth,
    required int popupHeight,
    Future<flutterWebView.NavigationDecision?> Function(
            BuildContext, flutterWebView.NavigationRequest)?
        navigationInterceptor,
  }) async {
    //Create the url

    flutterWebView.WebViewController? _webviewcontroller;

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          actionsPadding: EdgeInsets.zero,
          content: WillPopScope(
            // Catched back button pressed
            onWillPop: () async {
              if (_webviewcontroller == null) return true;
              if (await _webviewcontroller!.canGoBack()) {
                await _webviewcontroller!.goBack();
                return false;
              }
              return true;
            },
            child: Stack(
              children: [
                Container(
                  width: min(
                      popupWidth.toDouble(), MediaQuery.of(context).size.width),
                  height: min(popupHeight.toDouble(),
                      MediaQuery.of(context).size.height),
                  child: flutterWebView.WebView(
                    gestureNavigationEnabled: true,
                    onWebViewCreated: (controller) =>
                        _webviewcontroller = controller,
                    javascriptMode: flutterWebView.JavascriptMode.unrestricted,
                    initialUrl: authorizationUrl,
                    zoomEnabled: false,
                    navigationDelegate: (navigation) async {
                      if (navigationInterceptor != null) {
                        var interceptionResult = await navigationInterceptor
                            .call(context, navigation);

                        if (interceptionResult != null)
                          return interceptionResult;
                      }
                      return flutterWebView.NavigationDecision.navigate;
                    },
                    onPageFinished: (url) {
                      if (url.startsWith(redirectUrl)) {
                        Navigator.pop(dialogContext, url);
                      }
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    color: Colors.white,
                    child: IconButton(
                      onPressed: () => Navigator.pop(dialogContext, null),
                      icon: Icon(Icons.close),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );

    if (result == null) throw AuthenticationException(ERROR_USER_CLOSED);

    return result;
  }
}
