/*
 * @Author: qiuz
 * @Github: <https://github.com/qiuziz>
 * @Date: 2019-06-04 16:37:29
 * @Last Modified by: qiuz
 * @Last Modified time: 2019-06-04 17:20:27
 */

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_h5/container/webview/webview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController _controller = new TextEditingController();
  var _inputHistory;
  @override
  void initState() {
    super.initState();
    getHistory();
  }

  void save(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _inputHistory != null
        ? _inputHistory.insert(0, url)
        : _inputHistory = [url];
    prefs.setStringList('inputHistory', _inputHistory);
  }

  void remove(num index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _inputHistory.removeAt(index);
    });
    prefs.setStringList('inputHistory', _inputHistory);
  }

  void getHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _inputHistory = prefs
          .getStringList('inputHistory')
          ?.toList()
          ?.reversed
          ?.toList()
          ?.toSet()
          ?.toList();
    });
  }

  void openWebViewPage(String url) {
    Navigator.push(
      context,
      new CupertinoPageRoute(
        builder: (context) => new WebViewPage(url: url, appBar: true)
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter H5'),
        centerTitle: true,
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Theme(
                data: new ThemeData(
                    primaryColor: Colors.black26, hintColor: Colors.black54),
                child: TextField(
                  onSubmitted: (String value) {
                    save(value);
                    openWebViewPage(value);
                  },
                  textInputAction: TextInputAction.go,
                  controller: _controller,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  )),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: new Text('输入历史', textAlign: TextAlign.left),
                ),
              ],
            ),
            new Expanded(
              child: new ListView.separated(
                itemCount: _inputHistory != null
                    ? _inputHistory.length == 0 ? 0 : _inputHistory.length
                    : 0,
                itemBuilder: (context, index) {
                  return new Dismissible(
                      key: new Key(_inputHistory[index]),
                      background: Text(''),
                      secondaryBackground: Container(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text('删除',
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .subhead
                                      .copyWith(color: Colors.red)),
                              Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),
                      onDismissed: (DismissDirection direction) {
                        remove(index);
                      },
                      child: new ListTile(
                        title: Text(
                          _inputHistory[index],
                        ),
                        onTap: () {
                           openWebViewPage(_inputHistory[index]);
                        },
                      ));
                },
                separatorBuilder: (context, index) => Divider(
                      height: .0,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
