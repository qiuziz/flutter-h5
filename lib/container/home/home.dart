import 'dart:async';
import 'dart:convert';
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
    _inputHistory != null ? _inputHistory.insert(0, url) : _inputHistory = [url];
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
      _inputHistory = prefs.getStringList('inputHistory')?.toList()?.reversed?.toList()?.toSet()?.toList();
    });
    print(_inputHistory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter H5'),
        centerTitle: true,
      ),
      // We're using a Builder here so we have a context that is below the Scaffold
      // to allow calling Scaffold.of(context) so we can show a snackbar.
      body: Container(
        // height: 100,
        //    decoration: new BoxDecoration(
        // border: new Border.all(color: Colors.black54, width: 1.0),
        // borderRadius: new BorderRadius.circular(12.0)),
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
                    Navigator.push(
                      context,
                        new MaterialPageRoute(
                            builder: (context) =>
                                new WebViewPage(url: value)
                        )
                    );
                  },
                  textInputAction: TextInputAction.go,
                  controller: _controller,
                  decoration: InputDecoration(
                      // contentPadding: EdgeInsets.all(10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
//            borderSide: BorderSide(color: Colors.red, width: 3.0, style: BorderStyle.solid)//没什么卵效果
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
                          Navigator.push(
                            context,
                              new MaterialPageRoute(
                                  builder: (context) =>
                                      new WebViewPage(url: _inputHistory[index])
                              )
                          );
                        },
                    )
                  );
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
