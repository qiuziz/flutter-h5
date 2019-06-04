/*
 * @Author: qiuz
 * @Github: <https://github.com/qiuziz>
 * @Date: 2019-06-04 17:30:49
 * @Last Modified by: qiuz
 * @Last Modified time: 2019-06-04 17:34:21
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_h5/container/home/home.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewPage extends StatefulWidget {
  WebViewPage({Key key, this.url, this.appBar}) : super(key: key);

  final url;
  final bool appBar;

  @override
  State<StatefulWidget> createState() => new _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewPage> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  String _title = '';
  bool _loading = true;
  var _controllerFeture;
  @override
  void initState() {
    super.initState();
    print('aaaa${widget.appBar}');
  }

  @override
  Widget build(BuildContext context) {
    print(widget.appBar);
    return Scaffold(
      appBar: widget.appBar != null && widget.appBar ?
        AppBar(
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (context) =>
                          new Home()));
            },
            child: Text(_title),
          ),
          centerTitle: true,
          actions: <Widget>[
            SampleMenu(_controller.future),
          ],
        )
        : null,
      body:  WillPopScope(
        onWillPop: () async {
            if (await _controllerFeture.canGoBack()) {
              _controllerFeture.goBack();
              return false;
            }
           return true;
          // if (await _controller.goback()) {
          //   _lastPressedAt = DateTime.now();
          //   return false;
          // }
        },
        child: Builder(builder: (BuildContext context) {
          return IndexedStack(index: _loading ? 1 : 0, children: [
            Column(children: <Widget>[
              Expanded(
                  child: SafeArea(
                bottom: false,
                top: false,
                child: WebView(
                    initialUrl: widget.url,
                    javascriptMode: JavascriptMode.unrestricted,
                    onWebViewCreated: (WebViewController webViewController) {
                      _controller.complete(webViewController);
                      _controller.future.then((onValue) {
                         _controllerFeture = onValue;
                      });
                      setState(() {
                        _loading = true;
                      });
                    },
                    javascriptChannels: <JavascriptChannel>[
                      _navtiveRouteJavascriptChannel(context),
                    ].toSet(),
                    navigationDelegate: (NavigationRequest request) {
                    if (request.url.split('://')[0].indexOf('http') < 0) {
                      launch(request.url);
                      return NavigationDecision.prevent;
                    }
                      print('allowing navigation to $request');
                      return NavigationDecision.navigate;
                    },
                    onPageFinished: (String url) {
                      print('Page finished loading: $url');
                      _controller.future.then((controller) {
                        controller
                            .evaluateJavascript('window.document.title')
                            .then((result) {
                          setState(() {
                            _title = result;
                            _loading = false;
                          });
                        });
                      });
                    }),
              ))
            ]),
            Container(
              color: Colors.white,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  JavascriptChannel _navtiveRouteJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'NavtiveRoute',
        onMessageReceived: (JavascriptMessage result) {
          var res = json.decode(result.message);
          if (res['method'] == 'PUSH') {
            Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) =>
                        new WebViewPage(url: res['url'])));
          }
          if (res['method'] == 'POP') {
            Navigator.pop(context);
          }
        });
  }

}

enum MenuOptions {
  forword,
  back,
  refresh,
  // showUserAgent,
  // listCookies,
  // clearCookies,
  // addToCache,
  // listCache,
  // clearCache,
  // navigationDelegate,
}

class SampleMenu extends StatelessWidget {
  SampleMenu(this.controller);

  final Future<WebViewController> controller;
  final CookieManager cookieManager = CookieManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        return PopupMenuButton<MenuOptions>(
          onSelected: (MenuOptions value) {
            switch (value) {
              // case MenuOptions.showUserAgent:
              //   _onShowUserAgent(controller.data, context);
              //   break;
              // case MenuOptions.listCookies:
              //   _onListCookies(controller.data, context);
              //   break;
              // case MenuOptions.clearCookies:
              //   _onClearCookies(context);
              //   break;
              // case MenuOptions.addToCache:
              //   _onAddToCache(controller.data, context);
              //   break;
              // case MenuOptions.listCache:
              //   _onListCache(controller.data, context);
              //   break;
              // case MenuOptions.clearCache:
              //   _onClearCache(controller.data, context);
              //   break;
              // case MenuOptions.navigationDelegate:
              //   _onNavigationDelegateExample(controller.data, context);
              //   break;
              case MenuOptions.forword:
                controller.data.goForward();
                break;
              case MenuOptions.refresh:
                controller.data.reload();
                break;
              case MenuOptions.back:
                controller.data.goBack();
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
                PopupMenuItem<MenuOptions>(
                  value: MenuOptions.forword,
                  child: const Text('Forword'),
                  enabled: controller.hasData,
                ),
                const PopupMenuItem<MenuOptions>(
                  value: MenuOptions.refresh,
                  child: Text('Refresh'),
                ),
                const PopupMenuItem<MenuOptions>(
                  value: MenuOptions.back,
                  child: Text('Back'),
                ),
              ],
        );
      },
    );
  }

  void _onShowUserAgent(
      WebViewController controller, BuildContext context) async {
    // Send a message with the user agent string to the Toaster JavaScript channel we registered
    // with the WebView.
    controller.evaluateJavascript(
        'Toaster.postMessage("User Agent: " + navigator.userAgent);');
  }

  void _onListCookies(
      WebViewController controller, BuildContext context) async {
    final String cookies =
        await controller.evaluateJavascript('document.cookie');
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Cookies:'),
          _getCookieList(cookies),
        ],
      ),
    ));
  }

  void _onAddToCache(WebViewController controller, BuildContext context) async {
    await controller.evaluateJavascript(
        'caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";');
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Added a test entry to cache.'),
    ));
  }

  void _onListCache(WebViewController controller, BuildContext context) async {
    await controller.evaluateJavascript('caches.keys()'
        '.then((cacheKeys) => JSON.stringify({"cacheKeys" : cacheKeys, "localStorage" : localStorage}))'
        '.then((caches) => Toaster.postMessage(caches))');
  }

  void _onClearCache(WebViewController controller, BuildContext context) async {
    await controller.clearCache();
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text("Cache cleared."),
    ));
  }

  void _onClearCookies(BuildContext context) async {
    final bool hadCookies = await cookieManager.clearCookies();
    String message = 'There were cookies. Now, they are gone!';
    if (!hadCookies) {
      message = 'There are no cookies.';
    }
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Widget _getCookieList(String cookies) {
    if (cookies == null || cookies == '""') {
      return Container();
    }
    final List<String> cookieList = cookies.split(';');
    final Iterable<Text> cookieWidgets =
        cookieList.map((String cookie) => Text(cookie));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: cookieWidgets.toList(),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture,
      {this.left: false, this.right: false, this.replay: false})
      : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;
  final bool left;
  final bool right;
  final bool replay;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController controller = snapshot.data;
        return Row(
          children: <Widget>[
            left
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: !webViewReady
                        ? null
                        : () async {
                            if (await controller.canGoBack()) {
                              controller.goBack();
                            }
                          },
                  )
                : null,
            replay
                ? IconButton(
                    icon: const Icon(Icons.replay),
                    onPressed: !webViewReady
                        ? null
                        : () {
                            controller.reload();
                          },
                  )
                : null,
            right
                ? IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: !webViewReady
                        ? null
                        : () async {
                            if (await controller.canGoForward()) {
                              controller.goForward();
                            }
                          },
                  )
                : null,
          ].where((child) => child != null).toList(),
        );
      },
    );
  }
}
