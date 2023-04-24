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

    flutterWebView.WebViewController? _webviewcontroller;

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
                    width: min(popupWidth, MediaQuery.of(context).size.width),
                    height:
                        min(popupHeight, MediaQuery.of(context).size.height),
                    child: flutterWebView.WebView(
                      gestureNavigationEnabled: true,
                      onWebViewCreated: (controller) =>
                          _webviewcontroller = controller,
                      javascriptMode:
                          flutterWebView.JavascriptMode.unrestricted,
                      initialUrl: authorizationUrl,
                      zoomEnabled: false,
                      navigationDelegate: (navigation) async {
                        if (navigation.url.startsWith(redirectUrl)) {
                          Navigator.pop(dialogContext, navigation.url);
                          return flutterWebView.NavigationDecision.navigate;
                        }
                        if (navigationInterceptor != null) {
                          var interceptionResult = await navigationInterceptor
                              .call(context, navigation);

                          if (interceptionResult != null)
                            return interceptionResult;
                        }
                        return flutterWebView.NavigationDecision.navigate;
                      },
                      backgroundColor: backgroundColor,
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
                        onPressed: () => Navigator.pop(dialogContext, null),
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
