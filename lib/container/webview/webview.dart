import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_h5/container/home/home.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String kNavigationExamplePage = '''
<!DOCTYPE html><html>
<head><title>Navigation Delegate Example</title></head>
<script>
function callFlutter(){
 NavtiveRoute.postMessage(JSON.stringify({method: 'PUSH', url: 'https://photo.qiuz.me'}));
}
</script>
<body>
<p>
The navigation delegate is set to block navigation to the youtube website.
</p>
<ul>
<ul><a href="https://www.youtube.com/">https://www.youtube.com/</a></ul>
<ul><a href="https://www.google.com/">https://www.google.com/</a></ul>
<ul><button onclick="callFlutter()">callFlutter</button>
</ul>
</ul>
</body>
</html>
''';

class WebViewPage extends StatefulWidget {
  WebViewPage({Key key, this.url}) : super(key: key);

  final url;
  @override
  State<StatefulWidget> createState() => new _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewPage> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  String _title = '';
  bool _loading = true;
  num _stackToView = 1;

  void _handleLoad() {
    setState(() {
      _stackToView = 0;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        leading: NavigationControls(_controller.future, left: true),
        // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        actions: <Widget>[
          NavigationControls(
            _controller.future,
            left: false,
            right: true,
            replay: true,
          ),
          // SampleMenu(_controller.future),
        ],
      ),
      // We're using a Builder here so we have a context that is below the Scaffold
      // to allow calling Scaffold.of(context) so we can show a snackbar.
      body: Builder(builder: (BuildContext context) {
        return IndexedStack(index: _loading ? 1 : 0, children: [
          Column(children: <Widget>[
            Expanded(
                child: SafeArea(
              bottom: false,
              child: WebView(
                  initialUrl: widget.url,
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (WebViewController webViewController) {
                    _controller.complete(webViewController);
                  },
                  // ignore: prefer_collection_literals
                  javascriptChannels: <JavascriptChannel>[
                    _navtiveRouteJavascriptChannel(context),
                  ].toSet(),
                  navigationDelegate: (NavigationRequest request) {
                    // print(request);
                    // if (request.url == 'about:blank') {
                    //   return NavigationDecision.prevent;
                    // }
                    // if (_url != null && _url != request.url && request.url != 'about:blank') {
                    //   Navigator.push(
                    //       context,
                    //       new MaterialPageRoute(
                    //           builder: (context) =>
                    //               new WebViewPage(url: request.url)));
                    //   return NavigationDecision.prevent;
                    // }
                    setState(() {
                      _loading = true;
                    });
                    print('allowing navigation to $request');
                    return NavigationDecision.navigate;
                  },
                  onPageFinished: (String url) {
                    print('Page finished loading: $url');
                    _handleLoad();
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

  Widget favoriteButton() {
    return FutureBuilder<WebViewController>(
        future: _controller.future,
        builder: (BuildContext context,
            AsyncSnapshot<WebViewController> controller) {
          if (controller.hasData) {
            return FloatingActionButton(
              onPressed: () async {
                // showDialog(
                //     context: context,
                //     builder: (context) {
                //       TextEditingController _textFieldController =
                //           TextEditingController();
                //       return AlertDialog(
                //         title: Text('打开网页'),
                //         content: TextField(
                //           controller: _textFieldController,
                //           decoration: InputDecoration(hintText: "网页地址"),
                //         ),
                //         actions: <Widget>[
                //           new FlatButton(
                //             child: new Text('确定'),
                //             onPressed: () {
                //               Navigator.push(
                //                   context,
                //                   new MaterialPageRoute(
                //                       builder: (context) => new WebViewPage(
                //                           url: _textFieldController.text)));
                //              Navigator.of(context).pop();
                //             },
                //           ),
                //           new FlatButton(
                //             child: new Text('取消'),
                //             onPressed: () {
                //               Navigator.of(context).pop();
                //             },
                //           )
                //         ],
                //       );
                //     });
                Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) =>
                            new WebViewPage(url: 'https://qiuz.me')));
              },
              child: const Icon(Icons.add),
            );
          }
          return Container();
        });
  }
}

Widget _createDialog(
    String _confirmContent, Function sureFunction, Function cancelFunction) {
  return CupertinoAlertDialog(
    title: Text('提示'),
    content: TextField(
      decoration: InputDecoration(hintText: "TextField in Dialog"),
    ),
    actions: <Widget>[
      FlatButton(
        onPressed: sureFunction,
        child: Text('确定', style: TextStyle(color: Colors.blue)),
      ),
      FlatButton(
        onPressed: cancelFunction,
        child: Text('取消', style: TextStyle(color: Colors.blue)),
      ),
    ],
  );
}

enum MenuOptions {
  showUserAgent,
  listCookies,
  clearCookies,
  addToCache,
  listCache,
  clearCache,
  navigationDelegate,
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
              case MenuOptions.showUserAgent:
                _onShowUserAgent(controller.data, context);
                break;
              case MenuOptions.listCookies:
                _onListCookies(controller.data, context);
                break;
              case MenuOptions.clearCookies:
                _onClearCookies(context);
                break;
              case MenuOptions.addToCache:
                _onAddToCache(controller.data, context);
                break;
              case MenuOptions.listCache:
                _onListCache(controller.data, context);
                break;
              case MenuOptions.clearCache:
                _onClearCache(controller.data, context);
                break;
              case MenuOptions.navigationDelegate:
                _onNavigationDelegateExample(controller.data, context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
                PopupMenuItem<MenuOptions>(
                  value: MenuOptions.showUserAgent,
                  child: const Text('Show user agent'),
                  enabled: controller.hasData,
                ),
                const PopupMenuItem<MenuOptions>(
                  value: MenuOptions.listCookies,
                  child: Text('List cookies'),
                ),
                const PopupMenuItem<MenuOptions>(
                  value: MenuOptions.clearCookies,
                  child: Text('Clear cookies'),
                ),
                const PopupMenuItem<MenuOptions>(
                  value: MenuOptions.addToCache,
                  child: Text('Add to cache'),
                ),
                const PopupMenuItem<MenuOptions>(
                  value: MenuOptions.listCache,
                  child: Text('List cache'),
                ),
                const PopupMenuItem<MenuOptions>(
                  value: MenuOptions.clearCache,
                  child: Text('Clear cache'),
                ),
                const PopupMenuItem<MenuOptions>(
                  value: MenuOptions.navigationDelegate,
                  child: Text('Navigation Delegate example'),
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

  void _onNavigationDelegateExample(
      WebViewController controller, BuildContext context) async {
    final String contentBase64 =
        base64Encode(const Utf8Encoder().convert(kNavigationExamplePage));
    controller.loadUrl('data:text/html;base64,$contentBase64');
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
